import
  strutils,
  nimgame2 / [
    assets,
    entity,
    font,
    nimgame,
    textgraphic,
    types,
    typewriter,
  ],
  data


type
  Speech* = ref object of Typewriter
    timer*: float


proc initSpeech*(speech: Speech, pos: Coord, text: string, color: Color = SpeechColor) =
  speech.initTypewriter newTextGraphic normalFont, SpeechSpeed
  speech.layer = LayerGUI
  speech.tags.add "speech"
  TextGraphic(speech.graphic).color = color
  #TextGraphic(speech.graphic).align = TextAlign.center
  speech.pos = pos - (0.0, TextGraphic(speech.graphic).font.charH.float)
  let font = TextGraphic(speech.graphic).font
  var length = 0.0
  for line in text.splitLines:
    speech.add line
    let newLength = font.lineDim(line).w.float
    if newLength > length:
      length = newLength
  speech.center.x = length / 2
  speech.timer = font.lineDim(text).w.float * SpeechTimerPerChar
  # Movement
  speech.vel.y = -16.0
  speech.physics = defaultPhysics


proc newSpeech*(pos: Coord, text: string, color: Color = SpeechColor): Speech =
  new result
  result.initSpeech pos, text, color


proc updateSpeech*(speech: Speech, elapsed: float) =
  speech.updateTypewriter elapsed
  if speech.queueLen < 1: # all typed out
    if speech.timer > 0.0:
      speech.timer -= elapsed
    if speech.timer <= 0.0:
      speech.dead = true


method update*(speech: Speech, elapsed: float) =
  speech.updateSpeech elapsed

