public class Logyo.Application : He.Application {
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "quit", quit },
    };

    private const string BACKGROUND = "background";
    public static bool background;
    private bool first_activation = true;

    private const OptionEntry[] OPTIONS = {
        { BACKGROUND, 'b', 0, OptionArg.NONE, out background, "Launch and run in background.", null },
        { null }
    };

    public Application () {
        Object (
            application_id: Config.APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );
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
        if (first_activation) {
            hold ();
            first_activation = false;
        }

        if (background) {
            request_background.begin ();
            background = false;
            return;
        }

        if (get_windows () != null) {
            this.active_window?.present ();
        }

        new MainWindow (this);
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
        override_dark_style = true;
        is_content = true;

        resource_base_path = Config.APP_PATH;

        base.startup ();

        add_action_entries (APP_ENTRIES, this);

        schedule_notifications ();
    }

    private void schedule_notifications () {
        var now = new DateTime.now_local ();

        // Set midday notification
        var midday = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 12, 0, 0);
        if (now.compare (midday) > 0) {
            midday = midday.add_days (1);
        }

        // Set evening notification
        var evening = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 18, 0, 0);
        if (now.compare (evening) > 0) {
            evening = evening.add_days (1);
        }

        schedule_notification (_("Midday Check-in"), _("How are you feeling today?"), midday);
        schedule_notification (_("Evening Reflection"), _("Take a moment to reflect on your day."), evening);
    }

    private void schedule_notification (string title, string body, DateTime time) {
        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_priority (NotificationPriority.NORMAL);

        uint seconds_until_notification = (uint) (time.difference (new DateTime.now_local ()) / TimeSpan.SECOND);

        GLib.Timeout.add_seconds (seconds_until_notification, () => {
            base.send_notification (null, notification);
            schedule_next_notification (title, body, time.add_days (1));
            return false; // Do not repeat
        });
    }

    private void schedule_next_notification (string title, string body, DateTime next_time) {
        // Schedule the next notification for tomorrow
        GLib.Timeout.add_seconds ((uint) (next_time.difference (new DateTime.now_local ()) / TimeSpan.SECOND), () => {
            var notification = new Notification (title);
            notification.set_body (body);
            base.send_notification (null, notification);
            schedule_next_notification (title, body, next_time.add_days (1));
            return false;
        });
    }

    public async void request_background () {
        if (connection == null) {
            warning ("DBus connection not established");
            return;
        }

        var options = new VariantBuilder (new VariantType ("a{sv}"));
        options.add ("{sv}", "handle_token", new Variant.string ("logyo1"));
        options.add ("{sv}", "reason",
            new Variant.string ("Logyo needs to run in the background to send notifications"));
        options.add ("{sv}", "autostart", new Variant.boolean (false));
        options.add ("{sv}", "commandline", new Variant.strv ({"io.github.lainsce.Logyo", "--background"}));

        try {
            var result = yield connection.call (
                PORTAL_BUS_NAME,
                PORTAL_OBJECT_PATH,
                PORTAL_INTERFACE,
                "RequestBackground",
                new Variant ("(sa{sv})", "", options),
                new VariantType ("(o)"),
                DBusCallFlags.NONE,
                -1,
                null
            );

            string request_path;
            result.get ("(o)", out request_path);
            yield wait_for_response (request_path);
        } catch (Error e) {
            warning ("Error requesting background running: %s", e.message);
        }
    }

    private async void wait_for_response (string request_path) {
        uint signal_id = 0;
        signal_id = connection.signal_subscribe (
            PORTAL_BUS_NAME,
            "org.freedesktop.portal.Request",
            "Response",
            request_path,
            null,
            DBusSignalFlags.NONE,
            (conn, sender_name, object_path, interface_name, signal_name, parameters) => {
                uint32 response;
                Variant results;
                parameters.get ("(u@a{sv})", out response, out results);

                switch (response) {
                    case 0: // Success
                        warning ("Background permission granted");
                        break;
                    case 1: // User cancelled
                        warning ("User cancelled background permission request");
                        break;
                    case 2: // User dismissed
                        warning ("User dismissed background permission request");
                        break;
                    default:
                        warning ("Unknown response from background permission request: %u", response);
                        break;
                }

                wait_for_response.callback ();
            }
        );

        yield;
    }
}
