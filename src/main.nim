import
  nimgame2 / [
    input,
    nimgame,
    settings,
    types,
  ],
  data,
  scene_intro


game = newGame()
if game.init(GameWidth, GameHeight, title = GameTitle, integerScale = false):
  # INIT
  game.setResizable true
  game.minSize = (GameWidth, GameHeight)
  game.centrify()
  # SCENES
  introScene = newIntroScene()
  # RUN
  game.scene = introScene
  run game
  showCursor()

