component extends="Base" output="false" accessors="true" {
    property numeric indent;
    property boolean overWriteFileEnabled;

    public any function init(required array tables, required string dataSource, numeric maxRows = 1, boolean overWriteFileEnabled = false) {
        super.init();
        this.tables = arguments.tables;
        this.dataSourceName = arguments.dataSource;
        this.overWriteFileEnabled = arguments.overWriteFileEnabled;
        this.maxRows = arguments.maxRows;
        this.indent = 4;
        return this;
    }

    public string function execute(required string filePath) {
        var daoAdapter = getDatabaseFactory();
        var errors = {};
        var output = [];
        for (table in this.tables) {
            cfdbinfo( name="columns", type="columns", table=table, datasource=this.dataSourceName );
            try {
                var response = {};
                response.table = table;
                response.columns = columns;
                response.constraints = daoAdapter.getConstraints(table);
                response.records = [];
                var results = daoAdapter.findAll(table, this.maxRows);
                var primaryKeys = $getPrimaryKeys(response.columns);
                response.primaryKeys = primaryKeys;
                for (result in results) {
                    response.records.append({
                        "pk" = $primaryKeyValues(result, primaryKeys),
                        "fields" = result
                    });
                }
                output.append(response);
            } catch (any e) {
                errors["#table#"] = "no columns found for table #table#";
            }
        }
        return $createFixture(serializeJson(output), arguments.filePath);
    }

    private string function $getPrimaryKeys(required query columns) {
        var primaryKeys = [];
        for (column in arguments.columns) {
            if (column.is_primarykey) {
                arrayAppend(primaryKeys, column.column_name);
            }
        } 
        return arrayToList(primaryKeys);
    }

    private string function $createFixture(required string jsonOutput, required string filePath) {
        var jsonBeautifier = new JSONBeautifier(arguments.jsonOutput, this.indent);
        var dataDump = jsonBeautifier.format();
        if (len(arguments.filePath)) {
            if(fileExists(expandPath("/") & arguments.filePath) && !this.overWriteFileEnabled) {
                return "file exists, will not replace file";
            } else {
                fileWrite(expandPath("/") & arguments.filePath, dataDump);
                return "Writing file #arguments.filePath#";
            }
        } else {
            throw (type="Fixtures.IncorrectArguments", message="Missing file path to save file");
        }
    }

    private string function $primaryKeyValues(required struct result, required string primaryKeys) {
        var keys = "";
        for (key in arguments.primaryKeys) {
            if (len(keys)) {
                keys &= "_";
            }
            keys &= arguments.result[key];
        }
        return keys;
    }
}