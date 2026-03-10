extends MultiplayerSpawner

@export_group("Scenes","scene_")
## The scene of the player.
@export var scene_player : PackedScene

# --|| MAIN FUNCTIONS ||--

func _init() -> void:
	set_multiplayer_authority(1)

func _ready() -> void:
	spawn_function = customSpawn
	
	if not multiplayer.is_server(): return
	
	serverCreated()
	multiplayer.peer_connected.connect(playerJoined)
	LobbyManager.leftLobby.connect(leftLobby)

# --|| LOGIC FUNCTIONS ||--

func customSpawn(id : int) -> Node:
	var newPlayer : Node = scene_player.instantiate()
	newPlayer.global_position = Vector2(0,-250)
	newPlayer.name = str(id)
	var authorityNode : Node = newPlayer.get_node_or_null("Authorizer")
	if authorityNode:	authorityNode.assignAuthority.call_deferred(id)
	return newPlayer

func playerJoined(id : int) -> void:
	spawn(id)

func serverCreated() -> void:
	if not multiplayer.is_server(): return
	spawn(1)

func leftLobby() -> void:
	for player : Node in get_node(spawn_path).get_children():
		player.queue_free()
