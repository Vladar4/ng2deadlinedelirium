import
  nimgame2 / [
    assets,
    entity,
    nimgame,
    scene,
    texturegraphic,
    types,
  ],
  actor,
  data,
  scene_game,
  speech


const
  StreetObjects = {
    "house": @[(70.0, 265.0), (179, 265), (170, 60), (85, 60)],
    "cardboard": @[(315.0, 80.0), (405, 200), (465, 175), (465, 95), (400, 40)],
    "dumpster": @[(217.0, 165.0), (272, 182), (348, 180), (323, 92), (292, 70), (247, 76)],
    "graffiti": @[(75.0, 219.0), (127, 265), (144, 240), (107, 194)],
    "store": @[(512.0, 265.0), (627, 267), (613, 60), (525, 60)],
  }.toOrderedTable

  StreetWaypoints* = {
    "house": (120.0, 45.0),
    "dumpster": (250.0, 45.0),
    "cardboard": (320.0, 45.0),
    "store": (560.0, 45.0),
  }.toOrderedTable

  StreetFloor = @[(15.0, 0.0), (85, 60), (615, 60), (615, 0)]

  ObjectBottlePos = (352.0, 185.0)
  ObjectBottlePoints = @[(0.0, 0.0), (30, -10), (49, 49), (20, 57)]


type
  StreetScene* = ref object of GameScene


# SCENE

proc initStreetScene*(scene: StreetScene) =
  initGameScene scene
  scene.bg = newEntity()
  scene.bg.graphic = gfxData["scene_street"]
  scene.bg.layer = LayerBG
  scene.add scene.bg
  scene.initFloor StreetFloor
  scene.initObjects StreetObjects
  scene.initHero StreetWaypoints["house"].swapY

  # objects
  scene.update(0.0)
  scene.objectGraphic("cardboard").center += (0.0, 120.0)

  # graffiti
  let grf = scene.find "graffiti"
  if grf != nil:
    grf.layer = LayerObjectsAlt


proc free*(scene: StreetScene) =
  discard


proc newStreetScene*(): StreetScene =
  new result, free
  initStreetScene result


proc useObject(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  if obj == nil:
    write stdout, "ERROR: calling useObject with obj=nil\n"
    return
  let
    scene = GameScene(scene)
    name = obj.nameTag
    spos = actor.speechPos

  discard lang("", "")

  if name == "cardboard":
    obj.switchTags "cardboard", "hobo"
    obj.graphic = gfxData["object_hobo"]
    let bottle = newEntity()
    bottle.layer = LayerObjectsAlt
    bottle.tags.add "object"
    bottle.tags.add "bottle"
    bottle.pos = ObjectBottlePos
    bottle.collider = bottle.newPolyCollider(points = ObjectBottlePoints)
    scene.add bottle
    scene.add spos.newSpeech lang("cardboard", "use")

  elif name == "dumpster":
    if inventory.find("mouse") < 0:
      discard scene.addItem "mouse"
      scene.add spos.newSpeech lang("dumpster", "use")
    else:
      scene.add spos.newSpeech lang("dumpster", "use2")

  elif name == "house":
    GameScene(roomScene).say = lang("house", "use")
    game.scene = roomScene

  elif name == "store":
    GameScene(storeScene).say = lang("store", "use")
    game.scene = storeScene

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

  if name == "bottle" and item == "fire_extinguisher_empty":
    scene.find("hobo").graphic = gfxData["object_hobo2"]
    obj.switchTags "bottle"
    discard scene.delItem "fire_extinguisher_empty"
    discard scene.addItem "beer"
    scene.add spos.newSpeech lang("bottle", "with_fire_extinguisher_empty")

  else:
    let useWith = lang(name, "with_" & item)
    if useWith != "":
      scene.add spos.newSpeech useWith
    else:
      scene.add spos.newSpeech lang(item, "use")


method use*(scene: StreetScene, obj: Entity, item: string = "") =
  assert(obj != nil)
  let name = obj.nameTag
  #echo "USE ", name, (if item != "": " with " & item else: "")
  let after = if item == "": useObject
              else: useItem
  # MOVEMENT
  let way: Coord =
    if name in ["house", "graffiti"]:
      StreetWaypoints["house"].swapY
    elif name in ["dumpster"]:
      StreetWaypoints["dumpster"].swapY
    elif name in ["cardboard", "hobo", "bottle"]:
      StreetWaypoints["cardboard"].swapY
    elif name in ["store"]:
      StreetWaypoints["store"].swapY
    else:
      scene.hero.pos
  # EXECUTE
  scene.moveHero way, after, obj, item


proc eventStreetScene*(scene: StreetScene, event: Event) =
  eventGameScene scene, event


method event*(scene: StreetScene, event: Event) =
  eventStreetScene scene, event


