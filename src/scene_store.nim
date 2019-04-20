import
  nimgame2 / [
    assets,
    entity,
    nimgame,
    scene,
    texturegraphic,
    tween,
    types,
    utils,
  ],
  actor,
  data,
  scene_game,
  scene_street,
  speech


const
  StoreObjects = {
    "bread": @[(188.0, 360.0), (444, 360), (444, 318), (188, 318)],
    "cheese": @[(193.0, 236.0), (436, 236), (436, 193), (195, 193)],
    "store_door": @[(535.0, 290.0), (625, 315), (620, 0), (580, 0), (540, 22)],
    "chips_stand": @[(190.0, 300.0), (440, 300), (440, 250), (190, 250)],
    "fire_extinguisher_stand": @[(460.0, 140.0), (500, 140), (500, 40), (460, 40)],
    "veggies": @[(0.0, 250.0), (65, 230), (130, 135), (0, 70)],
  }.toOrderedTable

  StoreWaypoints = {
    "store_door": (500.0, 15.0),
    "clerk": (350.0, 25.0),
    "veggies": (125.0, 15.0),
  }.toOrderedTable

  StoreFloor = @[(110.0, 0.0), (148, 40), (480, 40), (530, 0)]

  ClerkPos = (340.0, 140.0)
  ClerkPoints = @[(0.0, 0.0), (85, 0), (85, 95), (0, 95)]

type
  StoreScene* = ref object of GameScene
    fg*: Entity
    clerk*: Actor


# SCENE

proc initStoreScene*(scene: StoreScene) =
  initGameScene scene
  scene.bg = newEntity()
  scene.bg.graphic = gfxData["scene_store"]
  scene.bg.layer = LayerBG
  scene.add scene.bg
  scene.fg = newEntity()
  scene.fg.graphic = gfxData["scene_store_fg"]
  scene.fg.layer = LayerFG
  scene.add scene.fg
  scene.initFloor StoreFloor
  scene.initObjects StoreObjects
  scene.initHero StoreWaypoints["store_door"].swapY

  scene.clerk = newActor(scene)
  scene.clerk.tags.add "clerk"
  scene.clerk.tags.add "object"
  scene.clerk.layer = LayerFG - 1
  scene.clerk.graphic = gfxData["clerk"]
  scene.clerk.initSprite(ClerkSpriteSize)
  discard scene.clerk.addAnimation("front", [0], Framerate)
  discard scene.clerk.addAnimation("left", [1], Framerate)
  discard scene.clerk.addAnimation("right", [1], Framerate, Flip.horizontal)
  scene.clerk.center = (22.0, 22.0)
  scene.clerk.pos = ClerkPos
  scene.clerk.collider = scene.clerk.newPolyCollider(points = ClerkPoints)
  scene.add scene.clerk

  # objects
  scene.update(0.0)
  scene.objectGraphic("fire_extinguisher_stand").center += (15.0, 0.0)


proc free*(scene: StoreScene) =
  discard


proc newStoreScene*(): StoreScene =
  new result, free
  initStoreScene result


method show*(scene: StoreScene) =
  showGameScene scene
  let cheese = scene.find "cheese"
  cheese.layer = LayerBG


proc clerkReturn*(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  actor.switchTags "clerk_away", "clerk"
  actor.play("front", -1)


proc clerkGoAway*(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  actor.moveTween.setup(
    actor.pos,
    ClerkPos,
    duration = distance(actor.pos, ClerkPos) * ActorSpeed,
    loops = 0)
  actor.setAfterMove(clerkReturn, nil, "")
  actor.play("right", -1)
  actor.moveTween.play()


proc clerkRemoveMouse*(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  scene.del "mouse"
  scene.find("veggies_with_mouse").switchTags "veggies_with_mouse", "veggies"
  let pos: Coord = actor.pos - (256.0, 0.0)
  actor.moveTween.setup(
    actor.pos,
    pos,
    duration = distance(actor.pos, pos) * ActorSpeed,
    loops = 0)
  actor.setAfterMove(clerkGoAway, nil, "")
  actor.play("left", -1)
  actor.moveTween.play()


proc useObject(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  if obj == nil:
    write stdout, "ERROR: calling useObject with obj=nil\n"
    return
  let
    scene = StoreScene(scene)
    name = obj.nameTag
    spos = actor.speechPos
    spos2 = actor.speechPos + (0.0, -24.0)
    cpos = scene.clerk.pos + (32.0, -8.0)

  if name == "clerk":
    let obj = Actor(obj)
    if scene.find("veggies_with_mouse") == nil:
      scene.add cpos.newSpeech(lang("clerk", "say"), SpeechColorClerk)
    else:
      scene.add spos2.newSpeech lang("clerk", "use1")
      scene.add cpos.newSpeech(lang("clerk", "say1"), SpeechColorClerk)
      # clerk movement
      let
        mouse = scene.find("mouse")
        pos: Coord = (mouse.pos.x + 32.0, scene.clerk.pos.y)
      obj.moveTween.setup(
        obj.pos,
        pos,
        duration = obj.pos.x * ActorSpeed,
        loops = 0)

      obj.switchTags "clerk", "clerk_away"
      obj.setAfterMove(clerkRemoveMouse, mouse, "")
      obj.play("left", -1)
      obj.moveTween.play()

  elif name == "store_door":
    StreetScene(streetScene).spawn = StreetWaypoints["store"].swapY
    StreetScene(streetScene).say = lang("store_door", "use")
    game.scene = streetScene

  elif name == "fire_extinguisher_stand":
    if scene.find("clerk") == nil:
      scene.del "fire_extinguisher_stand"
      discard scene.addItem "fire_extinguisher"
      scene.add spos.newSpeech lang("fire_extinguisher_stand", "use1")
    else:
      scene.add cpos.newSpeech(
        lang("fire_extinguisher_stand", "say"), SpeechColorClerk)

  else:
    scene.add spos.newSpeech lang(name, "use")


proc useItem(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "") =
  if obj == nil:
    write stdout, "ERROR: calling useItem with obj=nil\n"
    return
  let
    scene = StoreScene(scene)
    name = obj.nameTag
    spos = actor.speechPos
    spos2 = actor.speechPos + (0.0, -24.0)
    cpos = scene.clerk.pos + (32.0, -8.0)

  if name == "clerk":
    # BUY CHIPS
    if item == "wallet_with_money":
      discard scene.delItem "wallet_with_money"
      discard scene.addItem "wallet"
      discard scene.addItem "chips"
      scene.add spos2.newSpeech lang("clerk", "with_money")
      scene.add cpos.newSpeech(lang("clerk", "say_money"), SpeechColorClerk)
    else:
      scene.add spos.newSpeech lang("clerk", "use")

  elif name == "veggies" and item == "mouse":
      # DEPOSIT MOUSE
      discard scene.delItem "mouse"
      let
        mouse = newEntity()
        veggies = scene.find("veggies")
      veggies.switchTags "veggies", "veggies_with_mouse"
      mouse.graphic = gfxData["item_mouse"]
      mouse.pos = veggies.pos + (50.0, 50.0)
      mouse.tags.add "mouse"
      mouse.layer = LayerObjectsAlt
      scene.add mouse
      scene.add spos.newSpeech lang("veggies", "with_mouse")

  else:
    let useWith = lang(name, "with_" & item)
    if useWith != "":
      scene.add spos.newSpeech useWith
    else:
      scene.add spos.newSpeech lang(item, "use")


method use*(scene: StoreScene, obj: Entity, item: string = "") =
  assert(obj != nil)
  let name = obj.nameTag
  #echo "USE ", name, (if item != "": " with " & item else: "")
  let after = if item == "": useObject
              else: useItem
  # MOVEMENT
  let way: Coord =
    if name in ["store_door", "fire_extinguisher_stand"]:
      StoreWaypoints["store_door"].swapY
    elif name in ["chips", "clerk"]:
      StoreWaypoints["clerk"].swapY
    elif name in ["veggies", "veggies_with_mouse"]:
      StoreWaypoints["veggies"].swapY
    else:
      scene.hero.pos
  # EXECUTE
  scene.moveHero way, after, obj, item
  scene.pointerItem -1


proc eventStoreScene*(scene: StoreScene, event: Event) =
  eventGameScene scene, event


method event*(scene: StoreScene, event: Event) =
  eventStoreScene scene, event


