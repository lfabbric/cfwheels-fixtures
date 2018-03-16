component extends="wheels.Test" {

    function setup() {
        variables.loc = {};
        variables.loc.mysql.settings = {
            "format"= "json",
            "indent"= 4,
            "path"= "/plugins/fixtures/tests/fixtures/",
            "database"= "store",
            "unittest_database"= "storetest"
        };
        variables.loc.previousDataSourceName = get("dataSourceName");
    }

    function tearDown() {
        set(dataSourceName = variables.loc.previousDataSourceName);
    }

    function getDataBaseType() {
        cfdbinfo( name="dbinfo", type="version", datasource=loc.mysql.settings.database );
        return lcase(replace(dbInfo.database_productname, " ", "-", "all"));
    }

    function test_dump_mysql_table() {
        if (getDataBaseType() != "mysql") {
            loc.message = "This test has been Skipped - The test runner is using on a different database: #getDataBaseType()#";
            debug("loc.message");
            assert(true);
            return;
        }
        var previousDataSourceName = get("dataSourceName");
        set(dataSourceName = loc.mysql.settings.database);
        dumpData(
            tables = ["offices"], 
            filePath = "plugins/fixtures/tests/fixtures/offices2.json",
            overWriteFileEnabled = true,
            settings = variables.loc.mysql.settings
        );
        if (fileExists(expandpath(variables.loc.mysql.settings.path & "offices2.json"))) {
            assert(true);
            fileDelete(expandpath(variables.loc.mysql.settings.path & "offices2.json"));
        } else {
            assert(false);
        }
    }

    function test_dump_mysql_table_correct_content() {
        if (getDataBaseType() != "mysql") {
            loc.message = "This test has been Skipped - The test runner is using on a different database: #getDataBaseType()#";
            debug("loc.message");
            assert(true);
            return;
        }
        var previousDataSourceName = get("dataSourceName");
        set(dataSourceName = loc.mysql.settings.database);
        dumpData(
            tables = ["offices"], 
            filePath = "plugins/fixtures/tests/fixtures/offices2.json",
            overWriteFileEnabled = true,
            settings = variables.loc.mysql.settings
        );
        if (fileExists(expandpath(variables.loc.mysql.settings.path & "offices2.json"))) {
            var fixtureContent = fileRead(expandpath(variables.loc.mysql.settings.path & "offices2.json"));
            var serializedContent = deSerializeJSON(fixtureContent);
            
            if (!arrayLen(serializedContent)) {
                message = "DataDump failed - No data found";
                debug("message");
                assert(false);
            }

            if (!serializedContent[1].keyExists("columns") && !arrayLen(serializedContent[1].columns)) {
                message = "Missing the columns key";
                debug("message");
                assert(false);
            }

            if (serializedContent[1].keyExists("columns") && serializedContent[1].columns.keyExists("columns") && !arrayLen(serializedContent[1].columns.columns)) {
                message = "Missing the nested columns key";
                debug("message");
                assert(false);
            }

            if (serializedContent[1].keyExists("columns") && serializedContent[1].columns.keyExists("data") && !arrayLen(serializedContent[1].columns.data)) {
                message = "Missing the nested data key";
                debug("message");
                assert(false);
            }

            if (!serializedContent[1].keyExists("records") && !arrayLen(serializedContent[1].records)) {
                message = "Missing the records key";
                debug("message");
                assert(false);
            }

            if (!serializedContent[1].keyExists("table") && !len(serializedContent[1].table)) {
                message = "Missing the table key";
                debug("message");
                assert(false);
            }

            if (!serializedContent[1].keyExists("constraints") && !len(serializedContent[1].constraints)) {
                message = "Missing the constraints key";
                debug("message");
                assert(false);
            }

            fileDelete(expandpath(variables.loc.mysql.settings.path & "offices2.json"));
        } else {
            assert(false);
        }
    }
}