#
jule = {
  boardWidth: 30,
  boardHeight: 30,
  boardSpacing: 20,
  gameInterval: 300
}

#
# Run fn
#

jule.initGame = ->
  # Initialize board
  jule.initBoard()
  # Generate context
  jule.getCanvas()
  # Build world
  window.requestAnimationFrame(jule.executeSequence)
  # Start run interval
  jule.runGameInterval()

#
#
#

jule.initBoard = ->

  jule.board = []

  for line in [0..jule.boardHeight]
    jule.board.push([])

    for col in [0..jule.boardWidth]
      jule.board[line].push(null)

  jule.players = []

  jule.players.push({
    id: 0,
    name: 'Gonçalo',
    score: 0,
    orientation: 'right',
    position: [10, 10],
    lastPosition: null,
    color: 'red'
  })

#
#
#

jule.runGameInterval = ->

  window.setInterval ->

    jule.updateGame()

  , jule.gameInterval

#
#
#

jule.detectCollision = (pos, dir) ->

  switch dir

    when 'up'
      true if jule.board[pos[1]-1][pos[0]] isnt null

    when 'down'
      true if jule.board[pos[1]+1][pos[0]] isnt null

    when 'left'
      true if jule.board[pos[1]][pos[0]-1] isnt null

    when 'right'
      true if jule.board[pos[1]][pos[0]+1] isnt null

#
#
#

jule.playerLost = (player) ->
  player.lost = true

  # Clear from board
  for line, lineIndex in jule.board
    for col, colIndex in line
      jule.board[lineIndex][colIndex] = null if col is player.id

  jule.initBoard()

#
#
#

jule.updatePlayer = (player) ->

  return if player.lost

  switch player.orientation

    when 'up'
      jule.board[player.position[1]-1][player.position[0]] = player.id
      player.position[1]--

    when 'down'
      jule.board[player.position[1]+1][player.position[0]] = player.id
      player.position[1]++

    when 'left'
      jule.board[player.position[1]][player.position[0]-1] = player.id
      player.position[0]--

    when 'right'
      jule.board[player.position[1]][player.position[0]+1] = player.id
      player.position[0]++

  player.lastOrientation = player.orientation

#
#
#

jule.updateGame = ->

  # Calculate players board occupation
  for player in jule.players
    jule.playerLost(player) if jule.detectCollision(player.position, player.orientation)
    jule.updatePlayer(player)

#
# Get canvas env
#

jule.getCanvas = ->
  # Get canvas dom element
  jule.canvas = document.getElementById 'jule'

  # Check for browser compatibility
  if jule.canvas.getContext
    jule.ctx = jule.canvas.getContext '2d'
    jule.bindCanvas()
  else
    location.href = 'http://www.disney.com'

#
#
#

jule.playerMove = (player, dir) ->
  if !player
    # Current player
    player = jule.players[0]

  return if player.lastOrientation is dir

  return if player.lastOrientation is 'up' and dir is 'down'
  return if player.lastOrientation is 'left' and dir is 'right'
  return if player.lastOrientation is 'down' and dir is 'up'
  return if player.lastOrientation is 'right' and dir is 'left'

  # Set player orientation
  player.orientation = dir

#
#
#

jule.bindCanvas = ->

  document.addEventListener 'keydown', (e)  ->

    if e.keyCode is 87 or e.keyCode is 38
      jule.playerMove(false, 'up')

    if e.keyCode is 83 or e.keyCode is 40
      jule.playerMove(false, 'down')

    if e.keyCode is 65 or e.keyCode is 37
      jule.playerMove(false, 'left')

    if e.keyCode is 68 or e.keyCode is 39
      jule.playerMove(false, 'right')

  , true

  return

#
#
#
jule.getPlayerById = (id) ->

  for player in jule.players
    if id is player.id
      player

  null

#
#
#
jule.executeSequence = ->

  ctx = jule.ctx

  # Clear board
  ctx.clearRect(0, 0, jule.canvas.width, jule.canvas.height);

  #
  # Build board lines
  #

  for colIndex in [0..jule.boardWidth]
    ctx.beginPath()
    ctx.moveTo(colIndex * jule.boardSpacing, 0)
    ctx.lineTo(colIndex * jule.boardSpacing, jule.boardHeight * jule.boardSpacing)
    ctx.stroke()

  for rowIndex in [0..jule.boardHeight]
    ctx.beginPath()
    ctx.moveTo(0, rowIndex * jule.boardSpacing)
    ctx.lineTo(jule.boardWidth * jule.boardSpacing, rowIndex * jule.boardSpacing)
    ctx.stroke()

  #
  # Players
  #

  for row, rowIndex in jule.board
    for col, colIndex in row
      # Check for player color
      if col isnt null
        ctx.fillRect(colIndex * jule.boardSpacing, rowIndex * jule.boardSpacing, jule.boardSpacing, jule.boardSpacing)

  # Redraw
  window.requestAnimationFrame(jule.executeSequence)

# Execute
jule.initGame()