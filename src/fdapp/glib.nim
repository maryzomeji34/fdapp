import std/[dynlib, macros]

##[
  This module provides partial bindings for GLib.

  It is used internally for most of functionality of fdapp.
  You only need to import this module to call `iterate` manually when not importing the main fdapp module (see `test_icons.nim` for example).
]##


type
  # --- GObject ---
  GObject* = pointer
  GObjectUnrefFunc = proc(obj: GObject) {.stdcall, gcsafe.}
  GObjectSignalConnectDataFunc = proc(obj: GObject, signal: cstring, handler: proc() {.cdecl.}, data, destroyData: pointer, connectFlags: cint): culong {.stdcall, gcsafe.}

  # --- GMainContext ---
  GMainContext* = GObject
  GMainContextNewFunc = proc(): GMainContext {.stdcall, gcsafe.}
  GMainContextThreadDefaultFunc = proc(context: GMainContext) {.stdcall, gcsafe.}
  GMainContextIterationFunc = proc(context: GMainContext, mayBlock: cint): cint {.stdcall, gcsafe.}

  # --- GSettings ---
  GSettings* = GObject
  GSettingsNewFunc = proc(schema: cstring): GObject {.stdcall, gcsafe.}
  GSettingsGetStringFunc = proc(settings: GObject, key: cstring): cstring {.stdcall, gcsafe.}


let gioHandle = loadLibPattern("libgio-2.0.so(|.0)")
assert gioHandle != nil

let
  # --- GObject ---
  unref* = cast[GObjectUnrefFunc](gioHandle.symAddr("g_object_unref"))
  connect* = cast[GObjectSignalConnectDataFunc](gioHandle.symAddr("g_signal_connect_data"))

  # --- GMainContext ---
  newGMainContext = cast[GMainContextNewFunc](gioHandle.symAddr("g_main_context_new"))
  pushThreadDefault = cast[GMainContextThreadDefaultFunc](gioHandle.symAddr("g_main_context_push_thread_default"))
  popThreadDefault = cast[GMainContextThreadDefaultFunc](gioHandle.symAddr("g_main_context_pop_thread_default"))
  iteration = cast[GMainContextIterationFunc](gioHandle.symAddr("g_main_context_iteration"))
  glibContext* = newGMainContext()
    ## Separate `GMainContext` to be used by the library.
    ## If your application uses GLib, you should not worry that fdapp will mess with your app's context, because it uses its own.

  # --- GSettings ---
  newGSettings* = cast[GSettingsNewFunc](gioHandle.symAddr("g_settings_new"))
  gsettingsGetString* = cast[GSettingsGetStringFunc](gioHandle.symAddr("g_settings_get_string"))


proc withGlibContextImpl(actions: NimNode): NimNode =
  result = newStmtList()
  result.add newCall(bindSym"pushThreadDefault", bindSym"glibContext")
  result.add actions
  result.add newCall(bindSym"popThreadDefault", bindSym"glibContext")


macro withGlibContext*(actions: untyped) =
  ## Sets fdapp's Glib context to be the current one, then executes `actions` and switches back current context.

  withGlibContextImpl(actions)


proc iterate*(context: GMainContext) =
  ## Non-blocking iteration of `context`

  discard context.iteration(0)
