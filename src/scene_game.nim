
#===============================#
# BASE TYPE FOR ALL GAME SCENES #
#===============================#

import
  nimgame2 / [
    gui/button,
    gui/widget,
    assets,
    entity,
    font,
    graphic,
    input,
    nimgame,
    scene,
    settings,
    textgraphic,
    truetypefont,
    tween,
    types,
    typewriter,
    utils,
  ],
  actor,
  data,
  mpointer,
  speech

const
  ToolbarCount* = 16


type
  ToolbarButton* = ref object of GuiButton
    id: int

  GameScene* = ref object of Scene
    toolbar*: array[ToolbarCount, ToolbarButton]
    bg*, floor*: Entity
    hero*: Actor
    spawn*: Coord # hero spawn or (0.0, 0.0)
    say*: string  # hero speech on spawn
    itemId*: int ## id in the inventory
    # Private fields
    fHint: Typewriter
    fItem: Entity # using an item
    isMaximized: bool

# TOOLBAR BUTTON

proc initToolbarButton*(btn: ToolbarButton, id: int) =
  btn.initGuiButton(gfxData["gui_toolbar_button"])
  btn.tags.add "toolbar"
  btn.layer = LayerToolbar
  btn.id = id
  btn.pos = (float(id * btn.sprite.dim.w), 0.0)
  btn.imageOffset = (4.0, 4.0)


proc newToolbarButton*(id: int): ToolbarButton =
  new result
  initToolbarButton result, id


proc clickToolbarButton*(btn: ToolbarButton, mb: MouseButton) =
  discard


method onClick*(btn: ToolbarButton, mb: MouseButton) =
  btn.clickToolbarButton mb


# HINT

proc hint*(scene: GameScene): string =
  scene.fHint.text


proc `hint=`*(scene: GameScene, val: string) =
  scene.fHint.clear true
  scene.fHint.center.x =
    TextGraphic(scene.fHint.graphic).font.lineDim(val).w.float / 2
  scene.fHint.add val


proc clearHint*(scene: GameScene) =
  scene.fHint.clear true


# SCENE

proc updateToolbar*(scene: GameScene) =
  for i in 0..<ToolbarCount-1:
    if i < inventory.len:
      scene.toolbar[i].show
      scene.toolbar[i].enable
      scene.toolbar[i].image = gfxData["item_" & inventory[i]]
    else:
      scene.toolbar[i].disable
      scene.toolbar[i].image = nil
      scene.toolbar[i].hide


proc addItem*(scene: GameScene, item: string): bool =
  if inventory.len < ToolbarCount - 1:
    inventory.add item
    updateToolbar scene
    return true
  else:
    return false


proc delItem*(scene: GameScene, item: string): bool =
  let id = inventory.find item
  if id >= 0:
    inventory.delete id
    updateToolbar scene
    return true
  else:
    return false


proc swapY*(coord: Coord): Coord =
  # swap Y coord (Thanks, Inkscape!)
  (coord.x, GameHeight - coord.y)


proc swapY*(coords: openarray[Coord]): seq[Coord] =
  for coord in coords:
    result.add coord.swapY


proc initFloor*(scene: GameScene, points: openarray[Coord]) =
  scene.floor = newEntity()
  scene.floor.tags.add "floor"
  scene.floor.collider = scene.floor.newPolyCollider(points = swapY points)
  scene.add scene.floor


proc objectGraphic*(scene: GameScene, name: string, graphic: string = ""): Entity =
  ##  Set object's graphic and return its entity.
  ##
  let obj = scene.find(name)
  if obj == nil:
    return nil
  obj.graphic =
    if graphic == "":
      gfxData["object_" & name]
    else:
      gfxData[graphic]
  return obj


proc switchTags*(obj: Entity, before, after: string = "") =
  let pos = obj.tags.find before
  if pos >= 0:
    obj.tags.delete pos
  if after != "":
    obj.tags.add after


proc initObjects*(scene: GameScene, table: OrderedTable[string, seq[Coord]]) =
  for k, v in table.pairs:
    let obj = newEntity()
    obj.layer = LayerObjects
    obj.tags.add "object"
    obj.tags.add k
    let root = v[0].swapY
    obj.pos = root
    var points: seq[Coord]
    for point in v:
      points.add point.swapY - root
    obj.collider = obj.newPolyCollider(points = points)
    scene.add obj


proc initHero*(scene: GameScene, pos: Coord) =
  scene.hero = newActor(scene)
  scene.hero.tags.add "hero"
  scene.hero.tags.add "actor"
  scene.hero.layer = LayerHero
  scene.hero.graphic = gfxData["hero"]
  # SPRITE
  scene.hero.initSprite(HeroSpriteSize)
  discard scene.hero.addAnimation("front_left", toSeq(0..11), Framerate)
  discard scene.hero.addAnimation("front_right", toSeq(0..11), Framerate, Flip.horizontal)
  discard scene.hero.addAnimation("back_left", toSeq(12..23), Framerate)
  discard scene.hero.addAnimation("back_right", toSeq(12..23), Framerate, Flip.horizontal)
  #
  scene.hero.centrify(ver = VAlign.bottom)
  scene.hero.pos = pos
  scene.add scene.hero


proc moveHero*(scene: GameScene, pos: Coord,
    afterMove: AfterMove = nil, obj: Entity = nil, item: string = "") =
  scene.hero.setAfterMove(afterMove, obj, item)
  let tween = scene.hero.moveTween
  tween.setup(
    scene.hero.pos,
    pos,
    duration = distance(scene.hero.pos, pos) * ActorSpeed,
    loops = 0)
  let
    facing = if scene.hero.pos.y < pos.y: "front_"
             else: "back_"
    side = if scene.hero.pos.x > pos.x: "left"
           else: "right"
  scene.hero.setAfterMove(afterMove, obj, item)
  scene.hero.play(facing & side, -1)
  tween.play()


proc initGameScene*(scene: GameScene) =
  initScene scene
  # toolbar
  for i in 0..<ToolbarCount:
    scene.toolbar[i] = newToolbarButton i
    scene.toolbar[i].tags.add "item_" & $i
    scene.add scene.toolbar[i]
  #scene.toolbar[^1].image = gfxData["item_menu"]
  scene.toolbar[^1].hide()
  updateToolbar scene
  # mousePointer
  scene.add mousePointer
  # hint
  scene.fHint = newTypewriter(newTextGraphic normalFont, HintSpeed)
  TextGraphic(scene.fHint.graphic).color = HintColor
  scene.fHint.layer = LayerGUI
  scene.fHint.center.y = 16.0
  scene.fHint.parent = mousePointer
  scene.add scene.fHint
  # item
  scene.itemId = -1
  scene.fItem = newEntity()
  scene.fItem.layer = LayerUseItem
  scene.fItem.parent = mousePointer
  scene.fItem.center = MousePointerItemOffset
  scene.add scene.fItem


proc free*(scene: GameScene) =
  discard


proc newGameScene*(): GameScene =
  new result, free
  initGameScene result


proc showGameScene*(scene: GameScene) =
  hideCursor()
  updateToolbar scene
  if scene.spawn > (0.0, 0.0):
    scene.hero.pos = scene.spawn
  if scene.say != "":
    scene.add scene.hero.speechPos.newSpeech scene.say
    scene.say = ""
  mousePointer.pos = mouse.abs


method show*(scene: GameScene) =
  showGameScene scene


proc pointerItem*(scene: GameScene, id: int) =
  scene.itemId = id
  if id < 0:
    scene.fItem.graphic = nil
  else:
    scene.fItem.graphic = gfxData["item_" & inventory[id]]


proc hideGameScene*(scene: GameScene) =
  scene.del "speech"
  if scene.itemId >= 0:
    scene.itemId = -1
    scene.fItem.graphic = nil


method hide*(scene: GameScene) =
  hideGameScene scene


# EVENT

proc nameTag*(entity: Entity): string =
  for tag in entity.tags:
    if tag == "toolbar" or tag == "object":
      continue
    return tag


method use*(scene: GameScene, obj: Entity, item: string = "") {.base.} =
  discard


proc eventGameScene*(scene: GameScene, event: Event) =
  scene.eventScene event

  # mousePointer target
  let target = mousePointer.target

  # MOUSE MOTION
  if event.kind == MouseMotion:
    let m = (event.motion.x.float, event.motion.y.float)
    mousePointer.pos = m
    var hint: string
    if target == nil:
      hint = ""
    else:
      if "toolbar" in target.tags and GuiWidget(target).state.isEnabled:
        let id = ToolbarButton(target).id
        if id >= 15:
          hint = lang("gui", "menu")
        else:
          hint = lang(inventory[id], "name")
      elif "object" in target.tags:
          hint = lang(target.nameTag, "name")
    if scene.hint != hint:
      scene.hint = hint

  # MOUSE BUTTON DOWN
  elif event.kind == MouseButtonDown:
    let
      m = (event.button.x.float, event.button.y.float)

    # LEFT BUTTON
    if target != nil and event.button.button == MouseButton.left:
      # FLOOR
      if "floor" in target.tags:
        scene.moveHero m
      # OBJECT
      elif "object" in target.tags:
        if scene.itemId >= 0:
          scene.use target, inventory[scene.itemId]
          scene.pointerItem -1
        else:
          # USE OBJECT
          scene.use target
      # ITEM
      elif "toolbar" in target.tags and GuiWidget(target).state.isEnabled:
        let id = ToolbarButton(target).id
        if id < 15:

          # SPECIAL CASE ITEMS
          proc eat(scene: GameScene) =
            discard scene.delItem("beer_cold")
            discard scene.delItem("chips")
            discard scene.addItem("knife")
            scene.add scene.hero.speechPos.newSpeech lang("food", "use")

          if inventory[id] == "beer_cold":
            if inventory.find("chips") < 0:
              scene.add scene.hero.speechPos.newSpeech lang("beer_cold", "use")
            else:
              eat scene
          elif inventory[id] == "chips":
            if inventory.find("beer_cold") < 0:
              scene.add scene.hero.speechPos.newSpeech lang("chips", "use")
            else:
              eat scene

          else:
            scene.pointerItem id
        else:
          #TODO menu
          discard

    # RIGHT BUTTON
    elif event.button.button == MouseButton.right:

      # CANCEL ITEM USE
      if scene.itemId >= 0:
        scene.itemId = -1
        scene.fItem.graphic = nil

      elif target != nil:
        # OBJECT
        if "object" in target.tags:
          scene.add newSpeech(
            scene.hero.speechPos, lang(target.nameTag, "look"))
        # ITEM
        elif "toolbar" in target.tags and GuiWidget(target).state.isEnabled:
          let id = ToolbarButton(target).id
          if id < 15:
            scene.add newSpeech(
              scene.hero.speechPos, lang(inventory[id], "look"))

  # KEY UP
  elif event.kind == KeyUp:
    # Fullscreen
    if event.key.keysym.scancode == ScancodeF11:
      scene.isMaximized = game.maximized or game.fullscreen
      toggleFullscreen()
      if scene.isMaximized:
        maximize game
    elif event.key.keysym.scancode == ScancodeReturn:
      toggleFullscreen()
    # Colliders
    elif event.key.keysym.scancode == ScancodeF10:
      colliderOutline = not colliderOutline
    # Info
    elif event.key.keysym.scancode == ScancodeF12:
      showInfo = not showInfo


method event*(scene: GameScene, event: Event) =
  scene.eventGameScene event


# UPDATE

proc updateGameScene*(scene: GameScene, elapsed: float) =
  scene.updateScene elapsed


method update*(scene: GameScene, elapsed: float) =
  scene.updateGameScene elapsed

