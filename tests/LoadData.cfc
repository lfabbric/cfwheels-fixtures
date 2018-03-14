component extends="wheels.Test" {

    function setup() {
        variables.loc = {};
        variables.loc.settings = {
            "format"= "json",
            "indent"= 4,
            "path"= "/plugins/fixtures/tests/fixtures/",
            "database"= "ppsmysqlloc",
            "database_schema"= "store",
            "unittest_database"= "ppsmysqltest",
            "unittest_database_schema"= "ppstest"
        };
        variables.loc.previousDataSourceName = get("dataSourceName");
    }

    function tearDown() {
        set(dataSourceName = variables.loc.previousDataSourceName);
    }

    function test_load_mysql_fixtures_from_multiple_tables_with_relationships() {
        try {
            loadData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json", "/plugins/fixtures/tests/fixtures/customers.json", "/plugins/fixtures/tests/fixtures/employees.json"], settings = variables.loc.settings);
        } catch (any e) {}
        // check if tables exists
        var dbinfo  = new dbinfo(dataSource = loc.settings.unittest_database);
        try {
            dbinfo.setTable("offices");
            assert("#dbinfo.columns().recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        try {
            dbinfo.setTable("customers");
            assert("#dbinfo.columns().recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        clearData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json", "/plugins/fixtures/tests/fixtures/customers.json", "/plugins/fixtures/tests/fixtures/employees.json"], settings = variables.loc.settings);
        try {
            dbinfo.setTable("employees");
            assert(false);
        } catch (any e) {
            assert(true);
        }
    }

    function test_load_missing_fixture() {
        try {
            loadData(
                fixtures = ["/plugins/fixtures/tests/fixtures/notfound.json"],
                enablePopulateTables = false,
                settings = variables.loc.settings
            );
        } catch (any e) {
            assert(true);
        }
    }

    function test_load_it_all() {
        var fixtureList = [
            variables.loc.settings.path & "customers.json",
            variables.loc.settings.path & "employees.json",
            variables.loc.settings.path & "offices.json",
            variables.loc.settings.path & "orderdetails.json",
            variables.loc.settings.path & "orders.json",
            variables.loc.settings.path & "payments.json",
            variables.loc.settings.path & "productlines.json",
            variables.loc.settings.path & "products.json"
        ];
        try {
            loadData(fixtures = fixtureList, settings = variables.loc.settings);
        } catch (any e) {}
        // check if tables exists
        var dbinfo  = new dbinfo(dataSource = loc.settings.unittest_database);
        try {
            dbinfo.setTable("offices");
            assert("#dbinfo.columns().recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        try {
            dbinfo.setTable("customers");
            assert("#dbinfo.columns().recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        clearData(fixtures = fixtureList, settings = variables.loc.settings);
        try {
            dbinfo.setTable("employees");
            assert(false);
        } catch (any e) {
            assert(true);
        }
    }
}