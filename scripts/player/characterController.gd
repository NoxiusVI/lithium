extends NetworkRigidBody2D

# --|| VARIABLES ||--
@export_group("Acceleration","acceleration")
## What is the maximum speed possible through acceleration.
@export var accelerationCeiling : float = 1000.0
## How fast we accelerate towards our move direction.
@export var accelerationSpeed : float = 10000.0
## How fast we accelerate torque while moving.
@export var accelerationTorque : float = 144000.0

@export_group("Jump","jump")
## The force of a jump.
@export var jumpImpulse : float = 1000.0
## The amount of seconds we remember the jump input.
@export var jumpBuffer : int = 12
## The amount of seconds we allow a jump for after we've left the ground.
@export var jumpCoyote : int = 12

@export_group("Nodes","node")
## The node we get our input from.
@export var nodeInput : PlayerInput 
## The node that is responsible for synchronizing.
@export var nodeSynchronizer : RollbackSynchronizer

# How many ticks of jump buffering we have left.
var jumpBufferRemaining : int = 0
# How many ticks of coyote time we have left.
var coyoteTimeRemaining : int = 0
# If we have already jumped. If we have, we will require the release of the jump key.
var jumpAlreadyPressed : bool = false
var hasJumped : bool = false

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	setSchemas()

func _rollback_tick(delta : float, _tick : int,_isFresh : bool) -> void:
	accelerate(delta)
	jump()

# --|| LOGIC FUNCTIONS ||--

func setSchemas() -> void:
	var newNodeSerializer : NodeSerializer = NodeSerializer.new()
	newNodeSerializer.scene_tree = get_tree()
	
	nodeSynchronizer.set_schema({
		"Grip:item" : newNodeSerializer
	})

func jump() -> void:
	jumpBufferRemaining = max(jumpBufferRemaining - 1, 0)
	coyoteTimeRemaining = max(coyoteTimeRemaining -1, 0)
	
	if nodeInput.movement.y < 0.0:
		if not jumpAlreadyPressed: jumpBufferRemaining = jumpBuffer
		jumpAlreadyPressed = true
	else:
		jumpAlreadyPressed = false
	
	if get_contact_count() > 0:
		coyoteTimeRemaining = jumpCoyote
	
	if jumpBufferRemaining <= 0: return
	if coyoteTimeRemaining <= 0: return
	
	linear_velocity.y = -jumpImpulse
	jumpBufferRemaining = 0

func accelerate(delta : float) -> void:
	if is_zero_approx(nodeInput.movement.x): return
	
	var curSpeed : float = linear_velocity.x
	var wishSpeed : float = nodeInput.movement.x * accelerationCeiling
	var deltaSpeed : float = wishSpeed - curSpeed
	var impulse : float = clamp(deltaSpeed,-accelerationSpeed*delta,accelerationSpeed*delta)
	var torque : float = 0.0
	
	if impulse < 0.0: torque = -accelerationTorque
	elif impulse > 0.0: torque = accelerationTorque
	
	apply_central_impulse(Vector2(impulse, 0.0))
	apply_torque(torque)
