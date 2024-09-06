namespace Logyo.FileUtil {
    private string get_logyo_directory () {
        var path = Environment.get_user_data_dir () + "/logyo/";
        try {
            var dir = File.new_for_path (path);
            if (!dir.query_exists (null)) {
                dir.make_directory_with_parents (null);
            }
        } catch (Error e) {
            warning ("Failed to create directory: %s", e.message);
        }
        return path;
    }

    public void save_log (LogWidget log_widget, string filename) {
        var path = get_logyo_directory () + filename;
        try {
            var json_builder = new Json.Builder ();
            json_builder.begin_object ();
            json_builder.set_member_name ("logs");
            json_builder.begin_array ();

            var log_struct = log_widget.to_log_struct ();
            json_builder.add_value (log_struct.to_json ());

            json_builder.end_array ();
            json_builder.end_object ();

            var json_root = json_builder.get_root ();
            var json_generator = new Json.Generator ();
            json_generator.set_pretty (true);
            json_generator.set_root (json_root);
            json_generator.to_file (path);
        } catch (Error e) {
            warning ("Failed to save log: %s", e.message);
        }
    }
    public void save_logs (List<LogWidget> log_widgets, string filename) throws Error {
        var path = get_logyo_directory () + filename;
        try {
            var json_builder = new Json.Builder ();
            json_builder.begin_object ();
            json_builder.set_member_name ("logs");
            json_builder.begin_array ();

            foreach (LogWidget log_widget in log_widgets) {
                var log_struct = log_widget.to_log_struct ();
                json_builder.add_value (log_struct.to_json ());
            }

            json_builder.end_array ();
            json_builder.end_object ();

            var json_root = json_builder.get_root ();
            var json_generator = new Json.Generator ();
            json_generator.set_pretty (true);
            json_generator.set_root (json_root);
            json_generator.to_file (path);
        } catch (Error e) {
            warning ("Failed to save logs: %s", e.message);
        }
    }

    public List<LogWidget> load_logs (string filename) {
        var path = get_logyo_directory () + filename;
        var log_widgets = new List<LogWidget> ();

        var file = File.new_for_path (path);
        if (!file.query_exists ()) {
            warning ("File does not exist: %s", path);
            return log_widgets;
        }

        try {
            var json_parser = new Json.Parser ();
            json_parser.load_from_file (path);

            var root = json_parser.get_root ();

            if (root.get_node_type () == Json.NodeType.OBJECT) {
                var obj = root.get_object ();
                var array = obj.get_array_member ("logs");

                foreach (Json.Node node in array.get_elements ()) {
                    var bobj = node.get_object ();
                    LogStruct log_struct = LogStruct.from_json (bobj);
                    var log_widget = new LogWidget (log_struct);
                    log_widgets.append (log_widget);
                }
            } else {
                warning ("Root JSON node is not an object.");
            }
        } catch (Error e) {
            warning ("Failed to load logs: %s", e.message);
        }

        return log_widgets;
    }
}
