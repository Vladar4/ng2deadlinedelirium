import
  nimgame2 / [
    assets,
    nimgame,
    entity,
    scene,
    settings,
    textgraphic,
    texturegraphic,
    tween,
    types,
    utils
  ],
  data,
  scene_end,
  scene_finish,
  scene_game,
  scene_room,
  scene_start,
  scene_store,
  scene_street,
  scene_title


type
  IntroScene = ref object of Scene
    loading: Entity
    loadingTween: Tween[Entity, float]


proc initIntroScene*(scene: IntroScene) =
  initScene scene


proc free*(scene: IntroScene) =
  discard


proc newIntroScene*(): IntroScene =
  new result, free
  initIntroScene result


method show*(scene: IntroScene) =

  # LOAD
  loadFonts()

  # Loading text
  let loadingText = newTextGraphic(bigFont)
  loadingText.setText "Loading..."
  scene.loading = newEntity()
  scene.loading.graphic = loadingText
  scene.loading.centrify
  scene.loading.pos = (GameWidth / 2, GameHeight / 2)
  scene.add scene.loading
  scene.loadingTween = newTween[Entity, float](
    scene.loading,
    proc(t: Entity): float = TextureGraphic(scene.loading.graphic).alphaMod.float,
    proc(t: Entity, val: float) = TextureGraphic(scene.loading.graphic).alphaMod = uint8 val)
  scene.loadingTween.procedure = inOutSine
  scene.loadingTween.setup(255, 0, duration = 0.5, loops = -1)
  scene.loadingTween.play()

  # Loading cycle
  var
    timeA, timeB: uint64
  timeA = getPerformanceCounter()
  for c in loadData():
    timeB = getPerformanceCounter()
    let elapsed = timeDiff(timeA, timeB).msToSec
    scene.loadingTween.update elapsed
    game.forceRender elapsed
    timeA = timeB

  # After load
  scene.loadingTween.stop()
  scene.loading.visible = false
  game.maximize()

  # INIT
  titleScene = newTitleScene()
  startScene = newStartScene()
  finishScene = newFinishScene()
  endScene = newEndScene()
  #roomScene = newRoomScene()
  #streetScene = newStreetScene()
  #storeScene = newStoreScene()

  game.scene = titleScene


proc eventIntroScene*(scene: IntroScene, event: Event) =
  eventScene scene, event


method event*(scene: IntroScene, event: Event) =
  scene.eventIntroScene event


proc updateIntroScene*(scene: IntroScene, elapsed: float) =
  scene.updateScene elapsed


method update*(scene: IntroScene, elapsed: float) =
  scene.updateIntroScene elapsed

