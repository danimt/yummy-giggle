#
game = {
  boardWidth: 300,
  boardHeight: 300,
  boardSpacing: 30,
  gameInterval: 100,
  playerHeight: 5,
  playerDepth: 1,
  camAngle: 0 
  camSmoothness: 5
}

Number::mod = (n) ->
  (this % n + n) % n

#
# Run fn
#

game.initGame = ->
  # Initialize board
  game.initBoard()
  # Bind
  game.bind()
  # Generate context
  game.getCanvas()

  window.setInterval ->
    game.updateGame()
  , game.gameInterval

#
#
#

game.initBoard = ->

  game.board = []

  for line in [0..game.boardHeight]
    game.board.push([])

    for col in [0..game.boardWidth]
      game.board[line].push(null)

  game.players = []

  game.players.push({
    id: 0,
    name: 'Gonçalo',
    score: 0,
    orientation: 'right',
    position: [1, 1],
    lastPosition: null,
    color: 0xff0000
  })

#
#
#

game.detectCollision = (pos, dir) ->

  switch dir

    when 'up'
      true if pos[1]-1 < 0 or game.board[pos[1]-1][pos[0]] isnt null 

    when 'down'
      true if pos[1]+1 >= game.boardHeight or game.board[pos[1]+1][pos[0]] isnt null

    when 'left'
      true if pos[0]-1 < 0 or game.board[pos[1]][pos[0]-1] isnt null

    when 'right'
      true if pos[0]+1 >= game.boardWidth or game.board[pos[1]][pos[0]+1] isnt null

#
#
#

game.playerLost = (player) ->
  player.lost = true

  # Clear from board
  for line, lineIndex in game.board
    for col, colIndex in line
      game.board[lineIndex][colIndex] = null if col is player.id

  game.destroyPlayerObject(player)
  game.initBoard()

#
#
#

game.updatePlayer = (player) ->

  return if player.lost

  switch player.orientation

    when 'up'
      game.board[player.position[1]-1][player.position[0]] = player.id
      player.position[1]--

    when 'down'
      game.board[player.position[1]+1][player.position[0]] = player.id
      player.position[1]++

    when 'left'
      game.board[player.position[1]][player.position[0]-1] = player.id
      player.position[0]--

    when 'right'
      game.board[player.position[1]][player.position[0]+1] = player.id
      player.position[0]++

  player.lastOrientation = player.orientation

  #
  game.renderPlayer(player)

#
#
#

game.playerMove = (player, dir) ->
  if !player
    # Current player
    player = game.players[0]

  newDir = 'down' if dir is 'right' and player.lastOrientation is 'right'
  newDir = 'up' if dir is 'left' and player.lastOrientation is 'right'

  newDir = 'up' if dir is 'right' and player.lastOrientation is 'left'
  newDir = 'down' if dir is 'left' and player.lastOrientation is 'left'

  newDir = 'left' if dir is 'right' and player.lastOrientation is 'down'
  newDir = 'right' if dir is 'left' and player.lastOrientation is 'down'

  newDir = 'right' if dir is 'right' and player.lastOrientation is 'up'
  newDir = 'left' if dir is 'left' and player.lastOrientation is 'up'

  # Set player orientation
  player.orientation = newDir

#
#
#

game.bind = ->

  document.addEventListener 'keydown', (e)  ->

    #if e.keyCode is 87 or e.keyCode is 38
    #  game.playerMove(false, 'up')

    #if e.keyCode is 83 or e.keyCode is 40
    #  game.playerMove(false, 'down')

    if e.keyCode is 65 or e.keyCode is 37
      game.playerMove(false, 'left')

    if e.keyCode is 68 or e.keyCode is 39
      game.playerMove(false, 'right')

  , true

  return

#
#
#

game.getPlayerById = (id) ->

  for player in game.players
    if id is player.id
      player

#
#
#

game.updateGame = ->

  # Calculate players board occupation
  for player in game.players
    game.playerLost(player) if game.detectCollision(player.position, player.orientation)
    game.updatePlayer(player)

#
#
#

game.updateCamera = ->
  # Get player
  player = game.getPlayerById(0)[0]

  #playerX = player.position[0] * game.boardSpacing - (game.boardSpacing * game.boardWidth / 2)
  #playerY = player.position[1] * game.boardSpacing - (game.boardSpacing * game.boardHeight / 2)
  if player._rawPos
    playerX = player._rawPos[0]
    playerY = player._rawPos[1]

  # Computes camera position

  game.camera.position.y = 150
  game.camera.position.z = playerY - 100 * Math.cos(game.camAngle) - 100 * Math.sin(game.camAngle)
  game.camera.position.x = playerX + 100 * Math.sin(game.camAngle) - 100 * Math.cos(game.camAngle)

  # Calculate camera angle

  if player.orientation is 'right'
    desiredAngle = 0
  else if player.orientation is 'left' 
    desiredAngle = Math.PI
  else if player.orientation is 'down' 
    desiredAngle = Math.PI / 2
  else if player.orientation is 'up'
    desiredAngle = 3 * Math.PI / 2

  difference = Math.abs(desiredAngle - game.camAngle)

  # Select shortest way to rotate camera -> to be completed
  if difference < 2 * Math.PI - difference
    camStep = difference / game.camSmoothness
  else
    camStep = - (2 * Math.PI - difference) / game.camSmoothness

  # Go counter clockwise
  if desiredAngle - game.camAngle < 0
    camStep = - camStep

  if player._rawPos
    # Update game
    game.camera.lookAt(new THREE.Vector3(player._rawPos[0], 0, player._rawPos[1]))

  game.camAngle = (game.camAngle + camStep).mod(2 * Math.PI)

#
#
#

game.renderPlayer = (player) ->
  game.createPlayerObject(player)

#
# Get canvas env
#

game.getCanvas = ->
  #
  game.scene = new THREE.Scene()

  #
  game.camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000)

  #
  game.renderer = new THREE.WebGLRenderer()
  game.renderer.setSize(window.innerWidth, window.innerHeight)

  #
  document.body.appendChild(game.renderer.domElement)

  #
  geometry = new THREE.BoxGeometry game.boardWidth*game.boardSpacing, 0, game.boardHeight*game.boardSpacing
  material = new THREE.MeshBasicMaterial
    color: 0x000000

  game.floor = new THREE.Mesh geometry, material
  
  game.scene.add game.floor

  #
  # Build board lines
  #

  boardLineMaterial = new THREE.LineBasicMaterial
    color: 0x333333

  for colIndex in [0..game.boardWidth]

    geometry = new THREE.Geometry()

    geometry.vertices.push(
      new THREE.Vector3( game.boardSpacing*colIndex - (game.boardSpacing*game.boardWidth / 2) , 1, -(game.boardSpacing*game.boardHeight / 2)),
      new THREE.Vector3( game.boardSpacing*colIndex - (game.boardSpacing*game.boardWidth / 2), 1, (game.boardSpacing*game.boardHeight / 2) )
    )

    line = new THREE.Line geometry, boardLineMaterial
    game.scene.add line

  for rowIndex in [0..game.boardHeight]

    geometry = new THREE.Geometry()

    geometry.vertices.push(
      new THREE.Vector3( -(game.boardSpacing*game.boardWidth / 2) , 1, game.boardSpacing*rowIndex - (game.boardSpacing*game.boardHeight / 2)),
      new THREE.Vector3( (game.boardSpacing*game.boardWidth / 2), 1,  game.boardSpacing*rowIndex - (game.boardSpacing*game.boardHeight / 2))
    )

    line = new THREE.Line geometry, boardLineMaterial
    game.scene.add line

  #
  game.camera.position.z = 10
  game.camera.position.x = 0
  game.camera.position.y = 50

  game.camera.lookAt(new THREE.Vector3(0, 0, 0))

  #
  game.executeSequence()

  game.createPlayerObject(0)

#
#
#

game.createPlayerObject = (player) ->
  # Check player
  return if !player

  # global static
  geometry = new THREE.BoxGeometry game.boardSpacing, game.playerHeight, game.playerDepth
  material = new THREE.MeshBasicMaterial
    color: player.color

  obj = new THREE.Mesh geometry, material

  # Initialize object array
  if !player._object
    player._object = []


  # Set orientation
  if player.orientation is 'up' or player.orientation is 'down'
    # Rotate 90deg
    obj.rotateOnAxis new THREE.Vector3(0, 1, 0), Math.PI/2

  # Set current position
  obj.position.x = player.position[0] * game.boardSpacing - (game.boardWidth / 2) * game.boardSpacing
  obj.position.y = game.playerHeight / 2
  obj.position.z = player.position[1] * game.boardSpacing - (game.boardHeight / 2) * game.boardSpacing

  switch player.orientation
    when 'up'
      obj.position.z = obj.position.z + game.boardSpacing
      geometry.applyMatrix( new THREE.Matrix4().makeTranslation(game.boardSpacing / 2, 0, 0))
    when 'left'
      obj.position.x = obj.position.x + game.boardSpacing
      geometry.applyMatrix( new THREE.Matrix4().makeTranslation( -game.boardSpacing/2, 0, 0 ) )
    when 'right'
      obj.position.x = obj.position.x - game.boardSpacing
      geometry.applyMatrix( new THREE.Matrix4().makeTranslation( game.boardSpacing/2, 0, 0 ) )
    when 'down'
      obj.position.z = obj.position.z - game.boardSpacing
      geometry.applyMatrix( new THREE.Matrix4().makeTranslation(- game.boardSpacing/2, 0 , 0 ) )

  obj.scale.x = 0.000001

  # Create player object
  player._object.push obj

  # Add player object to scene
  game.scene.add obj

  animStep = 0

  orientation = player.orientation 

  playerAnim = window.setInterval ->


    animStep = animStep + 0.1

    obj.scale.x = animStep

    player._rawPos = [
      obj.position.x ,
      obj.position.z
    ]

    switch orientation
      when 'up'
        player._rawPos[1] -= animStep * game.boardSpacing
      when 'left'
        player._rawPos[0] -= animStep * game.boardSpacing
      when 'right'
        player._rawPos[0] += animStep * game.boardSpacing
      when 'down'
        player._rawPos[1] += animStep * game.boardSpacing


    console.log player._rawPos[0] + ' ' + player._rawPos[1]

    if animStep >= 0.99
      window.clearInterval playerAnim

  , game.gameInterval / 10

#
#
#

game.destroyPlayerObject = (player) ->
  # Check player
  return if !player

  #
  for obj in player._object
    game.scene.remove obj

#
#
#

game.executeSequence = ->
  #
  requestAnimationFrame(game.executeSequence);

  # Update camera realtime
  game.updateCamera()

  #
  game.renderer.render(game.scene, game.camera);

# Execute
game.initGame()