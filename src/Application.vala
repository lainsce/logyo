public class Logyo.Application : He.Application {
    public static Application app;
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "quit", quit },
    };

    private const string BACKGROUND = "background";
    public static bool background;

    private List<MainWindow> windows;
    public unowned MainWindow main_window {
        get { return (windows.length () > 0) ? windows.data : null; }
    }

    private const OptionEntry[] OPTIONS = {
        { BACKGROUND, 'b', 0, OptionArg.NONE, out background, "Launch and run in background.", null },
        { null }
    };

    public Application () {
        Object (
            application_id: Config.APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );

        app = this;
        windows = new List<MainWindow> ();

        var action = new GLib.SimpleAction ("launch-in-bg", GLib.VariantType.STRING);
        action.activate.connect ((param) => { open_in_bg (param.get_string ()); });
        add_action (action);
    }

    private void open_in_bg (string name) {
        activate ();

        main_window.present ();
    }

    private const string PORTAL_BUS_NAME = "org.freedesktop.portal.Desktop";
    private const string PORTAL_OBJECT_PATH = "/org/freedesktop/portal/desktop";
    private const string PORTAL_INTERFACE = "org.freedesktop.portal.Background";

    private DBusConnection? connection = null;

    construct {
        add_main_option_entries (OPTIONS);
        try {
            connection = Bus.get_sync (BusType.SESSION);
        } catch (Error e) {
            error ("Failed to connect to session bus: %s", e.message);
        }
        var settings = new Settings ("io.github.lainsce.Logyo");
        if (settings.get_boolean ("notifications-enabled")) {
            schedule_notifications ();
        }
    }

    public static int main (string[] args) {
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.textdomain (Config.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");

        Environment.set_prgname (Config.APP_ID);
        Environment.set_application_name (_("Logyo"));

        var app = new Logyo.Application ();
        return app.run (args);
    }

    protected override void activate () {
        base.activate ();

        if (main_window != null)
            return;

        if (background) {
            request_background.begin ();
            background = false;
            return;
        }

        add_new_window ();
    }

    public MainWindow add_new_window () {
        var window = new MainWindow (this);

        windows.append (window);
        window.present ();

        notify_property ("main-window");

        return window;
    }

    public bool remove_this_window (MainWindow window) {
        if (windows.length () == 1)
            return quit_app ();

        var initial_windows_count = windows.length ();

        window.hide ();
        windows.remove (window);
        base.remove_window (window);

        notify_property ("main-window");

        return initial_windows_count != windows.length ();
    }
    public bool quit_app () {
        foreach (var window in windows)
            window.hide ();
        // Ensure windows are hidden before returning from this function
        var display = Gdk.Display.get_default ();
        display.flush ();

        if (background)
            return true;

        Idle.add (() => {
            quit ();

            return false;
        });

        return true;
    }

    public override void startup () {
        Gdk.RGBA accent_color = { 0 };
        accent_color.parse ("#30B0C7");
        default_accent_color = He.from_gdk_rgba (
            {
                accent_color.red * 255,
                accent_color.green * 255,
                accent_color.blue * 255
            }
        );
        override_accent_color = true;
        is_content = true;

        resource_base_path = Config.APP_PATH;

        base.startup ();

        add_action_entries (APP_ENTRIES, this);
    }

    private void schedule_notifications () {
        var settings = new Settings ("io.github.lainsce.Logyo");
        var now = new DateTime.now_local ();

        if (settings.get_boolean ("during-notification")) {
            var during_time = settings.get_string ("during-time");
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
            var during = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), hours, minutes, 0);
            if (now.compare (during) > 0) {
                during = during.add_days (1);
            }
            schedule_notification (_("During Your Day"), _("How are you feeling today?"), during);
        }
        if (settings.get_boolean ("end-notification")) {
            var end = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 18, 0, 0);
            if (now.compare (end) > 0) {
                end = end.add_days (1);
            }
            schedule_notification (_("End of Day"), _("Take a moment to reflect on your day."), end);
        }
    }

    private void schedule_notification (string title, string body, DateTime time) {
        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_priority (NotificationPriority.NORMAL);

        uint seconds_until_notification = (uint) (time.difference (new DateTime.now_local ()) / TimeSpan.SECOND);

        GLib.Timeout.add_seconds (seconds_until_notification, () => {
            base.send_notification (null, notification);
            return false; // Do not repeat
        });
    }

    public async void request_background () {
        try {
            var portal = new Xdp.Portal.initable_new ();
            var window = active_window;
            var parent = Xdp.parent_new_gtk (window);
            var reason = _("Logyo wants to run in background");
            var cancellable = null;
            yield portal.request_background (parent, reason, new GLib.GenericArray<weak string> (), NONE, cancellable);
        } catch (GLib.Error error) {
            warning ("Failed to request to run in background: %s", error.message);
            background = false;
        }
    }
}
