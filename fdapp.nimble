# Package

version       = "0.1.0"
author        = "Candle Waster"
description   = "Freedesktop and other standard utilities library for Nim apps"
license       = "Unlicense"
srcDir        = "src"


# Dependencies

requires "nim >= 2.2.0"


task updateDocs, "Update docs":
  rmDir "src/htmldocs"
  exec "nim doc --project --index:only src/fdapp.nim"
  exec "nim doc --project src/fdapp.nim"
