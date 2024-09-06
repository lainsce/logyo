public class Logyo.ColorConstants {
    public const string COLOR_VERY_UNPLEASANT = "#5856D6";
    public const string COLOR_UNPLEASANT = "#AF52DE";
    public const string COLOR_SLIGHTLY_UNPLEASANT = "#007AFF";
    public const string COLOR_NEUTRAL = "#40A0B9";
    public const string COLOR_SLIGHTLY_PLEASANT = "#309821";
    public const string COLOR_PLEASANT = "#A89400";
    public const string COLOR_VERY_PLEASANT = "#FF9500";

    public static string get_color_for_mood(int value) {
        switch (value) {
            case 0: return COLOR_VERY_UNPLEASANT;
            case 1: return COLOR_UNPLEASANT;
            case 2: return COLOR_SLIGHTLY_UNPLEASANT;
            case 3: return COLOR_NEUTRAL;
            case 4: return COLOR_SLIGHTLY_PLEASANT;
            case 5: return COLOR_PLEASANT;
            case 6: return COLOR_VERY_PLEASANT;
            default: return COLOR_NEUTRAL;
        }
    }

    public static int get_mood_value(string feeling) {
        switch (feeling) {
            case "very-unpleasant": return 1;
            case "unpleasant": return 2;
            case "slightly-unpleasant": return 3;
            case "neutral": return 4;
            case "slightly-pleasant": return 5;
            case "pleasant": return 6;
            case "very-pleasant": return 7;
            default: return 4;
        }
    }

    public static void update_color(He.Application app, string color_string) {
        Gdk.RGBA accent_color = { 0 };
        accent_color.parse (color_string);
        app.default_accent_color = He.from_gdk_rgba (
            {
                accent_color.red * 255,
                accent_color.green * 255,
                accent_color.blue * 255
            }
        );
    }

    public static double[] convert_hex_to_rgb(string hexcode) {
        string hex = hexcode.replace("#", "");
        int length = 2;
        uint red = uint.parse (hex.substring(0, length), 16);
        uint green = uint.parse (hex.substring(2, length), 16);
        uint blue = uint.parse (hex.substring(4, length), 16);

        return {
            (double)red / 255,
            (double)green / 255,
            (double)blue / 255
        };
    }
}