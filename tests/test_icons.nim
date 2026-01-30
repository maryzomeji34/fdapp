import unittest
import std/[asyncdispatch, osproc, strformat, strutils]
import fdapp/[glib, icons]


test "icons lookup":
  let systemTheme = getSystemIconTheme()
  assert systemTheme != nil
  check systemTheme.id == execProcess("gsettings get org.gnome.desktop.interface icon-theme").strip(chars = {'\''} + WHITESPACE)
  echo fmt"Your system icon theme is: {systemTheme.id} ({systemTheme.name})"
  echo "Installed icon themes: ", getIconThemesList().join(", ")

  let adw = findIconTheme("Adwaita") # Adwaita is installed by default on many distros
  check adw != nil
  check adw.id == "Adwaita"
  check adw.name == "Adwaita"
  check adw.comment == "The Only One"
  check adw.inherits.contains findIconTheme("hicolor")

  check lookupIcon("package-x-generic-symbolic", theme = adw).path == "/usr/share/icons/Adwaita/symbolic/mimetypes/package-x-generic-symbolic.svg"
  check lookupIcon("package-x-generic-symbolic", theme = findIconTheme("hicolor")) == nil
  check lookupIcon("blah-blah") == nil
  check lookupIcon("folder", theme = adw, size = 512).size == 128 # Adwaita doesn't have 512px icons


test "watch system icon theme":
  let theme = getSystemIconTheme()
  var themeChanged = false

  onIconThemeChanged:
    if getSystemIconTheme() != theme:
      themeChanged = true

  let cb: Callback = proc(fd: AsyncFD): bool =
    discard execProcess(fmt"gsettings set org.gnome.desktop.interface icon-theme nonexistanttheme")
    return true

  addTimer(1000, true, cb)

  while not themeChanged:
    glibContext.iterate() # iterating context for Glib signal to work
    try: poll() except ValueError: break

  check getSystemIconTheme() != theme
  discard execProcess(fmt"gsettings set org.gnome.desktop.interface icon-theme {theme.id}")
  check getSystemIconTheme() == theme
