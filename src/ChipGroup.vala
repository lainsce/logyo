public class ChipGroup : He.Bin {
    private List<Gtk.ToggleButton> buttons = new List<Gtk.ToggleButton> ();
    public List<string> selected_values = new List<string> ();
    private Gtk.FlowBox fb;
    private string[] all_options;
    private int initial_count;

    public signal void selection_changed ();
    public signal void all_selections_cleared ();

    public ChipGroup (string[] options, int initial_count = -1) {
        this.all_options = options;
        this.initial_count = initial_count;
        fb = new Gtk.FlowBox ();

        setup_chips ();

        fb.homogeneous = false;
        fb.max_children_per_line = 3;
        fb.min_children_per_line = 3;
        fb.row_spacing = 6;
        fb.column_spacing = 1;
        fb.selection_mode = Gtk.SelectionMode.NONE;

        child = fb;

        update_selected_values ();
    }

    private void setup_chips () {
        int count = 0;
        foreach (string option in all_options) {
            if (initial_count > 0 && count >= initial_count) {
                break;
            }
            add_chip (option);
            count++;
        }
    }

    private void add_chip (string option) {
        var button = new Gtk.ToggleButton ();
        button.label = option;
        button.add_css_class ("chip");
        button.toggled.connect (() => {
            update_selected_values ();
            selection_changed ();
        });
        buttons.append (button);
        fb.append (button);
    }

    public void show_all_chips () {
        foreach (string option in all_options) {
            if (buttons != null) {
                add_chip (option);
            }
        }
    }

    private void update_selected_values () {
        selected_values = null;
        foreach (var button in buttons) {
            if (button.active) {
                selected_values.append (button.label);
            }
        }
        if (selected_values.length () == 0) {
            all_selections_cleared ();
        }
    }

    public void reset_selections () {
        foreach (var button in buttons) {
            button.active = false;
        }
        selected_values = null;
        all_selections_cleared ();
        selection_changed ();
    }

    public void set_selections (List<string> selections) {
        foreach (var button in buttons) {
            selected_values = null;
            if (selections.find_custom (button.label, strcmp) != null) {
                button.active = true;
                update_selected_values ();
                selection_changed ();
            } else {
                button.active = false;
                foreach (string option in selections) {
                    selected_values.append (option);
                }
                selection_changed ();
            }
        }
    }
}
