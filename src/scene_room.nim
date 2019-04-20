import
  nimgame2 / [
    assets,
    entity,
    graphic,
    input,
    nimgame,
    scene,
    texturegraphic,
    types,
  ],
  actor,
  data,
  scene_game,
  scene_street,
  scene_finish,
  speech


const
  RoomObjects = {
    "bed": @[(416.0, 140.0), (499, 140), (640, 68), (640, 0), (498, 0), (416, 70)],
    "computer": @[(244.0, 213.0), (331, 213), (366, 224), (400, 224), (400, 145), (244, 145)],
    "door": @[(0.0, 280.0), (27, 268), (27, 42), (0, 30)],
    "fridge": @[(45.0, 238.0), (87, 238), (151, 227), (150, 72), (87, 49), (45, 49)],
    "note": @[(249.0, 207.0), (273, 207), (273, 187), (249, 187)],
    "piggy_bank": @[(155.0, 178.0), (196, 178), (196, 144), (155, 144)],
    "plug": @[(368.0, 79.0), (385, 79), (385 ,61), (368, 61)],
    "poster": @[(419.0, 298.0), (480, 298), (480, 208), (419, 208)],
    "shelf": @[(117.0, 298.0), (170, 298), (221, 253), (240, 301), (292, 301), (314, 249), (332, 249), (332, 238), (117, 238)],
    "window": @[(548.0, 298.0), (640, 313), (640, 139), (548, 166)],
  }.toOrderedTable

  RoomWaypoints = {
    "bed": (420.0, 30.0),
    "chair": (302.0, 30.0),
    #"computer": (366.0, 30.0),
    "door": (45.0, 30.0),
    "fridge": (174.0, 53.0),
  }.toOrderedTable

  RoomFloor = @[(0.0, 0.0), (0, 15), (45, 30), (87, 30), (160, 55), (270, 55), (280, 45), (400, 45), (450, 0)]


type
  RoomScene* = ref object of GameScene


# SCENE

proc initRoomScene*(scene: RoomScene) =
  initGameScene scene
  scene.bg = newEntity()
  scene.bg.graphic = gfxData["scene_room"]
  scene.bg.layer = LayerBG
  scene.add scene.bg
  scene.initFloor RoomFloor
  scene.initObjects RoomObjects
  scene.initHero RoomWaypoints["bed"].swapY

  # objects
  scene.update(0.0)
  scene.objectGraphic("computer").center += (0.0, 56.0)
  scene.objectGraphic("piggy_bank").center += (3.0, 2.0)
  scene.objectGraphic("plug").center += (16.0, 43.0)

  let chair = newEntity()
  chair.layer = LayerObjectsAlt
  chair.graphic = gfxData["object_chair"]
  chair.pos = (275.0, 182.0)
  scene.add chair

  # note
  let note = scene.find "note"
  if note != nil:
    note.layer = LayerObjectsAlt

  # wallet
  discard scene.addItem "wallet"




proc free*(scene: RoomScene) =
  discard


proc newRoomScene*(): RoomScene =
  new result, free
  initRoomScene result


proc useObject(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  if obj == nil:
    write stdout, "ERROR: calling useObject with obj=nil\n"
    return
  let
    scene = GameScene(scene)
    name = obj.nameTag
    spos = actor.speechPos

  if name == "computer":
    if scene.contains "plug":
      scene.add spos.newSpeech lang("computer", "use")
    else:
      obj.switchTags "computer", "computer_burning"
      let dim = obj.graphic.dim
      obj.graphic = gfxData["object_computer_burning"]
      obj.initSprite(dim)
      discard obj.addAnimation("burn", toSeq(0..11), Framerate)
      obj.play("burn")
      scene.add spos.newSpeech lang("computer", "plug")

  elif name == "computer_fixed":
    showCursor()
    game.scene = finishScene

  elif name == "door":
    GameScene(streetScene).spawn = StreetWaypoints["house"].swapY
    GameScene(streetScene).say = lang("door", "use")
    game.scene = streetScene

  elif name == "fridge":
    scene.add spos.newSpeech lang("fridge", "use")

  elif name == "piggy_bank":
    discard scene.delItem "wallet"
    discard scene.addItem "wallet_with_money"
    obj.switchTags "piggy_bank"
    obj.graphic = gfxData["object_piggy_bank_empty"]
    scene.add spos.newSpeech lang("piggy_bank", "use")

  elif name == "plug":
    obj.graphic = gfxData["object_plugged"]
    obj.switchTags "plug"
    scene.add spos.newSpeech lang("plug", "use")

  else:
    scene.add spos.newSpeech lang(name, "use")


proc useItem(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  if obj == nil:
    write stdout, "ERROR: calling useItem with obj=nil\n"
    return
  let
    scene = GameScene(scene)
    name = obj.nameTag
    spos = actor.speechPos

  if name == "fridge" and item == "beer":
    discard scene.delItem "beer"
    discard scene.addItem "beer_cold"
    scene.add spos.newSpeech lang("fridge", "with_beer")

  elif name == "computer_burning" and item == "fire_extinguisher":
    obj.switchTags "computer_burning", "computer_broken"
    obj.stop()
    obj.sprite = nil
    obj.graphic = gfxData["object_computer_broken"]
    discard scene.delItem "fire_extinguisher"
    discard scene.addItem "fire_extinguisher_empty"
    scene.add spos.newSpeech lang("computer_burning", "with_fire_extinguisher")

  elif name == "computer_broken" and item == "knife":
    obj.switchTags "computer_broken", "computer_fixed"
    obj.graphic = gfxData["object_computer_fixed"]
    scene.add spos.newSpeech lang("computer_broken", "with_knife")

  else:
    let useWith = lang(name, "with_" & item)
    if useWith != "":
      scene.add spos.newSpeech useWith
    else:
      scene.add spos.newSpeech lang(item, "use")



method use*(scene: RoomScene, obj: Entity, item: string = "") =
  assert(obj != nil)
  let name = obj.nameTag
  #echo "USE ", name, (if item != "": " with " & item else: "")
  let after = if item == "": useObject
              else: useItem
  # MOVEMENT
  let way: Coord =
    if name in ["bed", "poster", "window"]:
      RoomWaypoints["bed"].swapY
    elif name in ["computer", "computer_burning", "computer_broken",
                  "computer_fixed", "note", "plug"]:
      RoomWaypoints["chair"].swapY
    elif name in ["door"]:
      RoomWaypoints["door"].swapY
    elif name in ["fridge", "piggy_bank", "shelf"]:
      RoomWaypoints["fridge"].swapY
    else:
      scene.hero.pos
  # EXECUTE
  scene.moveHero way, after, obj, item


proc eventRoomScene*(scene: RoomScene, event: Event) =
  eventGameScene scene, event


method event*(scene: RoomScene, event: Event) =
  eventRoomScene scene, event

