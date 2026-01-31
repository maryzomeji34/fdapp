import std/[dynlib, macros]

##[
  This module provides partial bindings for GLib.

  It is used internally for most of functionality of fdapp.
  You only need to import this module to call `iterate` manually when not importing the main fdapp module (see `test_icons.nim` for example).
]##


{.pragma: gio, cdecl, dynlib: "libgio-2.0.so(|.0)".}


type
  GError* = ptr object
    domain*: cuint
    code*: cint
    message*: cstring

  GDBusNodeInfo* = ptr object
    refCount: cint
    path: cstring
    interfaces*: ptr UncheckedArray[pointer]
    nodes: ptr UncheckedArray[pointer]
    annotations: ptr UncheckedArray[pointer]

  GObject* = ptr object
  GMainContext* = ptr object
  GVariant* = ptr object
  GVariantType* = ptr object
  GVariantIter* = ptr object

  GDBusConnection* = distinct GObject
  GDBusMethodInvocation* = distinct GObject
  GDBusCallback* = proc(connection: GDBusConnection, name: cstring, data: pointer) {.cdecl.}

  GDBusInterfaceMethodCallFunc* = proc(connection: GDBusConnection, sender, objectPath, interfaceName, methodName: cstring, parameters: GVariant, invocation: GDBusMethodInvocation, data: pointer) {.cdecl.}
  GDBusInterfaceGetPropertyFunc* = proc(connection: GDBusConnection, sender, objectPath, interfaceName, propertyName: cstring, error: ptr GError, data: pointer): pointer {.cdecl.}
  GDBusInterfaceSetPropertyFunc* = proc(connection: GDBusConnection, sender, objectPath, interfaceName, propertyName: cstring, value: pointer, error: ptr GError, data: pointer): cint {.cdecl.}

  GDBusInterfaceVTable* = object
    methodCall*: GDBusInterfaceMethodCallFunc
    getProperty*: GDBusInterfaceGetPropertyFunc
    setProperty*: GDBusInterfaceSetPropertyFunc

  GSettings* = distinct GObject


let gioHandle = loadLibPattern("libgio-2.0.so(|.0)")
assert gioHandle != nil

# TODO: cleanup
# --- GVariant ---
proc get*(value: GVariant, format: cstring) {.gio, importc:"g_variant_get", varargs.}
proc getString*(value: GVariant, length: ptr csize_t): cstring {.gio, importc:"g_variant_get_string".}
proc getChildValue*(value: GVariant, index: csize_t): GVariant {.gio, importc:"g_variant_get_child_value".}
proc lookupValue*(dictionary: GVariant, key: cstring, expectedType: GVariantType): GVariant {.gio, importc:"g_variant_lookup_value".}
proc unref*(value: GVariant) {.gio, importc:"g_variant_unref".}
proc newGVariantType*(format: cstring): GVariantType {.gio, importc:"g_variant_type_new".}
proc init*(iter: GVariantIter, variant: GVariant): csize_t {.gio, importc:"g_variant_iter_init".}
proc loop*(iter: GVariantIter, format: cstring): cint {.gio, importc:"g_variant_iter_loop", varargs.}

# --- GObject ---
proc unref*(value: GObject) {.gio, importc:"g_object_unref".}
proc connect*(obj: GObject, signal: cstring, handler: proc() {.cdecl.}, data, destroyData: pointer, connectFlags: cint): culong {.gio, importc:"g_signal_connect_data".}

# --- GMainContext ---
proc newGMainContext(): GMainContext {.gio, importc:"g_main_context_new".}
proc pushThreadDefault(context: GMainContext) {.gio, importc:"g_main_context_push_thread_default".}
proc popThreadDefault(context: GMainContext) {.gio, importc:"g_main_context_pop_thread_default".}
proc iteration(context: GMainContext, mayBlock: cint): cint {.gio, importc:"g_main_context_iteration".}

# --- GDBus ---
proc newGDBusNodeInfoForXml*(xml: cstring, error: ptr GError): GDBusNodeInfo {.gio, importc:"g_dbus_node_info_new_for_xml".}
proc gbusOwnName*(busType: cint, name: cstring, flags: cint, busAcquiredHandler, nameAcquiredHandler, nameLostHandler: GDBusCallback, data, dataFreeFunc: pointer): cuint {.gio, importc:"g_bus_own_name".}
proc registerObject*(connection: GDBusConnection, objectPath: cstring, interfaceInfo: pointer, vtable: ptr GDBusInterfaceVTable, data, dataFreeFunc: pointer, error: ptr GError): cuint {.gio, importc:"g_dbus_connection_register_object".}
proc returnValue*(invocation: GDBusMethodInvocation, parameters: GVariant) {.gio, importc:"g_dbus_method_invocation_return_value".}

# --- GSettings ---
proc newGSettings*(schema: cstring): GSettings {.gio, importc:"g_settings_new".}
proc getString*(settings: GSettings, key: cstring): cstring {.gio, importc:"g_settings_get_string".}


let glibContext* = newGMainContext()
    ## Separate `GMainContext` to be used by the library.
    ## If your application uses GLib, you should not worry that fdapp will mess with your app's context, because it uses its own.


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
