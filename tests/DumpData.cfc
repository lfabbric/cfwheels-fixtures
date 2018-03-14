component extends="wheels.Test" {

    function setup() {
        variables.loc = {};
        variables.loc.settings = {
            "format"= "json",
            "indent"= 4,
            "path"= "/plugins/fixtures/tests/fixtures/",
            "database"= "ppsmysqlloc",
            "unittest_database"= "store"
        };
        variables.loc.previousDataSourceName = get("dataSourceName");
    }

    function tearDown() {
        set(dataSourceName = variables.loc.previousDataSourceName);
    }

    function test_dump_mysql_table() {
        var previousDataSourceName = get("dataSourceName");
        set(dataSourceName = loc.settings.database);
        dumpData(
            tables = ["offices"], 
            filePath = "plugins/fixtures/tests/fixtures/offices2.json",
            overWriteFileEnabled = true,
            settings = variables.loc.settings
        );
        if (fileExists(expandpath(variables.loc.settings.path & "offices2.json"))) {
            assert(true);
            fileDelete(expandpath(variables.loc.settings.path & "offices2.json"));
        } else {
            assert(false);
        }
    }

    function test_dump_mysql_table_correct_content() {
        var previousDataSourceName = get("dataSourceName");
        set(dataSourceName = loc.settings.database);
        dumpData(
            tables = ["offices"], 
            filePath = "plugins/fixtures/tests/fixtures/offices2.json",
            overWriteFileEnabled = true,
            settings = variables.loc.settings
        );
        if (fileExists(expandpath(variables.loc.settings.path & "offices2.json"))) {
            assert(true);
            var fixtureContent = fileRead(expandpath(variables.loc.settings.path & "offices2.json"));
            var serializedContent = deSerializeJSON(fixtureContent);
            
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

            fileDelete(expandpath(variables.loc.settings.path & "offices2.json"));
        } else {
            assert(false);
        }
    }
}