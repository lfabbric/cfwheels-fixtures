component {
    property string dataSourceName;

    public any function init() {
        return this;
    }

    public adapters.AdapterIF function getDatabaseFactory() {
        var dbInfo = new dbinfo(dataSource = this.dataSourceName);
        var dbDriverName = replace(dbInfo.version().database_productname, " ", "-", "all");
        switch(dbDriverName) {
            case "Microsoft-SQL-Server":
                return new adapters.SQLServer(this.dataSourceName);
                break;
            default:
                throw(type="Fixtures.DatabaseFactory.IncompatibleDataBase", message="This plugin does not support the database #dbDriverName#");
                break;
        }
    }

    public string function getFixtureFilePath(required string fixture) {
        var fullPath = this.pathOverLoad & fixture;
        if (arguments.fixture.toString().find("/")) {
            fullPath = fixture;
        }
        return expandPath("/") & fullPath;
    }

    public array function validateAndDeSerializeJson(required string json) {
        try {
            var fixtures = deSerializeJson(arguments.json);
            var columns = "columns,primarykeys,records,table";
            if (isArray(fixtures)) {
                for (var fixture in fixtures) {
                    for (var column in columns) {
                        if (!fixture.keyExists(column)) {
                            throw(type="Fixtures.LoadData.InvalidColumns", message="The Fixture is not fomatted correctly, missing columns"); 
                        }
                    }
                }
            } else {
                throw(type="Fixtures.LoadData.InvalidDataType", message="The Fixture does not contain an array"); 
            }
        } catch (any e) {
            throw(type="Fixtures.LoadData.InvalidParseType", message="The Fixture could not be parsed correctly");
        }
        return fixtures;
    }
}