component extends="Base" output="false" accessors="true" {
    property array fixtures;
    property string pathOverLoad;
    property array parsedFixtures;
    property boolean isCreateTablesEnabled;
    property boolean isPopulateTablesEnabled;

    public any function init(required array fixtures, required string dataSource, string pathOverLoad = "", boolean isCreateTablesEnabled = true, boolean isPopulateTablesEnabled = true) {
        super.init();
        this.fixtures = arguments.fixtures;
        this.pathOverLoad = arguments.pathOverLoad;
        this.dataSourceName = arguments.dataSource;
        this.isCreateTablesEnabled = arguments.isCreateTablesEnabled;
        this.isPopulateTablesEnabled = arguments.isPopulateTablesEnabled;
        return this;
    }

    public array function parse() {
        var errors = [];
        var tables = [];
        for (fixture in this.fixtures) {
            var filePath = "";
            try {
                filePath = getFixtureFilePath(fixture);
                var fileOutput = fileRead(filePath);
            } catch (any e) {
                throw(type="Fixtures.LoadData.FileReadError", message="Could not read the fixture provided #filePath#");
            }
            var fixtureCollections = validateAndDeSerializeJson(fileOutput);
            tables.addAll(fixtureCollections);
        }
        if (!validateRelations(tables)) {
            throw(type="Fixtures.LoadData.IncompatibleAssociations", message="The uploaded fixtures is missing one or more database associations");
        }
        var orderOfOperations = $getOrderOfOperations(tables);
        return $executeCommands(orderOfOperations);
    }

    public void function enableCreateTables() {
        if (!this.isCreateTablesEnabled) {
            this.isCreateTablesEnabled = true;
        }
    }

    public void function disableCreateTables() {
        if (this.isCreateTablesEnabled) {
            this.isCreateTablesEnabled = false;
        }
    }

    public void function enablePopulateTables() {
        if (!this.isPopulateTablesEnabled) {
            this.isPopulateTablesEnabled = true;
        }
    }

    public void function disablePopulateTables() {
        if (this.isPopulateTablesEnabled) {
            this.isPopulateTablesEnabled = false;
        }
    }

    // ------------------------------------------------------------------------

    private array function $executeCommands(required array orderOfOperations) {
        var daoAdapter = getDatabaseFactory();
        var errors = [];
        for (item in arguments.orderOfOperations) {
            if (this.isCreateTablesEnabled && daoAdapter.tableExists(item.table)) {
                errors.append("The #item.table# table currently exists");
            } else if (this.isCreateTablesEnabled) {
                try {
                    errors.addAll(daoAdapter.createTable(item.columns, item.constraints, item.table));
                } catch (any e) {
                    errors.append("Unable to create the table #item.table#");
                }
            }
            if (this.isPopulateTablesEnabled) {
                try {
                    errors.addAll(daoAdapter.populate(item.records, item.columns, item.table));
                } catch (any e) {
                    errors.append("Unable to populate table #item.table# with items");
                }
            }
        }
        return errors;
    }

    private array function $getOrderOfOperations(required array fixtures, array sortedFixtures = [], numeric level = 1) {
        var tmpFixtures = arguments.fixtures.duplicate();
        var tmpLeftOverFixtures = arguments.fixtures.duplicate();
        var orderOfOperations = arguments.sortedFixtures.duplicate();
        if (arguments.level == 1) {
            for (i = arrayLen(tmpFixtures); i >= 1; i--) {
                if (!arrayLen(tmpFixtures[i].foreignTables)) {
                    orderOfOperations.append(tmpFixtures[i]);
                    tmpLeftOverFixtures.deleteAt(i);
                }
            }
            tmpFixtures = tmpLeftOverFixtures.duplicate();
        }
        for (i = arrayLen(tmpFixtures); i >= 1; i--) {
            var listOfTables = $arrayOfStructsValueList(orderOfOperations, "table");
            var found = true;
            for (tableName in tmpFixtures[i].foreignTables) {
                if (!listFindNoCase(listOfTables, tableName) && tableName != tmpFixtures[i].table) {
                    found = false;
                }
            }
            if (found) {
                orderOfOperations.append(tmpFixtures[i]);
                tmpLeftOverFixtures.deleteAt(i);
            } else {
                if (arrayLen(tmpLeftOverFixtures) > 1) {
                    var newFixture = $getOrderOfOperations(arraySlice(tmpLeftOverFixtures, 2), orderOfOperations, arguments.level+1);
                    orderOfOperations.append(newFixture);
                } else {
                    orderOfOperations.append($getOrderOfOperations(tmpLeftOverFixtures), orderOfOperations, arguments.level+1);
                }
            }
        }
        return orderOfOperations;
    }

    private boolean function validateRelations(required array fixtures) {
        var referencedPrimarykeyTable = [];
        for (fixture in fixtures) {
            fixture["foreignTables"] = [];
            fixture.columns = $formatFixtureColumns(fixture.columns);
            fixture.constraints = $formatFixtureColumns(fixture.constraints);
            for (column in fixture.columns) {
                if (column.referenced_primarykey_table != "N/A") {
                    referencedPrimarykeyTable.append(column.referenced_primarykey_table);
                    fixture["foreignTables"].append(column.referenced_primarykey_table);
                }
            }
        }
        var tableList = $arrayOfStructsValueList(arguments.fixtures, "table");
        for (tableName in referencedPrimarykeyTable) {
            if (!listFindNoCase(tableList, tableName)) {
                return false;
            }
        }
        return true;
    }

    private array function $formatFixtureColumns(required struct columns) {
        var parsedRows = [];
        if (!arguments.columns.keyExists("columns") || !arguments.columns.keyExists("data")) {
            throw(type="Fixtures.LoadData.IncompatibleFixtureColumns", message="An incompatible table structure exists in the fixture");
        }        
        for (item in arguments.columns.data) {
            var row = {};
            var count = 1;
            for (field in arguments.columns.columns) {
                var parsedVal = "";
                try {
                    parsedVal = item[count];
                } catch (any e) {}
                row[field] = parsedVal;
                count++;
            }
            parsedRows.append(row);
        }
        return parsedRows;
    }

    private string function $arrayOfStructsValueList(required array arrayOfStructures, required string key, string delimiter = ",") {
        var loc = {};
        loc.valueList = createObject("java", "java.lang.StringBuilder");
        loc.loopDelimiter = "";
        for(var structure in arguments.arrayOfStructures) {
            if (isStruct(structure)) {
                if (structure.keyExists(key)) {
                    loc.valueList.append(loc.loopDelimiter);
                    loc.valueList.append(structure[key]);
                    loc.loopDelimiter = arguments.delimiter;
                }
            }
        }
        return loc.valueList.toString();
    }
}