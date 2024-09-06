public class Logyo.LogWidget : Gtk.FlowBoxChild {
    private Gtk.Label timel;
    private Gtk.Label descriptionl;
    private Gtk.Label feelingl;
    private Gtk.Label motivationl;

    // Common properties
    public string time { get; set; }
    public string description { get; set; }
    public string feeling { get; set; }
    public string feeling_icon { get; set; }
    public string motivation { get; set; }

    public signal void log_deleted ();

    private LogStruct _log_struct;
    public LogStruct log_struct {
        get {
            return _log_struct;
        }
        set {
            _log_struct = value;
            update_labels ();
        }
    }

    public LogWidget (LogStruct? log_struct) {
        LogStruct ls = { "", "", "Neutral", "neutral", "" };
        _log_struct = log_struct != null ? log_struct : ls;

        time = _log_struct.time;
        feeling = _log_struct.feeling;
        feeling_icon = _log_struct.feeling_icon;
        motivation = _log_struct.motivation;
        description = _log_struct.description;

        var icon = new Gtk.Image.from_icon_name (feeling_icon) {
            halign = Gtk.Align.CENTER
        };
        icon.pixel_size = 128;

        timel = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            hexpand = true
        };
        timel.add_css_class ("logyo-caption");

        feelingl = new Gtk.Label ("");
        feelingl.add_css_class ("logyo-subtitle");

        descriptionl = new Gtk.Label ("");
        descriptionl.add_css_class ("logyo-title");

        motivationl = new Gtk.Label ("");
        motivationl.add_css_class ("logyo-caption");

        var delete_button = new He.Button ("user-trash-symbolic", "") {
            valign = Gtk.Align.START,
            margin_end = -12,
            margin_start = 12
        };
        delete_button.add_css_class ("circular");
        delete_button.clicked.connect (() => log_deleted ());

        var label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            valign = Gtk.Align.CENTER
        };
        label_box.append (timel);
        label_box.append (delete_button);

        var desc_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        desc_box.append (descriptionl);
        desc_box.append (feelingl);
        desc_box.append (motivationl);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24);
        box.append (label_box);
        box.append (delete_button);
        box.append (icon);
        box.append (desc_box);
        add_css_class ("mini-content-block");
        add_css_class ("logyo-feeling-block");

        box.set_parent (this);

        update_labels ();
        update_styling (_log_struct.feeling);
    }

    public LogStruct from_log_struct () {
        return _log_struct;
    }
    public LogStruct to_log_struct () {
        update_log_struct ();
        return _log_struct;
    }

    public virtual void update_log_struct () {
        _log_struct.time = time;
        _log_struct.feeling = feeling;
        _log_struct.feeling_icon = feeling_icon;
        _log_struct.motivation = motivation;
        _log_struct.description = description;
    }

    private void update_labels () {
        timel.label = "%s".printf (_log_struct.time);
        descriptionl.label = "%s".printf (_log_struct.description);
        feelingl.label = "%s".printf (_log_struct.feeling);
        motivationl.label = "%s".printf (_log_struct.motivation);
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
