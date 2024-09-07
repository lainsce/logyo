[GtkTemplate (ui = "/io/github/lainsce/Logyo/preferenceswindow.ui")]
public class Logyo.PreferencesWindow : He.SettingsWindow {
    [GtkChild]
    private unowned Gtk.Switch midday_switch;
    [GtkChild]
    private unowned Gtk.Switch evening_switch;
    [GtkChild]
    private unowned He.TimePicker midday_time_picker;

    public PreferencesWindow (MainWindow win) {
        Object (parent: win);
        Settings settings = new Settings ("io.github.lainsce.Logyo");

        settings.bind ("midday-notification", midday_switch, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("evening-notification", evening_switch, "active", SettingsBindFlags.DEFAULT);

        string midday_time = settings.get_string ("midday-time") ?? "12:00";
        string[] time_parts = midday_time.split(":");

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

        midday_time_picker.time = time;

        midday_time_picker.time_changed.connect (() => {
            settings.set_string ("midday-time", "%02d:%02d".printf (midday_time_picker.time.get_hour (), midday_time_picker.time.get_minute ()));
        });
    }
}