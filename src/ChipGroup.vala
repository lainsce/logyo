public class ChipGroup : He.Bin {
    private List<Gtk.ToggleButton> buttons = new List<Gtk.ToggleButton> ();
    public List<string> selected_values = new List<string> ();

    public signal void selection_changed ();

    public ChipGroup (string[] options) {
        var fb = new Gtk.FlowBox ();

        foreach (string option in options) {
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

        fb.homogeneous = false;
        fb.max_children_per_line = 0;
        fb.min_children_per_line = 3;
        fb.row_spacing = 6;
        fb.column_spacing = 12;
        fb.selection_mode = Gtk.SelectionMode.NONE;

        child = fb;

        update_selected_values ();
    }

    private void update_selected_values () {
        // Clear
        selected_values = null;
        // then populate.
        foreach (var button in buttons) {
            if (button.active) {
                selected_values.append (button.label);
            }
        }
    }
    public void reset_selections () {
        foreach (var button in buttons) {
            button.active = false;
        }
        selected_values = null;
        selection_changed ();
    }
}
