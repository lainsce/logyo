[GtkTemplate (ui = "/io/github/lainsce/Logyo/preferenceswindow.ui")]
public class Logyo.PreferencesWindow : He.SettingsWindow {
    [GtkChild]
    private unowned Gtk.Switch during_switch;
    [GtkChild]
    private unowned Gtk.Switch end_switch;
    [GtkChild]
    private unowned He.TimePicker during_time_picker;

    public PreferencesWindow (MainWindow win) {
        Object (parent: win);
        Settings settings = new Settings ("io.github.lainsce.Logyo");

        settings.bind ("during-notification", during_switch, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("end-notification", end_switch, "active", SettingsBindFlags.DEFAULT);

        string during_time = settings.get_string ("during-time") ?? "12:00";
        string[] time_parts = during_time.split(":");

        int hours = 12;
        int minutes = 0;

        if (time_parts.length >= 2) {
            if (int.try_parse(time_parts[0], out hours) == false) {
                hours = 12;
            }
            if (int.try_parse(time_parts[1], out minutes) == false) {
                minutes = 0;
            }
        }
        var time = new DateTime.local(
            new DateTime.now_local().get_year(),
            new DateTime.now_local().get_month(),
            new DateTime.now_local().get_day_of_month(),
            hours,
            minutes,
            0
        );

        during_time_picker.time = time;

        during_time_picker.time_changed.connect (() => {
            settings.set_string ("during-time", "%02d:%02d".printf (during_time_picker.time.get_hour (), during_time_picker.time.get_minute ()));
        });
    }
}