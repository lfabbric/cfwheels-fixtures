interface {
    any function init(required string dataSource);
    boolean function tableExists(required string table);
    array function createTable(required array tableDefinition, required array tableConstraints, required string table);
    array function dropTable(required string table);
    array function populate(required array results, required tableDefinitions, required string table);
    query function getConstraints(required string table);
    array function findAll(required string table, numeric maxRows);
}