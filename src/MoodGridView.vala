public class Logyo.MoodGridView : Gtk.Box {
    private unowned List<LogWidget> logs;
    private Gtk.DrawingArea drawing_area;
    private uint graph_width = 365;
    private uint graph_height = 365;
    private bool show_all_daily_moods;

    private Gtk.ToggleButton week_button;
    private Gtk.ToggleButton two_week_button;
    private Gtk.ToggleButton month_button;
    private He.Switch show_all_daily_moods_switch;

    public MoodGridView (List<LogWidget> logs) {
        this.logs = logs;

        this.orientation = Gtk.Orientation.VERTICAL;
        this.spacing = 18;
        this.margin_bottom = 18;
        this.margin_start = 18;

        var button_box = create_button_box ();
        this.append (button_box);

        drawing_area = new Gtk.DrawingArea ();
        drawing_area.set_content_width ((int)graph_width);
        drawing_area.set_content_height ((int)graph_height);
        drawing_area.add_css_class ("mood-graph");

        drawing_area.set_draw_func ((area, cr, width, height) => {
            draw_graph (cr, width, height, 7);
        });

        this.append (drawing_area);

        show_all_daily_moods_switch = new He.Switch ();
        if (show_all_daily_moods_switch.iswitch.active) {
            show_all_daily_moods = true;
            redraw ();
        } else {
            show_all_daily_moods = false;
            redraw ();
        }
        show_all_daily_moods_switch.iswitch.notify["active"].connect (() => {
            if (show_all_daily_moods_switch.iswitch.active) {
                show_all_daily_moods = true;
                redraw ();
            } else {
                show_all_daily_moods = false;
                redraw ();
            }
        });

        var label = new Gtk.Label ("Show All Daily Moods") {
            valign = Gtk.Align.CENTER
        };
        label.add_css_class ("caption");
        label.add_css_class ("dim-label");

        var mood_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        mood_box.append (show_all_daily_moods_switch);
        mood_box.append (label);

        this.append (mood_box);
    }

    private Gtk.Box create_button_box () {
        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        button_box.add_css_class ("segmented-button");

        // TRANSLATORS: First letter of the word Week.
        week_button = new Gtk.ToggleButton.with_label (_("W"));

        // TRANSLATORS: First letter of the word Week and saying it's 2 Weeks.
        two_week_button = new Gtk.ToggleButton.with_label (_("2W"));
        two_week_button.group = week_button;

        // TRANSLATORS: First letter of the word Month.
        month_button = new Gtk.ToggleButton.with_label (_("M"));
        month_button.group = week_button;

        week_button.set_active (true);

        button_box.append (week_button);
        button_box.append (two_week_button);
        button_box.append (month_button);

        week_button.clicked.connect (() => set_graph_period (7));
        two_week_button.clicked.connect (() => set_graph_period (14));
        month_button.clicked.connect (() => set_graph_period (30));

        return button_box;
    }

    private void set_graph_period (int days) {
        redraw_with_days (days);
    }

    public void redraw () {
        if (logs.length () >= 7) {
            set_graph_period (7);
        } else if (logs.length () >= 21) {
            set_graph_period (21);
        } else if (logs.length () >= 30) {
            set_graph_period (30);
        }
    }

    private void redraw_with_days (int days) {
        drawing_area.set_draw_func ((area, cr, width, height) => {
            draw_graph (cr, width, height, days);
        });
        drawing_area.queue_draw ();
    }

    private void draw_graph (Cairo.Context cr, double width, double height, int days) {
        if (logs == null) {
            return; // Nothing to draw
        }

        if (logs.length () == 0) {
            print ("Subset logs is empty.\n");
            return;
        }

        // Calculate graph dimensions and centering offsets
        double graph_width = width - 36;  // Adjust as needed
        double graph_height = height - 36;  // Adjust as needed
        double offset_x = (width - graph_width) / 2;
        double offset_y = (height - graph_height) / 2;

        cr.save ();
        cr.translate (offset_x, offset_y);

        cr.select_font_face ("Geist", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
        cr.set_font_size (12.0);
        cr.set_antialias (Cairo.Antialias.GRAY);

        double step_x = graph_width / days;

        // Draw faint grid lines and helpful text
        int[] y_values = { 0, 3, 6 };
        string[] labels = { _("Very Unpleasant"), "", _("Very Pleasant") };

        foreach (int y_value in y_values) {
            double y = graph_height - ((graph_height / 6.0) * y_value);
            cr.set_source_rgba (0.5, 0.5, 0.5, 0.12);
            cr.move_to (0, y);
            cr.line_to (graph_width, y);
            cr.stroke ();
        }

        int yi = 0;
        foreach (int y_value in y_values) {
            double y = graph_height - ((graph_height / 6.0) * y_value);
            cr.set_source_rgba (0.5, 0.5, 0.5, 0.66);

            double text_x = 3.0;  // Distance from the left edge
            double text_y = y + 3.0;

            cr.move_to (text_x, text_y);
            cr.show_text (labels[yi]);
            yi++;
        }

        for (int i = 0; i <= days; i++) {
            double x = i * step_x;
            cr.set_source_rgba (0.5, 0.5, 0.5, 0.12);
            cr.move_to (x, 0);
            cr.line_to (x, graph_height);
            cr.stroke ();
        }

        // Draw the points
        double radius = 6.0;
        int index = 0;
        foreach (LogWidget log in logs) {
            if (show_all_daily_moods) {
                // First pass: Draw backgrounds
                for (int day = 1; day <= days; day++) {
                    double x = (day - 1) * step_x;
                    double top_y = double.MAX;
                    double bottom_y = 0;
                    string top_mood = "";
                    string bottom_mood = "";

                    foreach (LogWidget l in logs) {
                        if (get_day_index (l) == day) {
                            double y = graph_height - ((get_mood_value (l.feeling_icon) - 1) / 6.0 * graph_height);
                            if (y < top_y) {
                                top_y = y;
                                top_mood = l.feeling_icon;
                            }
                            if (y > bottom_y) {
                                bottom_y = y;
                                bottom_mood = l.feeling_icon;
                            }
                        }
                    }

                    if (top_mood != "" && bottom_mood != "") {
                        // Draw rounded rectangle background
                        double padding = 2.0;
                        double rwidth = 16.0;
                        double rheight = (bottom_y - top_y + radius * 2) + 4.0;
                        double rx = x - 8.0;
                        double ry = (top_y - radius) - padding;

                        var pattern = new Cairo.Pattern.linear (rx, ry, rx, ry + rheight);
                        var top_color = get_color_for_mood (top_mood);
                        var bottom_color = get_color_for_mood (bottom_mood);
                        pattern.add_color_stop_rgba (0, top_color[0], top_color[1], top_color[2], 0.05);
                        pattern.add_color_stop_rgba (1, bottom_color[0], bottom_color[1], bottom_color[2], 0.05);
                        pattern.set_filter (Cairo.Filter.GAUSSIAN);

                        cr.save ();
                        cr.new_sub_path ();
                        cr.arc (rx + rwidth - radius, ry + radius, 8.0, -Math.PI_2, 0);
                        cr.arc (rx + rwidth - radius, ry + rheight - radius, 8.0, 0, Math.PI_2);
                        cr.arc (rx + radius, ry + rheight - radius, 8.0, Math.PI_2, Math.PI);
                        cr.arc (rx + radius, ry + radius, 8.0, Math.PI, -Math.PI_2);
                        cr.close_path ();
                        cr.set_source (pattern);
                        cr.fill ();
                        cr.restore ();
                    }
                }

                // Second pass: Draw points
                if (log == null || log.feeling_icon == null) {
                    continue;
                }

                int day_index = get_day_index (log);
                double x = (day_index - 1) * step_x;
                double y = graph_height - ((get_mood_value (log.feeling_icon) - 1) / 6.0 * graph_height);

                // Count occurrences of the same mood on the same day
                int mood_count = 0;
                foreach (LogWidget log2 in logs) {
                    if (get_day_index (log2) == day_index && log.feeling_icon == log2.feeling_icon) {
                        mood_count++;
                    }
                }

                double radius2 = radius + (mood_count == 1 ? 0 : mood_count);

                cr.arc (x, y, radius2, 0, 2 * Math.PI);
                cr.set_source_rgb (
                    get_color_for_mood (log.feeling_icon)[0],
                    get_color_for_mood (log.feeling_icon)[1],
                    get_color_for_mood (log.feeling_icon)[2]
                );
                cr.fill ();
            } else {
                if (log == null || log.feeling_icon == null || log.time.contains ("@")) {
                    continue;
                }

                double x = index * step_x;
                double y = graph_height - ((get_mood_value (log.feeling_icon) - 1) / 6.0 * graph_height);
                cr.arc (x, y, radius, 0, 2 * Math.PI);
                cr.set_source_rgb (
                    get_color_for_mood (log.feeling_icon)[0],
                    get_color_for_mood (log.feeling_icon)[1],
                    get_color_for_mood (log.feeling_icon)[2]
                );
                cr.fill ();
                index++;
            }
        }
    }

    private int get_day_index (LogWidget log) {
        string date_part;

        // Check if the format includes time
        if (log.time.contains ("@")) {
            // Split at "@" and use the second part which contains the date
            date_part = log.time.split ("@")[1].strip ();
        } else {
            // If there's no "@", the entire log.time is the date part
            date_part = log.time;
        }

        // Split the date into day and month components
        string[] date_components = date_part.split ("/");

        if (date_components.length != 2) {
            warning ("Unexpected date format: %s", log.time);
            return -1;
        }

        int day = int.parse (date_components[0]);
        return day;
    }

    private int get_mood_value (string feeling) {
        switch (feeling) {
            case "very-unpleasant": return 1;
            case "unpleasant": return 2;
            case "slightly-unpleasant": return 3;
            case "neutral": return 4;
            case "slightly-pleasant": return 5;
            case "pleasant": return 6;
            case "very-pleasant": return 7;
            default: return 4;
        }
    }

    private double[] get_color_for_mood (string feeling) {
        switch (get_mood_value (feeling)) {
            case 1: return convert_hex_to_rgb (ColorConstants.COLOR_VERY_UNPLEASANT);
            case 2: return convert_hex_to_rgb (ColorConstants.COLOR_UNPLEASANT);
            case 3: return convert_hex_to_rgb (ColorConstants.COLOR_SLIGHTLY_UNPLEASANT);
            case 4: return convert_hex_to_rgb (ColorConstants.COLOR_NEUTRAL);
            case 5: return convert_hex_to_rgb (ColorConstants.COLOR_SLIGHTLY_PLEASANT);
            case 6: return convert_hex_to_rgb (ColorConstants.COLOR_PLEASANT);
            case 7: return convert_hex_to_rgb (ColorConstants.COLOR_VERY_PLEASANT);
            default: return convert_hex_to_rgb (ColorConstants.COLOR_NEUTRAL);   // fallback to NEUTRAL
        }
    }

    private double[] convert_hex_to_rgb (string hexcode) {
        print ("HEX: %s\n", hexcode);

        // 000000
        // 012345
        // R: 0 to 1
        // G: 2 to 3
        // B: 4 to 5
        string hex = hexcode.replace("#", "");
        int length = 2;
        uint red = uint.parse (hex.substring(0, length), 16);
        uint green = uint.parse (hex.substring(2, length), 16);
        uint blue = uint.parse (hex.substring(4, length), 16);

        double[] rgb = {
            (double)red / 255,
            (double)green / 255,
            (double)blue / 255
        };

        print ("RGB: %0.4f, %0.4f, %0.4f\n", rgb[0], rgb[1], rgb[2]);

        return rgb;
    }
}
