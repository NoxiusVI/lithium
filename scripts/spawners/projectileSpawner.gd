extends MultiplayerSpawner

@export_group("Scenes","scene_")
## The scene of the player.
@export var scene_bullet : PackedScene

# --|| MAIN FUNCTIONS ||--

func _init() -> void:
	set_multiplayer_authority(1)

func _ready() -> void:
	SpawnerRegistry.bulletSpawner = self
	
	spawn_function = customSpawn
	
	if not multiplayer.is_server(): return
	
	LobbyManager.leftLobby.connect(leftLobby)

# --|| LOGIC FUNCTIONS ||--

func customSpawn(data : Dictionary) -> Node:
	var id : int = data.get("id")
	var num : int = data.get("num")
	var transform : Transform2D = data.get("transform")
	var velocity : Vector2 = data.get("velocity")
	var newBullet : Node = scene_bullet.instantiate()
	
	newBullet.linear_velocity = velocity
	newBullet.global_transform = transform
	newBullet.name = str(id) + "_" + str(num)
	
	var authorityNode : Node = newBullet.get_node_or_null("Authorizer")
	if authorityNode: authorityNode.assignAuthority.call_deferred(id)
	
	return newBullet

func leftLobby() -> void:
	for bullet : Node in get_node(spawn_path).get_children():
		bullet.queue_free()
