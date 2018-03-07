component implements="AdapterIF" extends="SQLDAO" {
    public any function init(required string dataSource) {
        super.init();
        this.database = "SQLServer";
        this.dataSourceName = arguments.dataSource;
        return this;
    }

    public query function getConstraints(required string table) {
        var query = new query();
        query.setDatasource(this.dataSourceName);
        query.addParam(name="table", value=arguments.table, cfsqltype="cf_sql_varchar");
        query.setSql("
            SELECT
                sys.indexes.name AS constraint_name,
                sys.indexes.is_primary_key,
                sys.indexes.is_unique_constraint,
                sys.indexes.type_desc,
                sys.all_columns.name
            FROM 
                sys.indexes
            LEFT OUTER JOIN sys.index_columns ON 
                sys.indexes.index_id = sys.index_columns.index_id
                AND sys.indexes.object_id = sys.index_columns.object_id
            LEFT OUTER JOIN sys.all_columns ON 
                sys.index_columns.column_id = sys.all_columns.column_id
                AND sys.indexes.object_id = sys.all_columns.object_id
            WHERE 
                sys.indexes.object_id = OBJECT_ID(:table, 'U');
        ");
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

    public array function dropTable(required string table) {
        var errors = [];
        var query = new query();
        query.setDatasource(this.dataSourceName);
        
        try {
            var sql = "
                SELECT 
                    'ALTER TABLE [' +  OBJECT_SCHEMA_NAME(parent_object_id) +
                    '].[' + OBJECT_NAME(parent_object_id) + 
                    '] DROP CONSTRAINT [' + name + ']' AS dropconstraint
                FROM sys.foreign_keys
                WHERE
                    referenced_object_id = object_id('#arguments.table#')
            ";
            query.setSql(sql);
            var results = query.execute().getResult();
        } catch (any e) {
            errors.append("Failed to find constrains for table #arguments.table#");
        }

        for (result in results) {
            try {
                query = new query();
                query.setDatasource(this.dataSourceName);
                query.setSQL(result.dropconstraint);
                restults = query.execute().getPrefix();
            } catch (any e) {
                errors.append("Could not delete the constrains for the table #arguments.table#");
            }
        }

        try {
            query = new query();
            query.setDatasource(this.dataSourceName);
            query.setSQL("
                DROP TABLE #arguments.table#
            ");
            results = query.execute().getPrefix();
        } catch (any e) {
            errors.append("Could not drop the table #arguments.table#");
        }
        return errors;
    }

    public array function populate(required array results, required tableDefinitions, required string table) {
        var errors = [];
        setIdentity(true, arguments.table);
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
                        argumentCollection = {
                            "name" = lcase(column),
                            "value" = "#result.fields[column]#",
                            "cfsqltype" = getSqlType(tableDefinition.type_name)
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
        setIdentity(false, arguments.table);
        return errors;
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
            sql.append(" [#arguments.tableDefinition[i].column_name#] ");
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
                sql.append(" CONSTRAINT [DF_#arguments.table#_#arguments.tableDefinition[i].column_name#] DEFAULT (#arguments.tableDefinition[i].column_default_value#)");
            }
            if (isIdentity) {
                sql.append(" IDENTITY (1, 1)"); // bug in the dbinfo get columns - the identify is missing the values
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
            sql.append(", CONSTRAINT #constraint# ");
            if (constraints[constraint].len()) {
                if (constraints[constraint][1].is_primary_key) {
                    sql.append(" PRIMARY KEY #constraints[constraint][1].type_desc# (");
                } else if (constraints[constraint][1].is_unique_constraint) {
                    sql.append(" UNIQUE #constraints[constraint][1].type_desc# (");
                }
                for (i = 1; i <= arrayLen(constraints[constraint]); i++) {
                    sql.append("#constraints[constraint][i].name#");
                    if (i < constraints[constraint].len()) {
                        sql.append(",");
                    }
                }
                sql.append(")");
            }
        }
        return sql.toString();
    }

    private string function $createForeignConstraintsForTableHelper(required array tableDefinition, required string table) {
        var sql = createObject("java", "java.lang.StringBuilder");
        for (i = 1; i <= arrayLen(arguments.tableDefinition); i++) {
            if (arguments.tableDefinition[i]["referenced_primarykey_table"] != "N/A") {
                sql.append(",
                    CONSTRAINT [FK_#arguments.table#_#arguments.tableDefinition[i]["referenced_primarykey_table"]#] 
                    FOREIGN KEY ([#arguments.tableDefinition[i]["column_name"]#])
                    REFERENCES [#arguments.tableDefinition[i]["referenced_primarykey_table"]#] ( [#arguments.tableDefinition[i]["referenced_primarykey"]#] )
                ");
            }
        }
        return sql.toString();
    }

    private void function setIdentity(required boolean state, required string table) {
        var query = new query();
        query.setDataSource(this.dataSourceName);
        var allowIdentityInsert = (arguments.state) ? "ON" : "OFF";
        try{
            query.setSQL("
                SET IDENTITY_INSERT #arguments.table# #allowIdentityInsert#;
            ");
            query.execute();
        } catch (any e) {
            // TODO: really, I should check if the id has an identity first...
        }
    }
}