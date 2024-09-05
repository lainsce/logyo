public class Logyo.Application : He.Application {
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "quit", quit },
    };

    public const OptionEntry[] APP_OPTIONS = {
        { "silent", 's', 0, OptionArg.NONE, out silent,
        "Run the Application in background", null},
        { null }
    };

    public static bool silent;

    private Settings _settings;
    public Settings settings {
        get {
            return _settings;
        }
    }

    public Application () {
        Object (application_id: Config.APP_ID);
    }

    construct {
        flags |= ALLOW_REPLACEMENT;
        add_main_option_entries (APP_OPTIONS);
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

    public override void activate () {
        base.activate ();

        if (silent) {
            request_background.begin ();
            silent = false;
            return;
        }

        if (active_window == null) {
            var main_window = new MainWindow (this);
            add_window (main_window);
        }

        if (active_window != null) {
            this.active_window?.present ();
        }
    }

    public override void startup () {
        Gdk.RGBA accent_color = { 0 };
        accent_color.parse ("#30B0C7");
        default_accent_color = He.from_gdk_rgba ({accent_color.red * 255, accent_color.green * 255, accent_color.blue * 255});
        override_accent_color = true;
        override_dark_style = true;
        is_content = true;

        resource_base_path = Config.APP_PATH;

        base.startup ();

        add_action_entries (APP_ENTRIES, this);

        new MainWindow (this);
    }

    public async void request_background () {
        var portal = new Xdp.Portal ();

        Xdp.Parent? parent = active_window != null ? Xdp.parent_new_gtk (active_window) : null;

        var command = new GenericArray<weak string> ();
        command.add ("io.github.lainsce.Logyo");
        command.add ("--silent");

        try {
            if (!yield portal.request_background (
                parent,
                _("Logyo will run in the background to notify when to log an emotion or mood entry for the day."),
                (owned) command,
                Xdp.BackgroundFlags.AUTOSTART,
                null
            )) {
                release ();
            }
        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                debug ("Request for autostart and background permissions denied: %s", e.message);
                release ();
            } else {
                warning ("Failed to request autostart and background permissions: %s", e.message);
            }
        }
    }
}
