import fdapp/[glib]


type
  FreedesktopApp* = object


proc fdappIterate*() =
  ## Non-blocking iteration of fdapp's context.
  ##
  ## You must call this in your app's event loop.

  glibContext.iterate()
