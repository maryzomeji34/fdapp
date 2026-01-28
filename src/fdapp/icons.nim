import std/[os, sequtils, strformat]
import icontheme


type
  IconFormat* = enum
    xpm, png, svg


proc lookupIcon*(name: string, theme: IconTheme = getSystemIconTheme(),
                 icTypes: set[IconType] = {threshold, fixed, scalable},
                 size: uint = 0, scale: uint = 1,
                 formats: set[IconFormat] = {png, svg}): string =
  ## Gets path to an icon. If icon isn't found, empty string is returned.
  ##
  ## `name` must be just an icon name, without extension.
  ##
  ## If `size` is 0, the result is an icon of biggest size. Another `size` value sets a limit, but a smaller icon may be returned if there's no icon of requested size.

  if theme == nil:
    return ""

  let dirs = theme.directories.filter(proc (d: IconThemeSubdir): bool =
    if size > 0:
      return (d.icType in icTypes) and d.size <= size and d.scale <= scale
    else:
      return (d.icType in icTypes) and d.scale <= scale)

  for root in theme.paths:
    for dir in dirs:
      for format in formats:
        let path = fmt"{root}/{dir.path}/{name}.{format}"
        if fileExists(path):
          return path

  if theme.inherits.len > 0:
    for inhTheme in theme.inherits:
      let inhIcon = lookupIcon(name, inhTheme, icTypes, size, scale, formats)
      if inhIcon.len > 0: return inhIcon

  return ""
