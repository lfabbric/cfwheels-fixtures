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

    function test_clear_mysql_table_with_no_relations() {
        var errors = [];
        try {
            errors = loadData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json"], enablePopulateTables = false, settings = variables.loc.mysql.settings);
        } catch (any e) {}
        // check if tables exists
        try {
            cfdbinfo( name="dbinfo", type="columns", table="offices", datasource=loc.mysql.settings.database );
            assert("#dbinfo.recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        clearData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json"], settings = variables.loc.mysql.settings);
        try {
            cfdbinfo( name="dbinfo", type="columns", table="offices", datasource=loc.mysql.settings.database );
            assert(false);
        } catch (any e) {
            assert(true);
        }
    }

    function test_clear_mysql_tables_from_multiple_fixtures() {
        // this also tested associations...
        try {
            loadData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json", "/plugins/fixtures/tests/fixtures/customers.json", "/plugins/fixtures/tests/fixtures/employees.json"], settings = variables.loc.mysql.settings);
        } catch (any e) {}
        // check if tables exists
        try {
            cfdbinfo( name="dbinfo", type="columns", table="offices", datasource=loc.mysql.settings.database );
            assert("#dbinfo.recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        try {
            cfdbinfo( name="dbinfo", type="columns", table="customers", datasource=loc.mysql.settings.database );
            assert("#dbinfo.recordCount# gt 0");
        } catch (any e) {
            assert(false);
        }
        clearData(fixtures = ["/plugins/fixtures/tests/fixtures/orders.json"], settings = variables.loc.mysql.settings);
        try {
            cfdbinfo( name="dbinfo", type="columns", table="employees", datasource=loc.mysql.settings.database );
            assert(false);
        } catch (any e) {
            assert(true);
        }
    }
}