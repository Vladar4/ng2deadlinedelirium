import
  strutils,
  nimgame2 / [
    assets,
    entity,
    nimgame,
    scene,
    textgraphic,
    texturegraphic,
    tween,
    types,
    typewriter,
  ],
  data


const
  LineCount = 2
  TextSpeed = SpeechSpeed * 10
  Delay = 1.0
  TextPos = (192.0, 16.0)


type
  EndScene = ref object of Scene
    bg*: Entity
    fadeTween*: Tween[Entity, float]
    text*: Typewriter
    count*: int
    delay*: float


proc initEndScene*(scene: EndScene) =
  initScene scene
  # BG
  scene.bg = newEntity()
  scene.bg.layer = LayerBG
  scene.bg.graphic = gfxData["scene_finish2"]
  scene.add scene.bg
  # Text
  scene.text = newTypewriter(newTextGraphic(normalFont), TextSpeed)
  TextGraphic(scene.text.graphic).color = ColorWhite
  scene.text.layer = LayerGUI
  scene.text.pos = TextPos
  scene.add scene.text
  # Tween
  scene.fadeTween = newTween[Entity, float](
    scene.bg,
    proc(t: Entity): float = TextureGraphic(t.graphic).alphaMod.float,
    proc(t: Entity, val: float) = TextureGraphic(t.graphic).alphaMod = (255*val).uint8)
  scene.fadeTween.procedure = linear
  scene.fadeTween.setup(0, 1, 2.0, 0)


proc free*(scene: EndScene) =
  discard


method show*(scene: EndScene) =
  scene.text.clear true
  scene.count = 0
  scene.delay = Delay / 2
  scene.fadeTween.play()


proc newEndScene*(): EndScene =
  new result, free
  initEndScene result


proc eventEndScene*(scene: EndScene, event: Event) =
  scene.eventScene event
  if scene.count >= LineCount:
    if (event.kind == MouseButtonDown) or
       (event.kind == KeyDown):
      game.scene = titleScene


method event*(scene: EndScene, event: Event) =
  scene.eventEndScene event


proc updateEndScene(scene: EndScene, elapsed: float) =
  scene.updateScene elapsed
  scene.fadeTween.update elapsed
  if not scene.fadeTween.playing:
    if scene.delay > 0:
      scene.delay -= elapsed
    else:
      if scene.text.queueLen > 0:
        scene.text.updateTypewriter elapsed
      elif scene.count < LineCount:
        for line in lang("the_end", "say" & $scene.count).splitLines:
          scene.text.add line
        scene.delay = Delay
        inc scene.count


method update*(scene: EndScene, elapsed: float) =
  scene.updateEndScene elapsed

