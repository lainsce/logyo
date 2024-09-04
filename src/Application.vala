public class Logyo.Application : He.Application {
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "quit", quit },
    };

    private Portal _portal = new Portal ();
    private Settings _settings;
    public Settings settings {
        get {
            return _settings;
        }
    }

    public Application () {
        Object (application_id: Config.APP_ID);
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

        if (active_window is MainWindow) {
            active_window.present ();
        } else {
            open ({}, "");
        }
    }

    public override void open (File[] files, string hint) {
        var window = (active_window as MainWindow) ?? new MainWindow (this);
        window.present ();
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

    public void request_background () {
        _portal.request_background_async.begin (_("Logyo needs to stay open to notify you."),
            (obj, res) => _portal.request_background_async.end (res));
    }
}
