component hint="cfwheels fixture support" output="false" mixin="global" {
    public function init() {
        this.version = "1.4.5,2.0";
        return this;
    }

    public function loadData(array fixtures = [], boolean enableCreateTables = true, boolean enablePopulateTables = true) {
        if (!arrayLen(arguments.fixtures)) {
            throw(type="Fixtures.Missing", message="Missing fixtures to load");
        }
        var settings = $loadFixtureSettings();
        var dataSourceName = $getFixtureDataSourceName();
        var loadDataObj = new cfc.LoadData(
            arguments.fixtures,
            dataSourceName,
            settings.path,
            arguments.enableCreateTables,
            arguments.enablePopulateTables
        );
        loadDataObj.parse();
    }

    public string function dumpData(required array tables, string filePath = "", boolean overWriteFileEnabled = false, numeric maxRows = -1) {
        var settings = $loadFixtureSettings();
        var dumpDataObj = new cfc.DumpData(
            tables = arguments.tables,
            dataSource = $getFixtureDataSourceName(isUnitTest=false),
            maxRows = arguments.maxRows,
            overWriteEnabled = arguments.overWriteFileEnabled
        );
        dumpDataObj.setIndent(settings.indent);
        return dumpDataObj.execute(arguments.filePath);
    }

    public function clearData(array fixtures = []) {
         if (!arrayLen(arguments.fixtures)) {
            throw(type="Fixtures.Missing", message="Missing fixtures to load");
        }
        var settings = $loadFixtureSettings();
        var dataSourceName = $getFixtureDataSourceName();
        var clearDataObj = new cfc.ClearData(
            arguments.fixtures,
            dataSourceName,
            settings.path
        );
        clearDataObj.execute();
    }

    // @hint private
    public string function $getFixtureDataSourceName(boolean isUnitTest = true, string overLoadDataSourceName = "dataSourceName") {
        var settings = $loadFixtureSettings();
        var dataSourceName = get(arguments.overLoadDataSourceName);
        if (settings.keyExists("unittest_database") && len(settings.unittest_database) && arguments.isUnitTest) {
            dataSourceName = settings.unittest_database;
        }
        return dataSourceName;
    }

    public struct function $loadFixtureSettings() {
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
