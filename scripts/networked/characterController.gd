extends NetworkRigidBody2D

# --|| VARIABLES ||--
@export_group("Acceleration","acceleration_")
## What is the maximum speed possible through acceleration.
@export var acceleration_ceiling : float = 1000.0
## How fast we accelerate towards our move direction.
@export var acceleration_speed : float = 10000.0
## How fast we accelerate torque while moving.
@export var acceleration_torque : float = 144000.0

@export_group("Jump","jump_")
## The force of a jump.
@export var jump_impulse : float = 1000.0
## The amount of seconds we remember the jump input.
@export var jump_buffer : int = 12
## The amount of seconds we allow a jump for after we've left the ground.
@export var jump_coyote : int = 12

@export_group("Nodes","node_")
## The node we get our input from.
@export var node_input : PlayerInput

# How many ticks of jump buffering we have left.
var jumpBufferRemaining : int = 0
# How many ticks of coyote time we have left.
var coyoteTimeRemaining : int = 0
# If we have already jumped. If we have, we will require the release of the jump key.
var jumpAlreadyPressed : bool = false
var hasJumped : bool = false

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	pass

func _rollback_tick(delta : float, tick : int,is_fresh : bool) -> void:
	accelerate(delta)
	jump(tick)

# --|| LOGIC FUNCTIONS ||--

func jump(tick : int) -> void:
	jumpBufferRemaining = max(jumpBufferRemaining - 1, 0)
	coyoteTimeRemaining = max(coyoteTimeRemaining -1, 0)
	
	if node_input.movement.y < 0.0:
		if not jumpAlreadyPressed: jumpBufferRemaining = jump_buffer
		jumpAlreadyPressed = true
	else:
		jumpAlreadyPressed = false
	
	if get_contact_count() > 0:
		coyoteTimeRemaining = jump_coyote
	
	if jumpBufferRemaining <= 0: return
	if coyoteTimeRemaining <= 0: return
	
	var jumpVelocity : Vector2 = Vector2.ZERO
	
	linear_velocity.y = -jump_impulse
	jumpBufferRemaining = 0

func accelerate(delta : float) -> void:
	if is_zero_approx(node_input.movement.x): return
	
	var curSpeed : float = linear_velocity.x
	var wishSpeed : float = node_input.movement.x * acceleration_ceiling
	var deltaSpeed : float = wishSpeed - curSpeed
	var impulse : float = clamp(deltaSpeed,-acceleration_speed*delta,acceleration_speed*delta)
	var torque : float = 0.0
	
	if impulse < 0.0: torque = -acceleration_torque
	elif impulse > 0.0: torque = acceleration_torque
	torque *= delta
	
	apply_central_impulse(Vector2(impulse, 0.0) * mass)
	apply_torque_impulse(torque * mass)
