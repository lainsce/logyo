public struct Logyo.LogStruct {
    public string time;
    public string feeling;
    public string feeling_icon;
    public string description;
    public string motivation;

    public Json.Node to_json () {
        Json.Object obj = new Json.Object ();
        obj.set_string_member ("time", this.time);
        obj.set_string_member ("feeling", this.feeling);
        obj.set_string_member ("feeling-icon", this.feeling_icon);
        obj.set_string_member ("description", this.description);
        obj.set_string_member ("motivation", this.motivation);
        var node = new Json.Node (Json.NodeType.OBJECT);
        node.set_object (obj);
        return node;
    }

    public static LogStruct from_json (Json.Object obj) {
        return {
            obj.get_string_member ("time"),
            obj.get_string_member ("feeling"),
            obj.get_string_member ("feeling-icon"),
            obj.get_string_member ("description"),
            obj.get_string_member ("motivation")
        };
    }
}
