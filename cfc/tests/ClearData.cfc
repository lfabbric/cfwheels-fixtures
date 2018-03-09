component extends="wheels.Test" {

    function setup() {
        //loadData(fixtures = ["users.json"]);
    }

    function tearDown() {
        //clearData(fixtures = ["users.json"]);
    }

    function test_clear_mysql_table() {
        // The complextables.json should contain a number of fields and rows to simulate multiple conditions in a table.
        loadData(fixtures = ["/plugins/fixtures/tests/fixtures/complextables.json"], enablePopulateTables = false);

    }
}