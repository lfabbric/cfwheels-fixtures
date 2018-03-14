component hint="cfwheels fixture support" output="false" mixin="global" {
    public function init() {
        this.version = "1.4.5,2.0";
        return this;
    }

    public function loadData(array fixtures = [], boolean enableCreateTables = true, boolean enablePopulateTables = true) {
        if (!arrayLen(arguments.fixtures)) {
            throw(type="Fixtures.Missing", message="Missing fixtures to load");
        }
        var settings = $loadFixtureSettings(argumentCollection=arguments);
        var dataSourceName = $getFixtureDataSourceName();
        var loadDataObj = new cfc.LoadData(
            arguments.fixtures,
            dataSourceName,
            settings.path,
            arguments.enableCreateTables,
            arguments.enablePopulateTables
        );
        if (settings.keyExists("unittest_database_schema") && len(settings.unittest_database_schema)) {
            loadDataObj.setDataSourceSchema(settings.unittest_database_schema);
        }
        return loadDataObj.parse();
    }

    public string function dumpData(required array tables, string filePath = "", boolean overWriteFileEnabled = false, numeric maxRows = -1) {
        var settings = $loadFixtureSettings(argumentCollection=arguments);
        var dumpDataObj = new cfc.DumpData(
            tables = arguments.tables,
            dataSource = $getFixtureDataSourceName(isUnitTest=false, argumentCollection=arguments),
            maxRows = arguments.maxRows,
            overWriteFileEnabled = arguments.overWriteFileEnabled
        );
        dumpDataObj.setIndent(settings.indent);
        if (settings.keyExists("database_schema") && len(settings.database_schema)) {
            dumpDataObj.setDataSourceSchema(settings.database_schema);
        }
        return dumpDataObj.execute(arguments.filePath);
    }

    public array function clearData(array fixtures = []) {
        if (!arrayLen(arguments.fixtures)) {
            throw(type="Fixtures.Missing", message="Missing fixtures to load");
        }
        var settings = $loadFixtureSettings(argumentCollection=arguments);
        var dataSourceName = $getFixtureDataSourceName();
        var clearDataObj = new cfc.ClearData(
            arguments.fixtures,
            dataSourceName,
            settings.path
        );
        if (settings.keyExists("unittest_database_schema") && len(settings.unittest_database_schema)) {
            clearDataObj.setDataSourceSchema(settings.unittest_database_schema);
        }
        return clearDataObj.execute();
    }

    // @hint private
    public string function $getFixtureDataSourceName(boolean isUnitTest = true) {
        var settings = $loadFixtureSettings(argumentCollection=arguments);
        var dataSourceName = get("dataSourceName");
        if (settings.keyExists("database") && len(settings.database) && !arguments.isUnitTest) {
            dataSourceName = settings.database;
        } else if (settings.keyExists("unittest_database") && len(settings.unittest_database) && arguments.isUnitTest) {
            dataSourceName = settings.unittest_database;
        }
        return dataSourceName;
    }

    public struct function $loadFixtureSettings() {
        if (arguments.keyExists("settings")) {
            return arguments.settings;
        }
        var found = false;
        var loc = {};
        if (IsDefined("params") && params.keyExists("reload")) {
            structDelete(application.plugins, "fixtures");
        }
        lock name = "getSettings" timeout = "5" type = "readonly" {
            if (application.keyExists("plugins") && application.plugins.keyExists("fixtures") && application.plugins.fixtures.keyExists("createdat")) {
                if (application.plugins.fixtures.keyExists("settings") && datediff("s", application.plugins.fixtures.createdat, now()) <= 15) {
                    return application.plugins.fixtures.settings.duplicate();
                }
            }
        }
        var appKey = $appKey();
        pluginPath = application[appKey].webPath & application[appKey].pluginPath;
        var path = pluginPath & "/fixtures/settings.json";
        if (fileExists(expandpath(path))) {
            var settings = fileRead(expandpath(path), "utf-8");
            settings = deserializeJSON(settings);
            lock timeout = "10" scope = "application" type = "exclusive" {
                application.plugins.fixtures = {
                    "createdat" = now(),
                    "settings" = settings
                };
            }
            return application.plugins.fixtures.settings.duplicate();
        }
        return {};
    }
}
