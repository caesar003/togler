import Gio from "gi://Gio";

const TOG_DBUS_IFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.Togler">
    <method name="ToggleByWmClass">
      <arg type="s" name="wmclass" direction="in"/>
      <arg type="b" name="success" direction="out"/>
    </method>
  </interface>
</node>`;

export default class ToglerExtension {
  enable() {
    this._dbus = Gio.DBusExportedObject.wrapJSObject(TOG_DBUS_IFACE, this);
    this._dbus.export(Gio.DBus.session, "/org/gnome/Shell/Extensions/Togler");
    console.log("Togler extension enabled - D-Bus object exported");
  }

  disable() {
    if (this._dbus) {
      this._dbus.flush();
      this._dbus.unexport();
      this._dbus = null;
    }
    console.log("Togler extension disabled");
  }

  /* extension.js — inside your class */
  ToggleByWmClass(wmclass) {
    try {
      const actors = global.get_window_actors();
      const windows = actors.map((a) => a.get_meta_window()).filter(Boolean);

      // Some windows return an array or string; normalize if needed
      const matches = windows.filter((w) => {
        try {
          return w.get_wm_class && w.get_wm_class() === wmclass;
        } catch (e) {
          return false;
        }
      });

      // No matching window found — return false so caller can launch the app
      if (!matches.length) {
        return false;
      }

      const now = global.get_current_time();
      const focused = global.display.focus_window;

      // If focused and belongs to matches, minimize it
      if (focused && matches.includes(focused)) {
        focused.minimize();
        return true;
      }

      // Otherwise activate the first match
      const target = matches[0];
      target.get_workspace()?.activate(now);
      target.activate(now);
      return true;
    } catch (err) {
      // Log error and return false to indicate we didn't toggle
      console.error("Togler: error in ToggleByWmClass", err);
      return false;
    }
  }
}

