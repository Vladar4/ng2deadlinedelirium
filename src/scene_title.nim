import
  nimgame2 / [
    assets,
    entity,
    nimgame,
    scene,
    texturegraphic,
    types,
    tween,
  ],
  data,
  scene_room,
  scene_street,
  scene_store


type
  TitleScene = ref object of Scene
    bg*: Entity
    fadeTween*: Tween[Entity, float]


proc initTitleScene*(scene: TitleScene) =
  initScene scene
  scene.bg = newEntity()
  scene.bg.layer = LayerBG
  scene.bg.graphic = gfxData["scene_title"]
  scene.add scene.bg
  # Tween
  scene.fadeTween = newTween[Entity, float](
    scene.bg,
    proc(t: Entity): float = TextureGraphic(t.graphic).alphaMod.float,
    proc(t: Entity, val: float) = TextureGraphic(t.graphic).alphaMod = (255*val).uint8)
  scene.fadeTween.procedure = linear
  scene.fadeTween.setup(0, 1, 1.0, 0)


proc free*(scene: TitleScene) =
  discard


proc newTitleScene*(): TitleScene =
  new result, free
  initTitleScene result


method show*(scene: TitleScene) =
  inventory = @[]
  roomScene = newRoomScene()
  streetScene = newStreetScene()
  storeScene = newStoreScene()
  scene.fadeTween.play()


proc eventTitleScene*(scene: TitleScene, event: Event) =
  scene.eventScene event

  if not scene.fadeTween.playing:
    if (event.kind == MouseButtonDown) or
      (event.kind == KeyDown):
      game.scene = startScene



method event*(scene: TitleScene, event: Event) =
  scene.eventTitleScene event


proc updateTitleScene(scene: TitleScene, elapsed: float) =
  scene.updateScene elapsed
  scene.fadeTween.update elapsed


method update*(scene: TitleScene, elapsed: float) =
  scene.updateTitleScene elapsed

