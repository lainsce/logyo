[GtkTemplate (ui = "/io/github/lainsce/Logyo/mainwindow.ui")]
public class Logyo.MainWindow : He.ApplicationWindow {
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "about", action_about },
    };

    [GtkChild]
    private unowned Gtk.MenuButton menu_button;
    [GtkChild]
    private unowned He.Button export_button;
    [GtkChild]
    private unowned He.OverlayButton add_button;
    [GtkChild]
    private unowned He.EmptyPage empty_page;
    [GtkChild]
    private unowned Gtk.FlowBox feelings_list;
    [GtkChild]
    private unowned He.BottomSheet sheet;
    [GtkChild]
    private unowned Gtk.Stack main_stack;
    [GtkChild]
    private unowned Gtk.Stack stack;
    [GtkChild]
    private unowned He.Bin calendar;
    [GtkChild]
    private unowned He.AppBar calendar_appbar;
    [GtkChild]
    private unowned He.Bin graph;
    [GtkChild]
    private unowned He.NavigationRail navrail;
    [GtkChild]
    private unowned Gtk.ScrolledWindow scrolled_window;

    [GtkChild]
    private unowned He.Button next_button_t;
    [GtkChild]
    private unowned Gtk.CheckButton timed_cb;
    [GtkChild]
    private unowned Gtk.CheckButton all_day_cb;
    [GtkChild]
    private unowned He.TimePicker time_picker;

    [GtkChild]
    private unowned He.Button next_button_f;
    [GtkChild]
    private unowned Gtk.Label feeling_prompt_label;
    [GtkChild]
    private unowned Gtk.Image emo_image;
    [GtkChild]
    private unowned Gtk.Label emo_label;
    [GtkChild]
    private unowned He.Slider emo_slider;

    [GtkChild]
    private unowned He.Button next_button_d;
    [GtkChild]
    private unowned Gtk.Box description_box;

    [GtkChild]
    private unowned He.Button next_button_m;
    [GtkChild]
    private unowned Gtk.Label m_emo_desc;
    [GtkChild]
    private unowned Gtk.Box motivation_box;

    [GtkChild]
    private unowned Gtk.Box logged_box;
    [GtkChild]
    private unowned Gtk.Image logged_pic;

    [GtkChild]
    private unowned He.Button begin_button;

    [GtkChild]
    private unowned He.Button notifications_button;
    [GtkChild]
    private unowned He.Button skip_button;

    private static Settings settings;
    private bool is_first_run;
    private bool reminders_shown;

    private He.Application app { get; set; }

    private List<LogWidget> logs = new List<LogWidget> ();
    private List<LogWidget> logs2 = new List<LogWidget> ();
    private List<LogWidget> logs3 = new List<LogWidget> ();

    private CalendarView calendar_view;
    private MoodGridView graph_view;

    private ChipGroup description_group;
    private ChipGroup motivation_group;

    public MainWindow (He.Application application) {
        Object (
            application: application,
            icon_name: Config.APP_ID,
            title: _("Logyo")
        );

        this.app = application;
        is_first_run = settings.get_boolean ("first-run");
        reminders_shown = settings.get_boolean ("notifications-enabled");
    }

    static construct {
        settings = new Settings ("io.github.lainsce.Logyo");
    }

    construct {
        var loaded_logs = Logyo.FileUtil.load_logs ("logs.json");
        foreach (var log_widget in loaded_logs) {
            add_log_to_layout (log_widget);
            add_log_to_calendar_and_graph (log_widget);
        }

        calendar_view = new CalendarView (logs);
        calendar.child = calendar_view;

        // Initialize the current month and year
        var now = new DateTime.now_local ();
        var current_month = now.get_month ();
        var current_year = now.get_year ();

        var month_year_label = new He.ViewTitle () {
            label = "%s/%d".printf (
                current_month < 10 ?
                "0" + current_month.to_string () :
                current_month.to_string (), current_year
            )
        };
        month_year_label.add_css_class ("numeric");

        var prev_button = new He.Button ("go-previous", "") {
            is_disclosure = true
        };
        var next_button = new He.Button ("go-next", "") {
            is_disclosure = true
        };

        prev_button.clicked.connect (() => {
            calendar_view.change_month (-1, month_year_label);
        });

        next_button.clicked.connect (() => {
            calendar_view.change_month (1, month_year_label);
        });
        calendar_appbar.append (prev_button);
        calendar_appbar.append (next_button);

        calendar_appbar.viewtitle_widget = month_year_label;

        if (feelings_list.get_first_child () != null) {
            main_stack.visible_child_name = "list";
        } else {
            main_stack.visible_child_name = "empty";
        }

        add_action_entries (APP_ENTRIES, this);

        menu_button.get_popover ().has_arrow = false;
        empty_page.action_button.visible = false;
        navrail.remove_css_class ("sidebar-view");

        graph_view = new MoodGridView (logs2);
        graph.child = graph_view;

        export_button.clicked.connect (() => {
            show_export_dialog (logs3);
        });

        var scroll_controller = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.VERTICAL);
        scroll_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);

        scroll_controller.scroll.connect((dx, dy) => {
            var hadjustment = scrolled_window.get_hadjustment();
            hadjustment.value += dy * hadjustment.step_increment * 2; // Scroll horizontally using dy

            return true;
        });

        scrolled_window.add_controller(scroll_controller);

        description_group = new ChipGroup (FeelingConstants.descriptions);
        description_box.append (description_group);

        motivation_group = new ChipGroup (FeelingConstants.motivations);
        motivation_box.append (motivation_group);

        description_group.selection_changed.connect(() => {
            make_label (m_emo_desc, description_group.selected_values);
        });

        add_button.clicked.connect (on_add_clicked);

        sheet.notify["show-sheet"].connect (() => {
            if (sheet.show_sheet == false) {
                sheet.back_button.set_visible (false);
                stack.set_visible_child_name ("timed");
                sheet.remove_css_class ("logyo-feeling");
                sheet.remove_css_class ("logyo-feeling-flat");
                logged_pic.remove_css_class("blurry-image");
                logged_box.remove_css_class("label-overlay");
                update_color (ColorConstants.get_color_for_mood(3));
                sheet.title = null;
                navrail.visible = true;
                emo_image.icon_name = "neutral-symbolic";
            }
        });

        if (is_first_run) {
            stack.visible_child_name = "first-run";
            sheet.back_button.visible = false;
        }

        begin_button.clicked.connect (() => {
            stack.visible_child_name = "timed";
            sheet.back_button.visible = true;
        });

        notifications_button.clicked.connect (() => {
            settings.set_boolean ("notifications-enabled", true);
            log_feeling ();
        });

        skip_button.clicked.connect (() => {
            log_feeling ();
        });

        // Timed
        GLib.Timeout.add (60, () => {
            time_picker.time.add_minutes (1);
        });

        if (stack.get_visible_child_name () == "timed") {
            if (is_first_run) {
                sheet.back_button.set_visible (true);
            } else {
                sheet.back_button.set_visible (false);
            }
        }
        sheet.back_button.clicked.connect (() => {
            if (stack.get_visible_child_name () == "feeling") {
                stack.set_visible_child_name ("timed");
                sheet.back_button.set_visible (false);
                sheet.remove_css_class ("logyo-feeling");
                update_color (ColorConstants.get_color_for_mood(3));
                emo_slider.scale.set_value (3); // Neutral
                sheet.title = null;
                emo_image.icon_name = "neutral-symbolic";
            } else if (stack.get_visible_child_name () == "description") {
                stack.set_visible_child_name ("feeling");
                sheet.add_css_class ("logyo-feeling");
                sheet.remove_css_class ("logyo-feeling-flat");
            } else if (stack.get_visible_child_name () == "motivation") {
                stack.set_visible_child_name ("description");
            } else if (stack.get_visible_child_name () == "timed") {
                if (is_first_run) {
                    stack.set_visible_child_name ("first-run");
                    sheet.back_button.visible = false;
                } else {
                    sheet.show_sheet = false;
                    sheet.remove_css_class ("logyo-feeling");
                    sheet.remove_css_class ("logyo-feeling-flat");
                    update_color (ColorConstants.get_color_for_mood(3));
                    sheet.title = null;
                    emo_image.icon_name = "neutral-symbolic";
                }
            }
        });

        // Time
        next_button_t.clicked.connect (() => {
            if (stack.get_visible_child_name () == "timed") {
                if (is_first_run) {
                    is_first_run = false;
                    settings.set_boolean ("first-run", false);
                    sheet.back_button.set_visible (true);
                }
                stack.set_visible_child_name ("feeling");
                sheet.back_button.set_visible (true);
                sheet.add_css_class ("logyo-feeling");
                update_color (ColorConstants.get_color_for_mood(3));
                emo_slider.scale.set_value (3); // Neutral
                if (timed_cb.active == true) {
                    sheet.title = _("Emotion");
                    feeling_prompt_label.label = _("Choose how you're feeling right now");
                } else {
                    sheet.title = _("Mood");
                    feeling_prompt_label.label = _("Choose how you've felt overall today");
                }
            }
        });

        // Feeling
        next_button_f.clicked.connect (() => {
            if (stack.get_visible_child_name () == "feeling") {
                stack.set_visible_child_name ("description");
                sheet.add_css_class ("logyo-feeling-flat");
                sheet.remove_css_class ("logyo-feeling");
            }
        });

        Gtk.Adjustment adj = new Gtk.Adjustment (3.0, 0.0, 6.0, 1.0, 0.0, 0.0);
        emo_slider.scale.set_digits (0);
        emo_slider.scale.set_round_digits (0);
        emo_slider.scale.set_adjustment (adj);

        emo_slider.scale.value_changed.connect (() => {
            on_slider_value_changed (emo_slider.scale, emo_label);
        });

        // Description
        next_button_d.clicked.connect (() => {
            if (stack.get_visible_child_name () == "description") {
                stack.set_visible_child_name ("motivation");
            }
        });

        // Motivation
        next_button_m.clicked.connect (() => {
            if (stack.get_visible_child_name () == "motivation") {
                stack.set_visible_child_name ("logged");
                sheet.back_button.set_visible (false);
                sheet.title = null;
                sheet.remove_css_class ("logyo-feeling");
                sheet.remove_css_class ("logyo-feeling-flat");

                logged_pic.add_css_class("blurry-image");
                logged_box.add_css_class("label-overlay");

                Timeout.add_seconds (6, () => {
                    if (!reminders_shown || !settings.get_boolean ("notifications-enabled")) {
                        stack.set_visible_child_name ("reminders");
                        reminders_shown = true;
                    } else {
                        log_feeling ();
                    }
                    return false;
                });
            }
        });

        close_request.connect (() => on_close_request ());
    }

    private void make_label (Gtk.Label label, List<string> list) {
        string[] values_array = new string[list.length ()];
        int i = 0;
        foreach (var value in list) {
            values_array[i++] = value;
        }
        label.label = string.joinv(", ", values_array);
    }
    private string make_selection_string (List<string> list) {
        string[] values_array = new string[list.length ()];
        int i = 0;
        foreach (var value in list) {
            values_array[i++] = value;
        }
        return string.joinv(", ", values_array);
    }

    private void log_feeling () {
        var now = new GLib.DateTime.now_local ();
        var current_month = now.get_month ();
        var current_year = now.get_year ();

        LogStruct log_struct = {
            all_day_cb.active ? now.format ("%d/%m") : time_picker.time.format ("%H:%M @ %d/%m"),
            emo_label.get_label (),
            emo_image.get_icon_name (),
            m_emo_desc.label,
            make_selection_string (motivation_group.selected_values)
        };
        var log_widget = new LogWidget (log_struct);
        add_log_to_layout (log_widget);
        add_log_to_calendar_and_graph (log_widget);
        try {
            Logyo.FileUtil.save_logs (logs, "logs.json");
        } catch (Error e) {
            warning ("Failed to save logs: %s", e.message);
        }
        sheet.show_sheet = false;
        stack.set_visible_child_name ("timed");
        sheet.remove_css_class ("logyo-feeling-flat");
        logged_pic.remove_css_class("blurry-image");
        logged_box.remove_css_class("label-overlay");
        update_color (ColorConstants.get_color_for_mood(3));
        emo_image.icon_name = "neutral-symbolic";
        description_group.reset_selections ();
        motivation_group.reset_selections ();
        if (main_stack.visible_child_name == "empty") {
            main_stack.visible_child_name = "list";
        }
        if (all_day_cb.active) {
            calendar_view.update_calendar (current_month, current_year);
            graph_view.redraw ();
        } else {
            graph_view.redraw ();
        }
    }

    private bool on_close_request () {
        var res = Application.app.remove_this_window (this);
        return res;
    }

    private void show_export_dialog (List<LogWidget> elogs) {
        var dialog = new Gtk.FileChooserDialog (
            "Export Chart",
            this,
            Gtk.FileChooserAction.SAVE,
            "_Cancel", Gtk.ResponseType.CANCEL,
            "_Export", Gtk.ResponseType.ACCEPT
        );

        dialog.set_current_name ("mood_chart.html");

        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.ACCEPT) {
                string? filename = dialog.get_file ()?.get_path ();
                if (filename != null) {
                    generate_html_chart (filename, elogs);
                }
            }
            dialog.destroy ();
        });

        dialog.show ();
    }

    public void generate_html_chart (string output_file, List<LogWidget> plogs) {
        string html_template = """
        <!DOCTYPE html>
        <html lang='en'>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Mood Chart</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        </head>
        <body>
            <canvas id="moodChart" width="365" height="200"></canvas>
            <script>
                var ctx = document.getElementById('moodChart').getContext('2d');
                var moodChart = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: [%s],
                        datasets: [{
                            label: 'Mood Entry',
                            data: [%s],
                            borderColor: '#30B0C7',
                            borderWidth: 1,
                            pointBackgroundColor: [%s],
                            pointBorderColor: [%s],
                            fill: false,
                            tension: 0.25
                        }]
                    },
                    options: {
                        scales: {
                            x: {
                                title: {
                                    display: true,
                                    text: 'Date'
                                }
                            },
                            y: {
                                title: {
                                    display: true,
                                    text: 'Mood'
                                },
                                min: 1,
                                max: 7
                            }
                        }
                    }
                });
            </script>
        </body>
        </html>
        """;

        // Prepare data for the chart
        List<string> labels = new List<string> ();
        List<string> data = new List<string> ();
        List<string> point_colors = new List<string> ();

        foreach (var log in plogs) {
            labels.append ("\"%s\"".printf (log.time));
            data.append (map_feeling_to_number (log.feeling_icon).to_string ());
            point_colors.append ("\"%s\"".printf (get_color_for_feeling (log.feeling_icon)));
        }

        string label_str = join_labels (labels);
        string data_str = join_labels (data);
        string color_str = join_labels (point_colors);

        // Generate final HTML
        string html_content = html_template.printf (label_str, data_str, color_str, color_str);

        try {
            FileUtils.set_contents (output_file, html_content);
        } catch (Error e) {
            warning ("Failed to write HTML chart: %s", e.message);
        }
    }
    private string join_labels (List<string> labels) {
        var result = new StringBuilder ();
        for (int i = 0; i < labels.length (); i++) {
            result.append (labels.nth_data (i));
            if (i < labels.length () - 1) {
                result.append (",");
            }
        }
        return result.str;
    }

    private void add_log_to_layout (LogWidget log_widget) {
        log_widget.log_deleted.connect (() => { on_log_deleted (log_widget); });
        feelings_list.prepend (log_widget);
        logs.append (log_widget);
    }
    private void add_log_to_calendar_and_graph (LogWidget log_widget) {
        logs2.append (log_widget);
        logs3.append (log_widget);
        graph_view.redraw ();
    }

    private void on_add_clicked () {
        sheet.show_sheet = true;
        navrail.visible = false;
        if (is_first_run) {
            stack.set_visible_child_name ("first-run");
            sheet.back_button.visible = false;
        } else {
            stack.set_visible_child_name ("timed");
            sheet.back_button.visible = false;
        }
    }

    private void on_slider_value_changed (Gtk.Scale slider, Gtk.Label label) {
        int value = (int) slider.get_value ();
        label.set_text (get_mood_label(value));
        update_color (ColorConstants.get_color_for_mood(value));
        emo_image.icon_name = get_mood_icon(value);
    }

    private void update_color (string clr) {
        ColorConstants.update_color(app, clr);
    }

    private void on_log_deleted (LogWidget log) {
        var dialog = new He.Dialog (
            true,
            this,
            _("Remove Entry?"),
            "",
            _("Permanently deleting this entry will remove it completely."),
            "dialog-error-symbolic",
            new He.Button ("", _("Remove Entry")) {
                css_classes = { "meson-red" }
            },
            null
        );

        dialog.primary_button.clicked.connect (() => {
            logs.remove (log);
            try {
                Logyo.FileUtil.save_logs (logs, "logs.json");
            } catch (Error e) {
                warning ("Failed to save logs: %s", e.message);
            }
            feelings_list.remove (log);

            if (feelings_list.get_first_child () != null) {
                main_stack.visible_child_name = "list";
            } else {
                main_stack.visible_child_name = "empty";
            }

            var now = new DateTime.now_local ();
            var current_month = now.get_month ();
            var current_year = now.get_year ();
            calendar_view.update_calendar (current_month, current_year);
            graph_view.redraw ();
            dialog.close ();
        });

        dialog.cancel_button.clicked.connect (() => {
            dialog.close ();
        });

        dialog.present ();
    }

    private void action_about () {
        new He.AboutWindow (
            this,
            _("Logyo") + Config.NAME_SUFFIX,
            Config.APP_ID,
            Config.VERSION,
            Config.APP_ID,
            null,
            "https://github.com/lainsce/logyo/issues",
            "https://github.com/lainsce/logyo",
            null,
            { "Lains" },
            2024,
            He.AboutWindow.Licenses.GPLV3,
            He.Colors.MINT
        ).present ();
    }

    private int map_feeling_to_number (string feeling) {
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

    private string get_mood_icon(int value) {
        switch (value) {
            case 0: return "very-unpleasant";
            case 1: return "unpleasant";
            case 2: return "slightly-unpleasant";
            case 3: return "neutral";
            case 4: return "slightly-pleasant";
            case 5: return "pleasant";
            case 6: return "very-pleasant";
            default: return "neutral";
        }
    }

    private string get_mood_label(int value) {
        switch (value) {
            case 0: return _("Very Unpleasant");
            case 1: return _("Unpleasant");
            case 2: return _("Slightly Unpleasant");
            case 3: return _("Neutral");
            case 4: return _("Slightly Pleasant");
            case 5: return _("Pleasant");
            case 6: return _("Very Pleasant");
            default: return _("Neutral");
        }
    }

    private string get_color_for_feeling (string feeling) {
        return ColorConstants.get_color_for_mood(ColorConstants.get_mood_value(feeling));
    }
}
