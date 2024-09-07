public class Logyo.ColorConstants {
    public enum MoodValue {
        VERY_UNPLEASANT = 1,
        UNPLEASANT,
        SLIGHTLY_UNPLEASANT,
        NEUTRAL,
        SLIGHTLY_PLEASANT,
        PLEASANT,
        VERY_PLEASANT
    }

    private const string[] MOOD_COLORS = {
        "",
        "#5856D6", // VERY_UNPLEASANT
        "#AF52DE", // UNPLEASANT
        "#007AFF", // SLIGHTLY_UNPLEASANT
        "#40A0B9", // NEUTRAL
        "#309821", // SLIGHTLY_PLEASANT
        "#707200", // PLEASANT
        "#FF9500"  // VERY_PLEASANT
    };

    public static string get_color_for_mood(MoodValue value) {
        return MOOD_COLORS[value];
    }

    public static MoodValue get_mood_value(string feeling) {
        switch (feeling) {
            case "very-unpleasant": return MoodValue.VERY_UNPLEASANT;
            case "unpleasant": return MoodValue.UNPLEASANT;
            case "slightly-unpleasant": return MoodValue.SLIGHTLY_UNPLEASANT;
            case "neutral": return MoodValue.NEUTRAL;
            case "slightly-pleasant": return MoodValue.SLIGHTLY_PLEASANT;
            case "pleasant": return MoodValue.PLEASANT;
            case "very-pleasant": return MoodValue.VERY_PLEASANT;
            default: return MoodValue.NEUTRAL;
        }
    }

    public static void update_color(He.Application app, string color_string) {
        Gdk.RGBA accent_color = { 0 };
        accent_color.parse(color_string);
        app.default_accent_color = He.from_gdk_rgba({
            accent_color.red * 255,
            accent_color.green * 255,
            accent_color.blue * 255
        });
    }

    public static double[] convert_hex_to_rgb(string hexcode) {
        string hex = hexcode.replace("#", "");
        return {
            (double)uint.parse(hex.substring(0, 2), 16) / 255,
            (double)uint.parse(hex.substring(2, 2), 16) / 255,
            (double)uint.parse(hex.substring(4, 2), 16) / 255
        };
    }
}