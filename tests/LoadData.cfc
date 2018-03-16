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

    function test_load_mysql_fixtures_from_multiple_tables_with_relationships() {
        if (getDataBaseType() != "mysql") {
            loc.message = "This test has been Skipped - The test runner is using on a different database: #getDataBaseType()#";
            debug("loc.message");
            assert(true);
            return;
        }
        try {
            loadData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json", "/plugins/fixtures/tests/fixtures/customers.json", "/plugins/fixtures/tests/fixtures/employees.json"], settings = variables.loc.mysql.settings);
        } catch (any e) {}
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
        clearData(fixtures = ["/plugins/fixtures/tests/fixtures/offices.json", "/plugins/fixtures/tests/fixtures/customers.json", "/plugins/fixtures/tests/fixtures/employees.json"], settings = variables.loc.mysql.settings);
        try {
            cfdbinfo( name="dbinfo", type="columns", table="employees", datasource=loc.mysql.settings.database );
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
                settings = variables.loc.mysql.settings
            );
        } catch (any e) {
            assert(true);
        }
    }

    function test_load_it_all() {
        if (getDataBaseType() != "mysql") {
            loc.message = "This test has been Skipped - The test runner is using on a different database: #getDataBaseType()#";
            debug("loc.message");
            assert(true);
            return;
        }
        var fixtureList = [
            variables.loc.mysql.settings.path & "customers.json",
            variables.loc.mysql.settings.path & "employees.json",
            variables.loc.mysql.settings.path & "offices.json",
            variables.loc.mysql.settings.path & "orderdetails.json",
            variables.loc.mysql.settings.path & "orders.json",
            variables.loc.mysql.settings.path & "payments.json",
            variables.loc.mysql.settings.path & "productlines.json",
            variables.loc.mysql.settings.path & "products.json"
        ];
        try {
            loadData(fixtures = fixtureList, settings = variables.loc.mysql.settings);
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
        clearData(fixtures = fixtureList, settings = variables.loc.mysql.settings);
        try {
            cfdbinfo( name="dbinfo", type="columns", table="employees", datasource=loc.mysql.settings.database );
            assert(false);
        } catch (any e) {
            assert(true);
        }
    }
}