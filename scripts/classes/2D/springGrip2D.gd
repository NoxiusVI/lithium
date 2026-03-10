## Attempts to move a given physics body to [member targetPosition] position using spring-like forces.
class_name SpringGrip2D extends Node2D

# --|| VARIABLES ||--

## A local offset to our target position.
@export var targetPosition : Vector2 = Vector2.ZERO
## The stifness constant used in our force calculations.
@export var stiffness : float = 16.0
## The damping constant used in our force calculations.
@export var damping : float = 1.0
@export_group("Bodies","body")
## The first body (A) that is used as the center of the force calculations.
@export var holder : PhysicsBody2D
## The second body (B) that is moved towards the target position.
@export var item : PhysicsBody2D
@export_group("Flags","flag")
## If we should automatically update the spring.
@export var flagAutoUpdate : bool = true

# --|| MAIN FUNCTIONS ||--

func _physics_process(_delta: float) -> void:
	if not flagAutoUpdate: return
	update()

# --|| LOGIC FUNCTIONS ||--

func update() -> void:
	if not holder or not item: return
	
	var force : Vector2 = -stiffness * getDisplacement() - damping * getVelocity()
	applyForce(holder, -force)
	applyForce(item, force)

# --|| HELPER FUNCTIONS ||--
## Applies a central force equal to [param force] to the physics body specified by [param body].
func applyForce(body : PhysicsBody2D, force : Vector2) -> void:
	if body is not RigidBody2D: return
	body.apply_central_force(force)

## Returns the displacement value used by the spring-like simulation.
func getDisplacement() -> Vector2:
	var originVector : Vector2 = holder.global_position + targetPosition.rotated(holder.global_rotation)
	return item.global_position - originVector

## Returns the velocity of [member item]
func getVelocity() -> Vector2:
	return item.linear_velocity if item is RigidBody2D else Vector2.ZERO
