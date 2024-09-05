public class Logyo.CalendarView : Gtk.Box {
    // Constants
    private const int DAYS_IN_WEEK = 7;
    private const int MAX_DAYS_IN_MONTH = 31;
    private const int GRID_MARGIN = 18;        // Reduced margin
    private const int MONTHS_IN_YEAR = 12;
    private const int INITIAL_MONTH = 1;
    private const int FINAL_MONTH = 12;
    private const int TOTAL_WIDTH = 324;
    private const int DAY_WIDTH = (TOTAL_WIDTH - (2 * GRID_MARGIN)) / DAYS_IN_WEEK;
    private const int ICON_SIZE = 48;          // Reduced icon size

    // Private fields
    private int current_month;
    private int current_year;
    private unowned List<LogWidget> logs;

    private Gtk.Grid calendar_grid;

    public CalendarView (List<LogWidget> logs) {
        this.logs = logs;
        orientation = Gtk.Orientation.VERTICAL;
        width_request = TOTAL_WIDTH;

        // Initialize the current month and year
        var now = new GLib.DateTime.now_local ();
        current_month = now.get_month ();
        current_year = now.get_year ();

        // Create the calendar grid
        calendar_grid = new Gtk.Grid () {
            column_homogeneous = true,
            margin_end = GRID_MARGIN,
            margin_start = GRID_MARGIN,
        };

        // Add weekday labels
        add_weekday_labels ();

        var sw = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            halign = Gtk.Align.CENTER,
            margin_top = GRID_MARGIN / 2,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        sw.set_child (calendar_grid);

        append (sw);
        hexpand = true;
        vexpand = true;

        // Update the calendar with the provided logs
        update_calendar (current_month, current_year);
    }

    private void add_weekday_labels () {
        string[] weekdays = { _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat"), _("Sun") };
        for (int i = 0; i < DAYS_IN_WEEK; i++) {
            var label = new Gtk.Label (weekdays[i]) {
                hexpand = true,
                vexpand = true,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                width_request = DAY_WIDTH,
                margin_bottom = 12
            };
            label.add_css_class ("caption");
            calendar_grid.attach (label, i, 0);
        }
    }

    public void change_month (int offset, He.ViewTitle label) {
        current_month += offset;

        if (current_month > FINAL_MONTH) {
            current_month = INITIAL_MONTH;
            current_year++;
        } else if (current_month < INITIAL_MONTH) {
            current_month = FINAL_MONTH;
            current_year--;
        }

        update_calendar (current_month, current_year);
        label.label = "%s/%d".printf (
            current_month < 10 ?
            "0" + current_month.to_string () :
            current_month.to_string (), current_year
        );
    }

    public void update_calendar (int month, int year) {
        // Clear existing calendar grid, keeping the weekday labels
        for (int i = 1; i < 7; i++) {
            for (int j = 0; j < DAYS_IN_WEEK; j++) {
                var child = calendar_grid.get_child_at (j, i);
                if (child != null) {
                    calendar_grid.remove (child);
                }
            }
        }

        var processed_dates = new Gee.HashSet<string> ();
        var logged_days = new Gee.HashMap<int, LogWidget> ();

        // Process logs and store them in the logged_days map
        foreach (LogWidget log in logs) {
            if (log.time.contains ("@")) continue;
            if (processed_dates.contains (log.time)) continue;

            processed_dates.add (log.time);

            var date_parts = log.time.split ("/");
            int day = int.parse (date_parts[0]);
            int entry_month = int.parse (date_parts[1]);

            if (entry_month == month) {
                logged_days[day] = log;
            }
        }

        // Get the number of days in the current month
        var date = new GLib.DateTime.local (year, month, 1, 0, 0, 0);
        var next_month = date.add_months (1);
        var days_in_month = next_month.add_days (-1).get_day_of_month ();

        // Determine the first day of the month (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
        int first_day_of_month = date.get_day_of_week () - 1;
        if (first_day_of_month < 0) {
            first_day_of_month = 6;
        }

        // Create and add day widgets for all days in the month
        for (int day = 1; day <= days_in_month; day++) {
            int grid_row = ((day + first_day_of_month - 1) / DAYS_IN_WEEK) + 1;
            int grid_column = (day + first_day_of_month - 1) % DAYS_IN_WEEK;

            var day_widget = new Gtk.Box (Gtk.Orientation.VERTICAL, 4){
                width_request = DAY_WIDTH,
                height_request = DAY_WIDTH,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                hexpand = true,
                vexpand = true
            };
            var day_label = new Gtk.Label ("%d".printf(day)){
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                hexpand = true,
                vexpand = true
            };
            day_label.add_css_class ("caption");
            day_label.add_css_class ("numeric");
            day_widget.append (day_label);

            if (logged_days.has_key (day)) {
                var log = logged_days[day];
                var icon = new Gtk.Image.from_icon_name (log.feeling_icon) {
                    pixel_size = ICON_SIZE,
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                    hexpand = true,
                    vexpand = true
                };
                day_widget.append (icon);
                day_widget.tooltip_text = _("Daily Mood logged on:") + " " + log.time;
                day_widget.add_css_class ("day-logged");
            } else {
                var icon = new Gtk.Image.from_icon_name ("no-entry-symbolic") {
                    pixel_size = ICON_SIZE,
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                    hexpand = true,
                    vexpand = true
                };
                icon.add_css_class ("dim-label");
                day_widget.append (icon);
                day_widget.add_css_class ("day-empty");
            }

            day_widget.add_css_class ("day");
            calendar_grid.attach (day_widget, grid_column, grid_row);
        }
    }
}