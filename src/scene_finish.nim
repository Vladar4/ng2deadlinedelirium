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
    utils,
  ],
  data


const
  RandomLines = 15
  LineCount = 2 + RandomLines
  TextSpeed = SpeechSpeed * 5
  Delay = 1.5
  TextPos = (128.0, 32.0)


type
  FinishScene = ref object of Scene
    bg*: Entity
    fadeTween*: Tween[Entity, float]
    text*: Typewriter
    textLines*: seq[string]
    count*: int
    delay*: float
    done*: bool


proc randomLine(): string =
  for c in 0..49:
    result.add rand(32..127).char


proc generateText(): seq[string] =
  for l in 0..<LineCount:
    if l < (LineCount - RandomLines):
      result.add lang("outro", "say" & $l)
    else:
      result.add randomLine()


proc initFinishScene*(scene: FinishScene) =
  initScene scene
  # BG
  scene.bg = newEntity()
  scene.bg.layer = LayerBG
  scene.bg.graphic = gfxData["scene_finish1"]
  scene.add scene.bg
  # Text
  scene.text = newTypewriter(newTextGraphic(normalFont), TextSpeed)
  TextGraphic(scene.text.graphic).color = SpeechColor
  scene.text.layer = LayerGUI
  scene.text.pos = TextPos
  scene.add scene.text
  scene.textLines = generateText()
  # Tween
  scene.fadeTween = newTween[Entity, float](
    scene.bg,
    proc(t: Entity): float = TextureGraphic(t.graphic).alphaMod.float,
    proc(t: Entity, val: float) = TextureGraphic(t.graphic).alphaMod = (255*val).uint8)
  scene.fadeTween.procedure = linear


proc free*(scene: FinishScene) =
  discard


method show*(scene: FinishScene) =
  scene.text.clear true
  scene.delay = Delay / 2
  scene.count = 0
  scene.done = false
  scene.fadeTween.setup(0, 1, 2.0, 0)
  scene.fadeTween.play()


proc newFinishScene*(): FinishScene =
  new result, free
  initFinishScene result


proc eventFinishScene*(scene: FinishScene, event: Event) =
  scene.eventScene event


method event*(scene: FinishScene, event: Event) =
  scene.eventFinishScene event


proc updateFinishScene(scene: FinishScene, elapsed: float) =
  scene.updateScene elapsed
  scene.fadeTween.update elapsed
  #if not scene.fadeTween.playing:
  if scene.done:
    game.scene = endScene
  else:
    if scene.delay > 0:
      scene.delay -= elapsed
    else:
      if scene.text.queueLen > 0:
        scene.text.updateTypewriter elapsed
      elif scene.count < LineCount:
        for line in scene.textLines[scene.count].splitLines:
          scene.text.add line
        inc scene.count
        if scene.count <= (LineCount - RandomLines):
          scene.delay = Delay
        elif scene.count == (LineCount - RandomLines) + 1:
          scene.fadeTween.setup(1.0, 0.0, 10.0, 0)
          scene.fadeTween.play()
      else:
        scene.done = true


method update*(scene: FinishScene, elapsed: float) =
  scene.updateFinishScene elapsed

