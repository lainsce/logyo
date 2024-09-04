public class Logyo.Application : He.Application {
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "quit", quit },
    };

    public Application () {
        Object (application_id: Config.APP_ID);
    }

    public static int main (string[] args) {
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.textdomain (Config.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");

        var app = new Logyo.Application ();
        return app.run (args);
    }

    public override void activate () {
        this.active_window?.present ();
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
}
