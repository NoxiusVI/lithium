## I needed a class for this ok? Fuck off.

class_name NetworkCharacter2D extends NetworkRigidBody2D

# --|| VARIABLES ||--
@export_group("Acceleration","acceleration")
## What is the maximum speed possible through acceleration.
@export var accelerationLinearCeiling : float = 1000.0
## How fast we accelerate towards our move direction.
@export var accelerationLinearForce : float = 10000.0
## What is the maximum torque possible through acceleration.
@export var accelerationAngularCeiling : float = 12.0
## How fast we accelerate towards our spin direction.
@export var accelerationAngularForce : float = 240000.0

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

## How many ticks of jump buffering we have left.
var jumpBufferRemaining : int = 0
## How many ticks of coyote time we have left.
var coyoteTimeRemaining : int = 0
## If we have already jumped. If we have, we will require the release of the jump key.
var jumpAlreadyPressed : bool = false

# --|| MAIN FUNCTIONS ||--

func _rollback_tick(_delta : float, _tick : int,_isFresh : bool) -> void:
	accelerate()
	jump()

# --|| LOGIC FUNCTIONS ||--

## Handles jumping. Meant to be ran every tick.
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

## Handles acceleration in general. Meant to be ran every tick.
func accelerate() -> void:
	if is_zero_approx(nodeInput.movement.x): return
	linearAccelerate()
	angularAccelerate()

## Handles linear acceleration. Meant to be ran every tick.
func linearAccelerate() -> void:
	var targetLinearVel : float = nodeInput.movement.x * accelerationLinearCeiling
	var currentLinearVel : float = linear_velocity.x
	var wishLinearForce : float = nodeInput.movement.x * accelerationLinearForce
	
	var linearIsOpposite : bool = sign(targetLinearVel) != sign(currentLinearVel)
	var linearIsBelowCeiling : bool = abs(currentLinearVel) < accelerationLinearCeiling
	
	if linearIsOpposite or linearIsBelowCeiling:
		apply_central_force(Vector2(wishLinearForce, 0.0))

## Handles angular acceleration. Meant to be ran every tick.
func angularAccelerate() -> void:
	var targetAngularVel : float = nodeInput.movement.x * accelerationAngularCeiling
	var currentAngularVel : float = angular_velocity
	var wishAngularForce : float = nodeInput.movement.x * accelerationAngularForce
	
	var torqueIsOpposite : bool = sign(targetAngularVel) != sign(currentAngularVel)
	var torqueIsBelowCeiling : bool = abs(currentAngularVel) < accelerationAngularCeiling
	
	if torqueIsOpposite or torqueIsBelowCeiling:
		apply_torque(wishAngularForce)
