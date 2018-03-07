component output="false" {
    public any function init(required string jsonData, numeric indentBy = 4) {
        setJSON(arguments.jsonData);
        this.indent = arguments.indentBy;
        return this;
    }

    public void function setJSON(required string jsonData) {
        this.json = arguments.jsonData.toCharArray();
    }

    public string function format() {
        var newLine = createObject("java", "java.lang.System").getProperty("line.separator");
        var output = createObject("java", "java.lang.StringBuilder");
        var depth = 0;
        var insideQuote = false;
        for (var i = 1; i <= arrayLen(this.json); i++) {
            if ((this.json[i] == '}' || this.json[i] == ']') && !insideQuote) {
                depth--;
                output.append($appendNewLineWithIndent(depth, this.indent));
            }
            output.append(this.json[i]);
            if (((this.json[i] == '{' || this.json[i] == '[') || (this.json[i] == ',')) && !insideQuote) {
                if (this.json[i] != ',') depth++;
                output.append($appendNewLineWithIndent(depth, this.indent));
            }
            if (this.json[i] == ':' && !insideQuote) {
                output.append(" ");
            }
            if (this.json[i] == '"' && this.json[i-1] != "\") {
                insideQuote = !insideQuote;
            }
        }
        return output.toString();
    }

    private string function $appendNewLineWithIndent(required numeric depth, required numeric indent) {
        var output = createObject("java", "java.lang.StringBuilder");
        var newLine = createObject("java", "java.lang.System").getProperty("line.separator");
        return output.append(newLine).append(repeatString(" ", arguments.depth*arguments.indent));
    }
}