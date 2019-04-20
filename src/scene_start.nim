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
  LineCount = 5
  ChangeBgOn = 2
  TextSpeed = SpeechSpeed * 10
  Delay = 1.5
  TextPos = (32.0, 32.0)


type
  StartScene = ref object of Scene
    bg*: Entity
    fadeTween*: Tween[Entity, float]
    text*: Typewriter
    count*: int
    delay*: float


proc initStartScene*(scene: StartScene) =
  initScene scene
  # BG
  scene.bg = newEntity()
  scene.bg.layer = LayerBG
  scene.bg.graphic = gfxData["scene_start1"]
  scene.add scene.bg
  # Text
  scene.text = newTypewriter(newTextGraphic(normalFont), TextSpeed)
  TextGraphic(scene.text.graphic).color = SpeechColor
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


proc free*(scene: StartScene) =
  discard


method show*(scene: StartScene) =
  scene.bg.graphic = gfxData["scene_start1"]
  scene.text.clear true
  scene.count = 0
  scene.delay = Delay / 2
  scene.fadeTween.play()


proc newStartScene*(): StartScene =
  new result, free
  initStartScene result


proc eventStartScene*(scene: StartScene, event: Event) =
  scene.eventScene event
  if scene.count >= LineCount:
    if (event.kind == MouseButtonDown) or
       (event.kind == KeyDown):
      game.scene = roomScene


method event*(scene: StartScene, event: Event) =
  scene.eventStartScene event


proc updateStartScene(scene: StartScene, elapsed: float) =
  scene.updateScene elapsed
  scene.fadeTween.update elapsed
  if not scene.fadeTween.playing:
    if scene.delay > 0:
      scene.delay -= elapsed
    else:
      if scene.text.queueLen > 0:
        scene.text.updateTypewriter elapsed
      elif scene.count < LineCount:
        if scene.count == ChangeBgOn:
          scene.bg.graphic = gfxData["scene_start2"]
        for line in lang("intro", "say" & $scene.count).splitLines:
          scene.text.add line
        scene.delay = Delay
        inc scene.count


method update*(scene: StartScene, elapsed: float) =
  scene.updateStartScene elapsed

