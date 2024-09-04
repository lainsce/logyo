public class Logyo.LogWidget : Gtk.ListBoxRow {
    private Gtk.Label title;
    private Gtk.Label subtitle;

    // Common properties
    public string time { get; set; }
    public string description { get; set; }
    public string feeling { get; set; }
    public string feeling_icon { get; set; }
    public string motivation { get; set; }

    public signal void log_deleted();

    private LogStruct _log_struct;
    public LogStruct log_struct {
        get {
            return _log_struct;
        }
        set {
            _log_struct = value;
            update_labels();
        }
    }

    public LogWidget(LogStruct? log_struct) {
        LogStruct ls = { "", "", "Neutral", "neutral", "" };
        _log_struct = log_struct != null ? log_struct : ls;

        time = _log_struct.time;
        feeling = _log_struct.feeling;
        feeling_icon = _log_struct.feeling_icon;
        motivation = _log_struct.motivation;
        description = _log_struct.description;

        var icon = new Gtk.Image.from_icon_name (feeling_icon) {
            halign = Gtk.Align.START
        };
        icon.pixel_size = 48;

        title = new Gtk.Label("");
        title.set_xalign(0);
        title.add_css_class ("cb-title");

        subtitle = new Gtk.Label("");
        subtitle.set_xalign(0);
        title.add_css_class ("cb-subtitle");

        var delete_button = new He.Button ("user-trash-symbolic", "") {
            valign = Gtk.Align.START
        };
        delete_button.add_css_class ("circular");
        delete_button.clicked.connect(() => log_deleted());

        var label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            hexpand = true,
            valign = Gtk.Align.CENTER
        };
        label_box.append(icon);
        label_box.append(title);
        label_box.append(subtitle);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.append(label_box);
        box.append(delete_button);
        add_css_class ("mini-content-block");
        add_css_class ("logyo-feeling-block");

        box.set_parent (this);

        update_labels();
        update_styling (_log_struct.feeling);
    }

    public LogStruct from_log_struct() {
        return _log_struct;
    }
    public LogStruct to_log_struct() {
        update_log_struct();
        return _log_struct;
    }

    public virtual void update_log_struct() {
        _log_struct.time = time;
        _log_struct.feeling = feeling;
        _log_struct.feeling_icon = feeling_icon;
        _log_struct.motivation = motivation;
        _log_struct.description = description;
    }

    private void update_labels() {
        title.label = "%s - %s".printf(_log_struct.feeling, _log_struct.time);
        subtitle.label = "%s - %s".printf(_log_struct.description, _log_struct.motivation);
    }

    private void update_styling (string feel) {
        switch (feel) {
            case "Very Unpleasant":
                add_css_class ("very-unpleasant");
                break;
            case "Unpleasant":
                add_css_class ("unpleasant");
                break;
            case "Slightly Unpleasant":
                add_css_class ("slightly-unpleasant");
                break;
            case "Neutral":
                add_css_class ("neutral");
                break;
            case "Slightly Pleasant":
                add_css_class ("slightly-pleasant");
                break;
            case "Pleasant":
                add_css_class ("pleasant");
                break;
            case "Very Pleasant":
                add_css_class ("very-pleasant");
                break;
        }
    }
}