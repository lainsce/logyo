/*
* Copyright (c) 2023 Fyra Labs
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/
namespace Logyo {
    [SingleInstance]
    public class Settings : Object {
        public GLib.Settings settings = new GLib.Settings ("io.github.lainsce.Logyo");
        public bool background { get; set; }

        construct {
            settings.bind ("background", this, "background", DEFAULT);
        }

        public Action create_action (string key) {
            return settings.create_action (key);
        }
    }
    [GtkTemplate (ui = "/io/github/lainsce/Logyo/prefs.ui")]
    public class Preferences : He.SettingsWindow {
        [GtkChild]
        unowned He.Switch b;

        public Preferences (MainWindow win) {
            Object (parent: win);
            var settings = new Settings ();

            settings.settings.bind ("background", b.iswitch, "active", DEFAULT);
        }
    }
}