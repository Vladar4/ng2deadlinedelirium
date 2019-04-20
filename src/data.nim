import
  parsecfg, streams,
  nimgame2 / [
    plugin/tar,
    assets,
    scene,
    audio,
    nimgame,
    texturegraphic,
    truetypefont,
    types,
    utils,
  ],
  mpointer


const
  GameWidth*  = 640
  GameHeight* = 360
  GameTitle*  = "Deadline Delirium [LGJ2019]"
  DefaultFont*     = "data/fnt/FSEX300.ttf"
  DefaultLanguage* = "data/lang/english.lang"

  LayerBG* = 0
  LayerFG* = 10
  LayerObjects* = 20
  LayerActors* = 30
  LayerObjectsAlt* = 60
  LayerHero* = 70
  LayerToolbar* = 90
  LayerGUI* = 100
  LayerUseItem* = 110

  ActorSpeed* = 0.01

  HeroSpriteSize* = (192, 192)
  ClerkSpriteSize* = (128, 128)

  Framerate* = 1/12

  HintSpeed* = 0.025
  HintColor* = ColorLimeGreen

  SpeechSpeed* = 0.005
  SpeechColor* = ColorChartreuse
  SpeechColorClerk* = ColorCyan
  SpeechTimerPerChar* = 0.02


var
  normalFont*, bigFont*: TrueTypeFont
  language*: Config
  mousePointer*: MousePointer
  gfxData*: Assets[TextureGraphic]
  sfxData*: Assets[Sound]
  musData*: Assets[Music]
  gameIconSurface*: Surface
  introScene*, titleScene*, startScene*, finishScene*, endScene*: Scene
  roomScene*, streetScene*, storeScene*: Scene
  inventory*: seq[string]


proc load(font: var TrueTypeFont, path: string, size: int, t: TarFile) =
  if t.contents.len > 0: # data.tar.gz is empty or nonexistent
    if not font.load(t.read path, size):
      write stdout, "ERROR: Can't load font from 'data.tar.gz': ", path, "\n"
  else:
    if not font.load(path, size):
      write stdout, "ERROR: Can't load font from 'data' directory: ", path, "\n"


proc loadFonts*() =
  var t: TarFile
  discard t.openz "data.tar.gz"

  normalFont = newTrueTypeFont()
  normalFont.load(DefaultFont, 16, t)

  bigFont = newTrueTypeFont()
  bigFont.load(DefaultFont, 64, t)

  close t


proc lang*(section, value: string): string =
  language.getSectionValue(section, value)


iterator loadData*(): int =
  var
    t: TarFile
    count: int
  discard t.openz "data.tar.gz"

  gfxData = new Assets[TextureGraphic]

  if t.contents.len > 0:
    let stream = t.stream DefaultLanguage
    language = loadConfig(stream, DefaultLanguage)
    inc count
    yield count
    close stream

    for c in gfxData.loadIter(t.contents "data/gfx",
        proc (file: string): TextureGraphic = newTextureGraphic t.read(file)):
      inc count
      yield count

  else:
    language = loadConfig(DefaultLanguage)
    inc count
    yield count

    for c in gfxData.loadIter("data/gfx",
        proc(file: string): TextureGraphic = newTextureGraphic file):
      inc count
      yield count


  # finally
  mousePointer = newMousePointer(gfxData["gui_pointer"])
  close t


proc freeData*() =
  normalFont.free()
  bigFont.free()
  for gfx in gfxData.values:
    gfx.free()


# MISC

proc toggleFullscreen*() =
  let fullscreen = game.fullscreen()
  if not game.setFullscreen(not fullscreen):
    write stdout, "ERROR: Can't change window mode to " &
      (if fullscreen: "fullscreen" else: "windowed") & "\n"

