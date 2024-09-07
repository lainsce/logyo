public class ChipGroup : He.Bin {
    private GLib.List<Gtk.ToggleButton>? buttons = null;
    public GLib.List<string>? selected_values = null;

    private Gtk.FlowBox fb;

    public signal void selection_changed ();

    public ChipGroup (string[] options) {
        fb = new Gtk.FlowBox ();

        foreach (string option in options) {
            if (option != "") {
                add_button (option);
            }
        }

        fb.width_request = 350;
        fb.homogeneous = false;
        fb.max_children_per_line = 3;
        fb.min_children_per_line = 3;
        fb.row_spacing = 6;
        fb.column_spacing = 6;
        fb.selection_mode = Gtk.SelectionMode.NONE;

        child = fb;
    }

    public void reset_selections () {
        if (selected_values != null) {
            foreach (var button in buttons) {
                if (button.active) {
                    button.active = false;
                }
            }
            selected_values = null; // Clear the list by setting it to null
            selection_changed ();
        }
    }

    public void add_button (string label) {
        if (label == "") {
            return; // Skip invalid input early
        }

        var button = new Gtk.ToggleButton ();
        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
        var label_widget = new Gtk.Label (label) {
            halign = Gtk.Align.CENTER,
            hexpand = true
        };
        var icon = new Gtk.Image.from_icon_name ("emblem-default-symbolic");

        hbox.append (icon);
        hbox.append (label_widget);
        icon.hide (); // Hide the icon initially

        button.child = hbox;
        button.add_css_class ("chip");
        button.width_request = 80;

        button.toggled.connect (() => {
            if (button.active) {
                icon.show ();
                selected_values.prepend (label);
            } else {
                icon.hide ();
                selected_values.remove (label);
            }
            selection_changed ();
        });

        buttons.prepend (button);
        fb.append (button);
        button.show (); // Show only the added button instead of the entire container
    }

    public void remove_button (Gtk.ToggleButton button) {
        if (buttons != null) {
            buttons.remove (button); // Remove from the list
            fb.remove (button);
            if (button.active && selected_values != null) {
                var hbox = (Gtk.Box) button.child;
                var label = (Gtk.Label) hbox.get_first_child ().get_next_sibling ();
                selected_values.remove (label.label); // Maintain selected_values consistency
            }
            selection_changed ();
        }
    }

    public void set_button_style (string style_class) {
        foreach (var button in buttons) {
            button.add_css_class (style_class);
        }
    }

    public new void select_all () {
        if (buttons != null && (selected_values == null || selected_values.length () < buttons.length ())) {
            foreach (var button in buttons) {
                if (!button.active) {
                    button.active = true;
                    var hbox = (Gtk.Box) button.child;
                    var icon = (Gtk.Image) hbox.get_first_child ();
                    icon.show ();
                    var label = (Gtk.Label) icon.get_next_sibling ();
                    selected_values.prepend (label.label); // Avoid unnecessary updates
                }
            }
            selection_changed ();
        }
    }

    public void deselect_all () {
        if (selected_values != null) {
            foreach (var button in buttons) {
                if (button.active) {
                    button.active = false;
                    var hbox = (Gtk.Box) button.child;
                    var icon = (Gtk.Image) hbox.get_first_child ();
                    icon.hide ();
                }
            }
            selected_values = null; // Clear the list by setting it to null
            selection_changed ();
        }
    }

    public void toggle_selection (Gtk.ToggleButton button) {
        if (buttons != null) {
            button.active = !button.active;
            var hbox = (Gtk.Box) button.child;
            var icon = (Gtk.Image) hbox.get_first_child ();
            var label = (Gtk.Label) icon.get_next_sibling ();
            if (button.active) {
                icon.show ();
                selected_values.prepend (label.label);
            } else {
                icon.hide ();
                selected_values.remove (label.label);
            }
            selection_changed ();
        }
    }

    public bool is_selected (string label) {
        if (buttons != null) {
            foreach (var button in buttons) {
                var hbox = (Gtk.Box) button.child;
                var label_widget = (Gtk.Label) hbox.get_first_child ().get_next_sibling ();
                if (label_widget.label == label) {
                    return button.active;
                }
            }
        }
        return false;
    }

    public Gtk.ToggleButton? find_button_by_label (string label) {
        if (buttons != null) {
            foreach (var button in buttons) {
                var hbox = (Gtk.Box) button.child;
                var label_widget = (Gtk.Label) hbox.get_first_child ().get_next_sibling ();
                if (label_widget.label == label) {
                    return button;
                }
            }
        }
        return null;
    }
}
