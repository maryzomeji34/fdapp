# fdapp
 
A library for Nim that provides utilities to create ***F***ree***d***esktop-compliant ***app***s.

Each module can be used separately:

* **fdapp** — make your application run a DBus service under a well-known name, implementing `org.freedesktop.Application` and `com.canonical.Unity.LauncherEntry` interfaces
* **fdapp/icons** — lookup icons and get some info about installed icon themes

TODO:

* XDG user directories
* XDG portals

The only dependency of the library is libgio (at runtime, no devel files needed to compile).

## Documentation

For now please clone the repo and run `nimble updateDocs`, this will generate documentation locally (I try to write good doc comments). The documentation will be uploaded later after revision.
