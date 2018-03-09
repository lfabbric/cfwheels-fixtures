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

    function test_clear_mysql_table_with_no_relations() {
        try {
            loadData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json"], enablePopulateTables = false, settings = variables.loc.settings);
        } catch (any e) {}
        // check if tables exists
        var dbinfo  = new dbinfo(dataSource = loc.settings.unittest_database);
        try {
            dbinfo.setTable("offices");
            assert("#dbinfo.columns().recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        clearData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json"], settings = variables.loc.settings);
        
        var dbinfo  = new dbinfo(dataSource = loc.settings.unittest_database);
        try {
            dbinfo.setTable("offices");
            assert(false);
        } catch (any e) {
            assert(true);
        }
    }

    function test_clear_mysql_tables_from_multiple_fixtures() {
        // this also tested associations...
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
        clearData(fixtures = ["/plugins/fixtures/tests/fixtures/orders.json"], settings = variables.loc.settings);
        try {
            dbinfo.setTable("employees");
            assert(false);
        } catch (any e) {
            assert(true);
        }
    }
}