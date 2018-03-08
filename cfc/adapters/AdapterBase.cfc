component {
    public any function init() {
        this.database = "";
        this.ORACLE = "oracle";
        this.MICROSOFT = "sqlserver";
        this.DB2 = "db2";
        this.JDBC = "jdbc";
        this.dataBaseTypes = [this.JDBC, this.DB2, this.MICROSOFT, this.ORACLE];
        return this;
    }

    public string function getDatabaseType() {
        var dbInfo = new dbinfo(dataSource = this.dataSourceName);
        var driverName = dbInfo.version().driver_name;
        for (type in this.dataBaseTypes) {
            if (driverName.findNoCase(type)) {
                return type;
            }
        }
    }

    public string function getSqlType(required string fieldName) {
        var sqlTypeResults = {
            "#this.MICROSOFT#" = {
                "bigint" = "CF_SQL_BIGINT",
                "binaryt" = "CF_SQL_BINARY",
                "bit" = "CF_SQL_BIT",
                "char" = "CF_SQL_CHAR",
                "date" = "CF_SQL_DATE",
                "decimal" = "CF_SQL_DECIMAL",
                "double" = "CF_SQL_DOUBLE",
                "integer" = "CF_SQL_INTEGER",
                "int" = "CF_SQL_INTEGER",
                "longvarbinary" = "CF_SQL_LONGVARBINARY",
                "longvarchar" = "CF_SQL_LONGVARCHAR",
                "nchar" = "CF_SQL_NCHAR",
                "numeric" = "CF_SQL_NUMERIC",
                "nvarchar" = "CF_SQL_NVARCHAR",
                "real" = "CF_SQL_REAL",
                "smallint" = "CF_SQL_SMALLINT",
                "xml" = "CF_SQL_SQLXML",
                "time" = "CF_SQL_TIME",
                "datetime" = "CF_SQL_TIMESTAMP",
                "tinyint" = "CF_SQL_TINYINT",
                "varbinary" = "CF_SQL_VARBINARY",
                "varchar" = "CF_SQL_VARCHAR"
            }, 
            "#this.ORACLE#" = {
                "blob" = "CF_SQL_BLOB",
                "bfile" = "CF_SQL_BLOB",
                "char" = "CF_SQL_CHAR",
                "nchar" = "CF_SQL_CHAR",
                "clob" = "CF_SQL_CLOB",
                "nclob" = "CF_SQL_CLOB",
                "number" = "CF_SQL_DECIMAL",
                "number" = "CF_SQL_FLOAT",
                "long" = "CF_SQL_LONGVARCHAR",
                "NCHAR" = "CF_SQL_NCHAR",
                "NCLOB" = "CF_SQL_NCLOB",
                "NVARCHAR2" = "CF_SQL_NVARCHAR",
                "date" = "CF_SQL_TIMESTAMP",
                "raw" = "CF_SQL_VARBINARY",
                "varchar2" = "CF_SQL_VARCHAR",
                "nvarchar2" = "CF_SQL_VARCHAR"
            },
            "#this.DB2#" = {
                "Bigint" = "CF_SQL_BIGINT",
                "Blob" = "CF_SQL_BLOB",
                "Char" = "CF_SQL_CHAR",
                "Clob" = "CF_SQL_CLOB",
                "Date" = "CF_SQL_DATE",
                "Decimal" = "CF_SQL_DECIMAL",
                "Double" = "CF_SQL_DOUBLE",
                "Float" = "CF_SQL_FLOAT",
                "Integer" = "CF_SQL_INTEGER",
                "LONGVARGRAPHIC" = "CF_SQL_LONGNVARCHAR",
                //"Long Varchar" = "CF_SQL_LONGVARCHAR",
                "NCHAR" = "CF_SQL_NCHAR",
                "NCLOB" = "CF_SQL_NCLOB",
                "Numeric" = "CF_SQL_NUMERIC",
                "NVARCHAR" = "CF_SQL_NVARCHAR",
                "Real" = "CF_SQL_REAL",
                "Smallint" = "CF_SQL_SMALLINT",
                "Time" = "CF_SQL_TIME",
                "Timestamp" = "CF_SQL_TIMESTAMP",
                "Rowid" = "CF_SQL_VARBINARY",
                "Varchar" = "CF_SQL_VARCHAR"
            },
            "#this.JDBC#" = {
                "ARRAY" = "CF_SQL_ARRAY",
                "BIGINT" = "CF_SQL_BIGINT",
                "BINARY" = "CF_SQL_BINARY",
                "BIT" = "CF_SQL_BIT",
                "BLOB" = "CF_SQL_BLOB",
                "CHAR" = "CF_SQL_CHAR",
                "CLOB" = "CF_SQL_CLOB",
                "DATE" = "CF_SQL_DATE",
                "DECIMAL" = "CF_SQL_DECIMAL",
                "DISTINCT" = "CF_SQL_DISTINCT",
                "DOUBLE" = "CF_SQL_DOUBLE",
                "FLOAT" = "CF_SQL_FLOAT",
                "INTEGER" = "CF_SQL_INTEGER",
                "LONGVARBINARY" = "CF_SQL_LONGVARBINARY",
                "LONGNVARCHAR" = "CF_SQL_LONGNVARCHAR",
                "LONGVARCHAR" = "CF_SQL_LONGVARCHAR",
                "NCHAR" = "CF_SQL_NCHAR",
                "NULL" = "CF_SQL_NULL",
                "NUMERIC" = "CF_SQL_NUMERIC",
                "NVARCHAR" = "CF_SQL_NVARCHAR",
                "OTHER" = "CF_SQL_OTHER",
                "REAL" = "CF_SQL_REAL",
                "REF" = "CF_SQL_REFCURSOR",
                "SMALLINT" = "CF_SQL_SMALLINT",
                "STRUCT" = "CF_SQL_STRUCT",
                "TIME" = "CF_SQL_TIME",
                "TIMESTAMP" = "CF_SQL_TIMESTAMP",
                "TINYINT" = "CF_SQL_TINYINT",
                "VARBINARY" = "CF_SQL_VARBINARY",
                "VARCHAR" = "CF_SQL_VARCHAR"
            }
        };
        var revisedFieldName = cleanFieldName(arguments.fieldName);
        for (var item in sqlTypeResults[getDatabaseType()]) {
            if (revisedFieldName == item) {
                return sqlTypeResults[getDatabaseType()][item];
            }
        }
        throw(type="Fixtures.ADAPTERS.InvalidSqlType", message="Invalid SQLType Mapping: #revisedFieldName#");
    }

    private string function cleanFieldName(required string fieldName) {
        // cleanse brackets
        var cleansedFieldName = "";
        var fieldLength = len(arguments.fieldName);
        var position = find('(', arguments.fieldName, 0) - 1;
        var position = (position < fieldLength && position > 1) ? position : fieldLength;
        cleansedFieldName = left(arguments.fieldName, position);

        // cleanse identity
        cleansedFieldName = replaceNoCase(cleansedFieldName, " identity", "");

        return cleansedFieldName;
    }
}