public class Logyo.Application : He.Application {
    public static Application app;
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "quit", quit },
    };

    public static bool background;
    private Xdp.Portal? portal = null;
    public MainWindow window;

    private const OptionEntry[] OPTIONS = {
        { "background", 'b', 0, OptionArg.NONE, out background, "Launch and run in background.", null },
        { null }
    };

    public Application () {
        Object (
            application_id: Config.APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );

        app = this;
    }

    construct {
        add_main_option_entries (OPTIONS);

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

        var context = new OptionContext (_("Logyo"));
        context.add_main_entries (OPTIONS, "io.github.lainsce.Logyo");

        try {
            context.parse (ref args);
        } catch (Error e) {
            warning (e.message);
        }

        var app = new Logyo.Application ();
        return app.run (args);
    }

    protected override void activate () {
        base.activate ();

        if (background) {
            background = false;
            hold ();

            ask_for_background.begin ((obj, res) => {
                if (!ask_for_background.end (res)) {
                    release ();
                }
            });
        }

        if (get_windows () != null) {
            get_windows ().data.present (); // present window if app is already running
            return;
        }

        window = new MainWindow (this);
        window.show ();
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

    public async bool ask_for_background () {
        const string[] DAEMON_COMMAND = { "io.github.lainsce.Logyo", "--background" };
        if (portal == null) {
            portal = new Xdp.Portal ();
        }

        string reason = _(
            "Logyo will run when its window is closed so that it can send reminder notifications."
        );
        var command = new GenericArray<unowned string> (2);
        foreach (unowned var arg in DAEMON_COMMAND) {
            command.add (arg);
        }

        var window = Xdp.parent_new_gtk (active_window);

        try {
            return yield portal.request_background (window, reason, command, AUTOSTART, null);
        } catch (Error e) {
            warning ("Error during portal request: %s", e.message);
            return e is IOError.FAILED;
        }
    }
}
