# Plugin: Fixtures

## Purpose

The cfwheels fixtures provides utilities to dump database tables into json fixtures or load json fixtures and create/populate database tables.

## Requirements
Coldfusion
 - Lucee 5
 - Adobe Coldfusion 2016

Databases
 - SQL Server
 - MySQL

## Configuration

create a fixtures folder in your cfwheels tests folder. 
```
    cfwheels_home/tests/fixtures
```

## Usage

### Dump Data
Providing table names, the dumpData method will pull the structure and table rows and generate a fixture.  You can provide 1 or many tables for each fixture
```java
dumpData(
    tables = ["tablenames","users","markets"],
    filePath = "tests/fixtures/markets.json",
    overWriteFileEnabled = true,
    maxRows = 50
);
```

#### Parameters
Parameter | Type | Required | Default | Description
--- | --- | --- | --- | ---
tables | `array` | true |  | Specify which tables to prep for the fixture dump.
filePath | `string` | optional | | Overload the file path, if no file path is provided, the fixture will be saved to the cfwheels home folder.
overWriteFileEnabled | `boolean` | optional | false | If a fixture exists, you can either over write it or leave it as is.
maxRows | `numeric` | optional | -1 | You can reduce the number of records fetched from each table.

---

### Load Data
The loaddata can be called from anywhere, however, it is common to load from unit tests
```java
loadData(fixtures = ["markets.json"]);
```

You can also load multiple fixtures at a time by adding items to the array.  The path can be supplied when specifying the fixture, however, if one is not provided  it will automatically look in the root folder of the cfwheels_home/tests/fixtures folder.
```java
loadData(fixtures = ["markets.json", "fixture2.json", "/lib/fixture3.json"]);
```

#### Parameters
Parameter | Type | Required | Default | Description
--- | --- | --- | --- | ---
fixtures | `array` | true |  | Specify which files to load the fixtures from.
enableCreateTables | `boolean` | optional | true | When loading data, you can either create tables or use existing tables.
enablePopulateTables | `boolean` | optional | true | When loading data, you can either populate tables or not.

--- 

### Clear Data
Wipe database tables clean... In other words, drop tables specified in your fixtures.
```java
    clearData(fixtures = ["markets.json"]);
```

#### Parameters
Parameter | Type | Required | Default | Description
--- | --- | --- | --- | ---
fixtures | `array` | true |  | Specify which files to load the fixtures from.


## Example

```java
component extends="wheelsMapping.Test" {

    function setup() {
        loadData(fixtures = ["users.json"]);
    }

    function tearDown() {
        clearData(fixtures = ["users.json"]);
    }

    function test_user_authentication() {
        user = model("user").findOne(
            where = "id=12345",
            include = "roles"
        );
        assert("user.canAuthenticate()");
    }
}
```