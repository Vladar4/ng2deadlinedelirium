import
  nimgame2 / [
    assets,
    entity,
    input,
    texturegraphic,
  ]


const
  MousePointerDim = (32, 32)
  MousePointerCenter = (3.0, 3.0)
  MousePointerItemOffset* = (-14.0, -30.0)

type
  MousePointer* = ref object of Entity
    target*: Entity


# MOUSE POINTER

proc initMousePointer*(mp: MousePointer, graphic: TextureGraphic) =
  initEntity mp
  mp.layer = 1000
  mp.collider = newCollider(mp)
  mp.graphic = graphic
  mp.center = MousePointerCenter
  mp.initSprite(MousePointerDim)


proc newMousePointer*(graphic: TextureGraphic): MousePointer =
  new result
  initMousePointer result, graphic


proc updateMousePointer*(mp: MousePointer, elapsed: float) =
  mp.updateEntity elapsed
  mp.target = nil
  mp.sprite.currentFrame =
    if MouseButton.left.down: 1
    elif MouseButton.right.down: 2
    else: 0


method update*(mp: MousePointer, elapsed: float) =
  mp.updateMousePointer elapsed


proc onCollideMousePointer*(mp: MousePointer, target: Entity) =
  mp.target = target


method onCollide*(mp: MousePointer, target: Entity) =
  mp.onCollideMousePointer target

