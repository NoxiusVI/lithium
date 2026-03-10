extends RigidBody2D

# --|| VARIABLES ||--

@export_group("Settings","setting_")
## The amount of pixels to move us forward, so that we don't hit the player.
@export var setting_forwardOffset : float = 0.0
@export_group("Nodes","node_")
## The synchronizer of this node. We only need it so we can remove it if we are a ghost.
@export var node_synchronizer : MultiplayerSynchronizer
## The authorizer of this node. Used to hand back the ownership of this scene when we are done with it.
@export var node_authorizer : Authorizer
## The trail of this node. Used to prevent visual bugs.
@export var node_trail : Trail2D
@export_group("Local","local_")
## Used to sync linear velocity between clients, since Syncing directly will cause issues.
@export var local_linearVelocity : Vector2 = Vector2.ZERO
## Used to sync angular velocity between clients, since Syncing directly will cause issues.
@export var local_angularVelocity : float = 0.0
## Used to sync position between clients, since Syncing directly will cause issues.
@export var local_position : Vector2 = Vector2.ZERO
## Used to sync rotation between clients, since Syncing directly will cause issues.
@export var local_rotation : float = 0.0

var isGhost : bool = false

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	global_position += linear_velocity.normalized() * setting_forwardOffset
	if "GHOST" in name: 
		isGhost = true 
		node_synchronizer.queue_free()
	elif not multiplayer.is_server(): overwriteGhost.call_deferred()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_multiplayer_authority(): updateOwner(state)
	else: updateViewer(state)

# --|| LOGIC FUNCTIONS ||--

func overwriteGhost() -> void:
	var myGhost : Node = get_tree().root.get_node_or_null("Game/GhostObjects/" + "GHOST_" + name)
	if not myGhost:
		node_authorizer.assignAuthority(1)
		deleteSelf.rpc()
		return
	
	set_deferred("global_transform",myGhost.global_transform)
	set_deferred("linear_velocity",myGhost.linear_velocity)
	set_deferred("angular_velocity",myGhost.angular_velocity)
	node_trail.set("points",myGhost.node_trail.points)
	node_trail.set("pointBirthTimes",myGhost.node_trail.pointBirthTimes)
	myGhost.queue_free()

func updateViewer(state : PhysicsDirectBodyState2D) -> void:
	state.linear_velocity = local_linearVelocity
	state.angular_velocity = local_angularVelocity
	position = local_position
	rotation = local_rotation

func updateOwner(state : PhysicsDirectBodyState2D) -> void:
	local_linearVelocity = state.linear_velocity
	local_angularVelocity = state.angular_velocity
	local_position = position
	local_rotation = rotation
	#node_trail.flag_enabled = true

func onHit(body : Node) -> void:
	if isGhost:
		queue_free()
	else:
		node_authorizer.assignAuthority(1)
		deleteSelf.rpc()

@rpc("any_peer","call_local")
func deleteSelf() -> void:
	var senderId : int = multiplayer.get_remote_sender_id()
	
	if senderId != get_multiplayer_authority(): return
	if not multiplayer.is_server(): return
	
	#freeze = true
	#await get_tree().create_timer(0.2).timeout
	queue_free()

# --|| CONNECTED FUNCTIONS ||--

func onBulletBodyEntered(body: Node) -> void:
	if not is_multiplayer_authority(): return
	onHit(body)
	
