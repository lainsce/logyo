namespace Logyo {
    public class Portal {
        private static string BUS_NAME = "org.freedesktop.portal.Desktop";
        private static string OBJECT_PATH = "/org/freedesktop/portal/desktop";

        private DBusConnection? _bus = null;
        private string _parent = "";

        public Portal (string? parent = null) {
            _parent = parent ?? "";
        }

        public async void request_background_async (string? reason) {
            _bus = _bus ?? yield get_connection_async ();
            if (_bus != null) try {
                var options = make_options_builder ();
                if (reason != null) {
                    options.add ("{sv}", "reason", new Variant.string ((!)reason));
                }
                options.add ("{sv}", "autostart", new Variant.boolean (false));
                options.add ("{sv}", "dbus-activatable", new Variant.boolean (false));
                var param = new Variant ("(sa{sv})", _parent, options);
                yield ((!)_bus).call_with_unix_fd_list (
                            BUS_NAME,
                            OBJECT_PATH,
                            "org.freedesktop.portal.Background",
                            "RequestBackground",
                            param,
                            null,
                            DBusCallFlags.NONE,
                            -1);
            } catch (Error e) {
                print ("Bus.call error: %s\n", e.message);
            }
        }

        private VariantBuilder make_options_builder () {
            var token = "portal" + Random.next_int ().to_string ();
            var options = new VariantBuilder (VariantType.VARDICT);
            options.add ("{sv}", "handle_token", new Variant.string (token));
            return options;
        }

        private static async DBusConnection? get_connection_async () {
            try {
                return yield Bus.get (BusType.SESSION);
            } catch (Error e) {
                print ("Bus.get error: %s\n", e.message);
            }
            return null;
        }
    }
}