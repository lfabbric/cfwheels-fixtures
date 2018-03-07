component extends="Base" output="false" accessors="true" {
    property array fixtures;

    public any function init(required array fixtures, required string dataSource, string pathOverLoad = "") {
        super.init();
        this.fixtures = arguments.fixtures;
        this.pathOverLoad = arguments.pathOverLoad;
        this.dataSourceName = arguments.dataSource;
        return this;
    }

    public array function execute() {
        var errors = [];
        var tables = [];
        for (fixture in this.fixtures) {
            try {
                var filePath = getFixtureFilePath(fixture);
                var fileOutput = fileRead(filePath);
            } catch (any e) {
                throw(type="Fixtures.CleanData.FileReadError", message="Could not read the fixture provided");
            }
            var fixtureCollections = validateAndDeSerializeJson(fileOutput);
            tables.addAll(fixtureCollections);
        }
        $clean(tables);
        abort;
    }

    private void function $clean(required array parsedFixtures) {
        var daoAdapter = getDatabaseFactory();
        for (fixture in arguments.parsedFixtures) {
            if (daoAdapter.tableExists(fixture.table)) {
                daoAdapter.dropTable(fixture.table);
            }
        }
    }
}