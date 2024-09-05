[GtkTemplate (ui = "/io/github/lainsce/Logyo/mainwindow.ui")]
public class Logyo.MainWindow : He.ApplicationWindow {
    // Define color constants
    private const string COLOR_VERY_UNPLEASANT = "#5856D6";
    private const string COLOR_UNPLEASANT = "#AF52DE";
    private const string COLOR_SLIGHTLY_UNPLEASANT = "#007AFF";
    private const string COLOR_NEUTRAL = "#30B0C7";
    private const string COLOR_SLIGHTLY_PLEASANT = "#309821";
    private const string COLOR_PLEASANT = "#A89400";
    private const string COLOR_VERY_PLEASANT = "#FF9500";

    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "about", action_about },
    };

    [GtkChild]
    private unowned Gtk.MenuButton menu_button;
    [GtkChild]
    private unowned He.OverlayButton add_button;
    [GtkChild]
    private unowned He.EmptyPage empty_page;
    [GtkChild]
    private unowned Gtk.ListBox feelings_list;
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
    private unowned He.TextField description_entry;

    [GtkChild]
    private unowned He.Button next_button_m;
    [GtkChild]
    private unowned He.TextField motivation_entry;

    private He.Application app { get; set; }

    private List<LogWidget> logs = new List<LogWidget>();
    private List<LogWidget> logs2 = new List<LogWidget>();

    private CalendarView calendar_view;
    private MoodGridView graph_view;

    public MainWindow (He.Application application) {
        Object (
            application: application,
            icon_name: Config.APP_ID,
            title: _("Logyo")
        );

        this.app = application;
    }

    construct {
        schedule_notifications ();
        close_request.connect (() => {
            ((Application)application).request_background.begin (() => destroy ());

            return Gdk.EVENT_STOP;
        });

        var loaded_logs = Logyo.FileUtil.load_logs("logs.json");
        foreach (var log_widget in loaded_logs) {
            add_log_to_layout(log_widget);
        }

        calendar_view = new CalendarView (logs);
        calendar.child = calendar_view;

        // Initialize the current month and year
        var now = new DateTime.now_local();
        var current_month = now.get_month();
        var current_year = now.get_year();

        var month_year_label = new He.ViewTitle () {
            label = "%s/%d".printf(current_month < 10 ? "0" + current_month.to_string() : current_month.to_string(), current_year)
        };
        month_year_label.add_css_class("numeric");

        var prev_button = new He.Button ("go-previous", "") {
            is_disclosure = true
        };
        var next_button = new He.Button ("go-next", "") {
            is_disclosure = true
        };

        prev_button.clicked.connect(() => {
            calendar_view.change_month(-1, month_year_label);
        });

        next_button.clicked.connect(() => {
            calendar_view.change_month(1, month_year_label);
        });
        calendar_appbar.append (prev_button);
        calendar_appbar.append (next_button);

        calendar_appbar.viewtitle_widget = month_year_label;

        if (feelings_list.get_first_child() != null) {
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

        add_button.clicked.connect (on_add_clicked);

        sheet.notify["show-sheet"].connect (() => {
            if (sheet.show_sheet == false) {
                sheet.back_button.set_visible (false);
                stack.set_visible_child_name ("timed");
                sheet.remove_css_class ("logyo-feeling");
                sheet.remove_css_class ("logyo-feeling-flat");
                update_color (COLOR_NEUTRAL);
                sheet.title = null;
                navrail.visible = true;
                emo_image.icon_name = "neutral-symbolic";
            }
        });

        if (stack.get_visible_child_name () == "timed") {
            sheet.back_button.set_visible (false);
        }
        sheet.back_button.clicked.connect (() => {
            if (stack.get_visible_child_name () == "feeling") {
                stack.set_visible_child_name ("timed");
                sheet.back_button.set_visible (false);
                sheet.remove_css_class ("logyo-feeling");
                update_color (COLOR_NEUTRAL);
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
                sheet.back_button.set_visible (false);
                sheet.remove_css_class ("logyo-feeling");
                sheet.remove_css_class ("logyo-feeling-flat");
                update_color (COLOR_NEUTRAL);
                sheet.title = null;
                emo_image.icon_name = "neutral-symbolic";
            }
        });

        // Time
        next_button_t.clicked.connect (() => {
            if (stack.get_visible_child_name () == "timed") {
                stack.set_visible_child_name ("feeling");
                sheet.back_button.set_visible (true);
                sheet.add_css_class ("logyo-feeling");
                update_color (COLOR_NEUTRAL);
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

        Gtk.Adjustment adj = new Gtk.Adjustment(3.0, 0.0, 6.0, 1.0, 0.0, 0.0);
        emo_slider.scale.set_digits(0);
        emo_slider.scale.set_round_digits(0);
        emo_slider.scale.set_adjustment (adj);

        emo_slider.scale.value_changed.connect(() => {
            on_slider_value_changed(emo_slider.scale, emo_label);
        });

        // Description
        next_button_d.clicked.connect (() => {
            if (stack.get_visible_child_name () == "description") {
                stack.set_visible_child_name ("motivation");
            }
        });;

        // Motivation
        next_button_m.clicked.connect (() => {
            var datetime = new GLib.DateTime.now_local ();

            if (stack.get_visible_child_name () == "motivation") {
                LogStruct log_struct = {
                    all_day_cb.active ? datetime.format ("%d/%m") : time_picker.time.format ("%H:%M @ %d/%m"),
                    emo_label.get_label (),
                    emo_image.get_icon_name (),
                    description_entry.get_internal_entry ().text,
                    motivation_entry.get_internal_entry ().text
                };
                var log_widget = new LogWidget (log_struct);
                add_log_to_layout(log_widget);
                Logyo.FileUtil.save_logs(logs, "logs.json");
                sheet.show_sheet = false;
                stack.set_visible_child_name ("timed");
                sheet.remove_css_class ("logyo-feeling");
                sheet.remove_css_class ("logyo-feeling-flat");
                update_color (COLOR_NEUTRAL);
                sheet.title = null;
                emo_image.icon_name = "neutral-symbolic";
                description_entry.get_internal_entry ().text = "";
                motivation_entry.get_internal_entry ().text = "";
                if (main_stack.visible_child_name == "empty") {
                    main_stack.visible_child_name = "list";
                }
                if (all_day_cb.active) {
                    calendar_view.update_calendar (current_month, current_year);
                } else {
                }
            }
        });
    }

    private void schedule_notifications() {
        var now = new DateTime.now_local();

        // Set midday notification
        var midday = new DateTime.local(now.get_year(), now.get_month(), now.get_day_of_month(), 12, 0, 0);
        if (now.compare(midday) > 0) {
            midday = midday.add_days(1);
        }

        // Set evening notification
        var evening = new DateTime.local(now.get_year(), now.get_month(), now.get_day_of_month(), 18, 0, 0);
        if (now.compare(evening) > 0) {
            evening = evening.add_days(1);
        }

        schedule_notification(_("Midday Check-in"), _("How are you feeling today?"), midday);
        schedule_notification(_("Evening Reflection"), _("Take a moment to reflect on your day."), evening);
    }

    private void schedule_notification(string title, string body, DateTime time) {
        var notification = new Notification(title);
        notification.set_body(body);
        notification.set_priority(NotificationPriority.NORMAL);

        uint seconds_until_notification = (uint)(time.difference(new DateTime.now_local()) / TimeSpan.SECOND);

        GLib.Timeout.add_seconds(seconds_until_notification, () => {
            app.send_notification(null, notification);
            schedule_next_notification(title, body, time.add_days(1));
            return false; // Do not repeat
        });
    }

    private void schedule_next_notification(string title, string body, DateTime next_time) {
        // Schedule the next notification for tomorrow
        GLib.Timeout.add_seconds((uint)(next_time.difference(new DateTime.now_local()) / TimeSpan.SECOND), () => {
            var notification = new Notification(title);
            notification.set_body(body);
            app.send_notification(null, notification);
            schedule_next_notification(title, body, next_time.add_days(1));
            return false;
        });
    }

    private void add_log_to_layout(LogWidget log_widget) {
        log_widget.log_deleted.connect(() => { on_log_deleted(log_widget); });
        feelings_list.append (log_widget);
        logs.append(log_widget);
        logs2.append(log_widget);
        graph_view.redraw ();
    }

    private void on_add_clicked () {
        sheet.show_sheet = true;
        navrail.visible = false;
    }

    private void on_slider_value_changed(Gtk.Scale slider, Gtk.Label label) {
        int value = (int) slider.get_value();
        string[] levels = {
            _("Very Unpleasant"),
            _("Unpleasant"),
            _("Slightly Unpleasant"),
            _("Neutral"),
            _("Slightly Pleasant"),
            _("Pleasant"),
            _("Very Pleasant")
        };

        // Update the label text
        label.set_text(levels[value]);

        switch (value) {
            case 0:
            // Very Unpleasant
                update_color (COLOR_VERY_UNPLEASANT);
                emo_image.icon_name = "very-unpleasant";
                break;
            case 1:
            // Unpleasant
                update_color (COLOR_UNPLEASANT);
                emo_image.icon_name = "unpleasant";
                break;
            case 2:
            // Slightly Unpleasant
                update_color (COLOR_SLIGHTLY_UNPLEASANT);
                emo_image.icon_name = "slightly-unpleasant";
                break;
            default:
            case 3:
            // Neutral
                update_color (COLOR_NEUTRAL);
                emo_image.icon_name = "neutral";
                break;
            case 4:
            // Slightly Pleasant
                update_color (COLOR_SLIGHTLY_PLEASANT);
                emo_image.icon_name = "slightly-pleasant";
                break;
            case 5:
            // Pleasant
                update_color (COLOR_PLEASANT);
                emo_image.icon_name = "pleasant";
                break;
            case 6:
            // Very Pleasant
                update_color (COLOR_VERY_PLEASANT);
                emo_image.icon_name = "very-pleasant";
                break;
        }
    }

    private void update_color(string clr) {
        Gdk.RGBA accent_color = { 0 };
        accent_color.parse (clr);
        app.default_accent_color = He.from_gdk_rgba ({accent_color.red * 255, accent_color.green * 255, accent_color.blue * 255});
    }

    private void on_log_deleted(LogWidget log) {
        var dialog = new He.Dialog(
            true,
            this,
            _("Remove Entry?"),
            "",
            _("Permanently deleting this entry will remove it completely."),
            "dialog-error-symbolic",
            new He.Button("", _("Remove Entry")) {
                css_classes = { "meson-red" }
            },
            null
        );

        dialog.primary_button.clicked.connect(() => {
            logs.remove(log);
            Logyo.FileUtil.save_logs(logs, "logs.json");
            feelings_list.remove (log);

            if (feelings_list.get_first_child() != null) {
                main_stack.visible_child_name = "list";
            } else {
                main_stack.visible_child_name = "empty";
            }

            var now = new DateTime.now_local();
            var current_month = now.get_month();
            var current_year = now.get_year();
            calendar_view.update_calendar (current_month, current_year);
            graph_view.redraw ();
            dialog.close();
        });

        dialog.cancel_button.clicked.connect(() => {
            dialog.close();
        });

        dialog.present();
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
}