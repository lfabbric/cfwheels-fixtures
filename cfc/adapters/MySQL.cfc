component implements="AdapterIF" extends="AdapterBase" {
    public any function init(required string dataSource) {
        super.init();
        this.database = "MySQL";
        this.dataSourceName = arguments.dataSource;
        return this;
    }

    public query function getConstraints(required string table) {
        var query = new query();
        query.setDatasource(this.dataSourceName);
        query.addParam(name="table", value=arguments.table, cfsqltype="cf_sql_varchar");
        var sql = "
            select 
                information_schema.table_constraints.constraint_name,
                IF(information_schema.table_constraints.constraint_type = 'PRIMARY KEY', true, false) AS is_primary_key,
                IF(information_schema.table_constraints.constraint_type = 'UNIQUE', true, false) AS is_unique_constraint,
                information_schema.table_constraints.constraint_catalog AS type_desc,
                information_schema.key_column_usage.column_name AS name
            FROM information_schema.table_constraints
            LEFT JOIN information_schema.key_column_usage ON 
                information_schema.table_constraints.table_name = information_schema.key_column_usage.table_name
                AND information_schema.table_constraints.constraint_name = information_schema.key_column_usage.constraint_name 
                AND information_schema.table_constraints.table_schema = information_schema.key_column_usage.table_schema
            WHERE 
                information_schema.table_constraints.table_name = :table
                AND information_schema.table_constraints.constraint_type IN ('UNIQUE', 'PRIMARY KEY')
                AND information_schema.table_constraints.table_schema = database()
        ";
        query.setSql(sql = sql);
        return query.execute().getResult();
    }

    public boolean function tableExists(required string table) {
        var query = new query();
        query.setDatasource(this.dataSourceName);
        query.addParam(name="table", value=arguments.table, cfsqltype="cf_sql_varchar");
        query.setSql("
            SELECT 1
            FROM information_schema.tables
            WHERE
                table_type = 'BASE TABLE' 
                AND table_name = :table
                AND table_schema = database()
        ");
        results = query.execute().getResult();
        return results.recordCount;
    }

    public array function createTable(required array tableDefinition, required array tableConstraints, required string table) {
        var errors = [];
        var query = new query();
        var formattedConstraints = $formatConstraints(arguments.tableConstraints);
        var sql = "";
        query.setDatasource(this.dataSourceName);
        sql = "CREATE TABLE #arguments.table# (";
        sql &= $createFieldsForTableHelper(arguments.tableDefinition, arguments.table);
        sql &= $createConstraintsForTableHelper(formattedConstraints);
        sql &= $createForeignConstraintsForTableHelper(arguments.tableDefinition, arguments.table);
        sql &= ");";
        try {
            query.setSql(sql);
            results = query.execute();
        } catch (any e) {
            errors.append("Failed with table #arguments.table# -- #sql#");
        }
        return errors;
    }

    public array function findAll(required string table, numeric maxRows) {
        var query = new query();
        query.setDatasource(this.dataSourceName);
        var sql = "
            SELECT *
            FROM #arguments.table#
        ";
        if (arguments.maxRows >= 1) {
            sql &= "
                LIMIT #arguments.maxRows#
            ";
        }
        query.setSQL(sql);
        results = query.execute().getResult();
        return queryToArrayOfStructs(results);
    }

    public array function dropTable(required string table) {
        var initialForeignKeyCheckStatus = getForeignKeyCheckStatus();
        setForeignKeyCheckStatus(0);
        var errors = [];
        var query = new query();
        query.setDatasource(this.dataSourceName);
        try {
            query.setSql("DROP TABLE #arguments.table#");
            var results = query.execute().getResult();
        } catch (any e) {
            errors.append("Could not drop table #arguments.table#");
        }
        setForeignKeyCheckStatus(initialForeignKeyCheckStatus);
        return errors;
    }

    public array function populate(required array results, required tableDefinitions, required string table) {
        var errors = [];
        for (result in arguments.results) {
            var query = new query();
            query.setDatasource(this.dataSourceName);
            var columns = [];
            var columnValues = [];
            for (var column in result.fields) {
                columns.append(column);
                columnValues.append(":#column#");
                for (var tableDefinition in arguments.tableDefinitions) {
                    if (tableDefinition.column_name.findNoCase(column)) {
                        var cfSQLType = "CF_SQL_VARCHAR";
                        try {
                            cfSQLType = getSqlType(tableDefinition.type_name);
                        } catch (any e) {
                            errors.append(e.message);
                        }
                        argumentCollection = {
                            "name" = lcase(column),
                            "value" = "#result.fields[column]#",
                            "cfsqltype" = cfSQLType
                        };
                        if (!len(result.fields[column])) {
                            argumentCollection.null = true;
                        }
                        query.addParam(argumentCollection=argumentCollection);
                        break;
                    }
                }
            }
            var sql = "
                INSERT INTO #arguments.table# (#lcase(columns.toList())#)
                VALUES (#lcase(columnValues.toList())#)
            ";
            try {
                query.setSql(sql);
                query.execute();
            } catch(any e) {
                errors.append("An error was experienced inserting the following commands #sql# on table #arguments.table#");
            }
        }
        return errors;
    }

    private numeric function getForeignKeyCheckStatus() {
        var query = new query();
        query.setDatasource(this.dataSourceName);
        query.setSql("SELECT @@FOREIGN_KEY_CHECKS AS status");
        return query.execute().getResult().status;
    }

    private void function setForeignKeyCheckStatus(numeric status = 1) {
        var query = new query();
        query.setDatasource(this.dataSourceName);
        query.addParam(name="status", value=arguments.status, cfsqltype="CF_SQL_INTEGER");
        query.setSql("SET foreign_key_checks = :status");
        query.execute();
    }

    private struct function $formatConstraints(required array constraints) {
        var constraintList = {};
        for (constraint in arguments.constraints) {
            if (constraintList.keyExists(constraint.constraint_name) && constraintList[constraint.constraint_name].len()) {
                constraintList[constraint.constraint_name].append(constraint);
            } else {
                constraintList[constraint.constraint_name] = [constraint];
            }
        }
        return constraintList;
    }

    private string function $createFieldsForTableHelper(required array tableDefinition, required string table) {
        var fieldTypes = ["binary","char","datetime2","nchar","numeric","nvarchar","time","varbinary","varchar"];
        var complexFieldTypes = ["decimal"];
        var sql = createObject("java", "java.lang.StringBuilder");
        for (i = 1; i <= arrayLen(arguments.tableDefinition); i++) {
            var isIdentity = false;
            if (arguments.tableDefinition[i].type_name.contains("identity")) {
                isIdentity = true;
            }
            sql.append(" `#arguments.tableDefinition[i].column_name#` ");
            if (isIdentity) {
                sql.append("#replaceNoCase(arguments.tableDefinition[i].type_name, " identity", "")#");
            } else {
                sql.append("#arguments.tableDefinition[i].type_name#");
            }
            if (fieldTypes.findNoCase(arguments.tableDefinition[i].type_name)) {
                sql.append("(#arguments.tableDefinition[i].column_size#)");
            } else if (complexFieldTypes.findNoCase(arguments.tableDefinition[i].type_name)) {
                sql.append("(#arguments.tableDefinition[i].column_size#,#arguments.tableDefinition[i].decimal_digits#)");
            }
            if (!arguments.tableDefinition[i].is_nullable) {
                sql.append(" NOT ");
            }
            sql.append(" NULL");
            if (len(arguments.tableDefinition[i].column_default_value)) {
                sql.append(" DEFAULT #arguments.tableDefinition[i].column_default_value#");
            }
            if (i < arrayLen(arguments.tableDefinition)) {
                sql.append(",");
            }
        }
        return sql.toString();
    }

    private string function $createConstraintsForTableHelper(required struct constraints) {
        var sql = createObject("java", "java.lang.StringBuilder");
        for (constraint in constraints) {
            sql.append(", ");
            if (constraints[constraint].len()) {
                if (constraints[constraint][1].is_primary_key) {
                    sql.append(" PRIMARY KEY (#constraints[constraint][1].name#)");
                } else if (constraints[constraint][1].is_unique_constraint) {
                    sql.append(" UNIQUE (#constraints[constraint][1].name#)");
                }
            }
        }
        return sql.toString();
    }

    private string function $createForeignConstraintsForTableHelper(required array tableDefinition, required string table) {
        var sql = createObject("java", "java.lang.StringBuilder");
        for (i = 1; i <= arrayLen(arguments.tableDefinition); i++) {
            if (arguments.tableDefinition[i]["referenced_primarykey_table"] != "N/A") {
                sql.append(",
                    CONSTRAINT `FK_#arguments.table#_#arguments.tableDefinition[i]["referenced_primarykey_table"]#`
                    FOREIGN KEY (`#arguments.tableDefinition[i]["column_name"]#`)
                    REFERENCES `#arguments.tableDefinition[i]["referenced_primarykey_table"]#` ( `#arguments.tableDefinition[i]["referenced_primarykey"]#` )
                ");
            }
        }
        return sql.toString();
    }
}