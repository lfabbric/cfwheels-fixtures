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
        var dbinfo  = new dbinfo(dataSource = this.dataSourceName);
        for (table in this.tables) {
            dbinfo.setTable(table);
            try {
                var response = {};
                response.table = table;
                response.columns = dbinfo.columns();
                response.constraints = daoAdapter.getConstraints(table);
                response.records = [];
                // cant find non-plurar tables
                var tmpModel = new wheels.Model().$initModelClass("#table#", "");
                var results = tmpModel.findAll(maxRows=this.maxRows);
                var primaryKeys = tmpModel.primaryKeys();
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