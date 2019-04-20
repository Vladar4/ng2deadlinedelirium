import
  nimgame2 / [
    assets,
    entity,
    scene,
    tween,
    types,
  ],
  data


type
  AfterMove* = proc(
    scene: Scene, actor: Actor, obj: Entity = nil, item: string = "")

  Actor* = ref object of Entity
    scene*: Scene
    moveTween*: Tween[Entity, Coord]
    afterMove*: AfterMove
    obj*: Entity
    item*: string


proc setAfterMove*(
    actor: Actor, afterMove: AfterMove, obj: Entity, item: string = "") =
  actor.afterMove = afterMove
  actor.obj = obj
  actor.item = item


template speechPos*(actor: Actor): Coord =
  (actor.pos - (0.0, actor.sprite.dim.h.float))


proc initActor*(actor: Actor, scene: Scene) =
  initEntity actor
  actor.scene = scene
  actor.moveTween = newTween[Entity, Coord](
    actor,
    proc(t: Entity): Coord = t.pos,
    proc(t: Entity, val: Coord) = t.pos = val)
  actor.moveTween.procedure = linear


proc newActor*(scene: Scene): Actor =
  new result
  assert(scene != nil)
  initActor result, scene


proc updateActor*(actor: Actor, elapsed: float) =
  actor.updateEntity elapsed
  actor.moveTween.update elapsed
  if not actor.moveTween.playing:
    actor.stop(true)
    if actor.afterMove != nil:
      let afterMove = actor.afterMove
      actor.afterMove = nil
      afterMove actor.scene, actor, actor.obj, actor.item


method update*(actor: Actor, elapsed: float) =
  actor.updateActor elapsed

