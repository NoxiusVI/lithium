## A simple class for items.

class_name Item2D extends NetworkRigidBody2D

# --|| SIGNALS ||--

## Signal called when the item gets used by a player.
signal used
## Signal called when the item gets equipped by a player.
signal equipped
## Signal called when the item is unequipped by a player.
signal unequipped

# --|| VARIABLES ||--

@export_group("Spring","spring")
## How far away should the item be held.
@export var springLength : float = 100.0
## How much should the item be offset along hold length.
@export var springOffset : float = 0.0
## The stifness of the spring for linear forces.
@export var springLinearStiffness : float = 16.0
## The damping of the spring for linear forces.
@export var springLinearDamping : float = 1.0
## The stifness of the spring for angular forces.
@export var springAngularStiffness : float = 24000.0
## The damping of the spring for angular forces.
@export var springAngularDamping : float = 600.0

@export_group("Nodes","node")
## The object that is enabled to highlight the item.
@export var nodeHighlight : Node2D
## The object responsible for detecting players.
@export var nodePickUpArea : Area2D
## The character that currently has this weapon equipped.
@export var nodeUser : NetworkCharacter2D

## A bool telling us if this item is highlighted.
var isHighlighted : bool = false

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	nodeHighlight.visible = isHighlighted
	var newSchema : NodeSerializer = NodeSerializer.new()
	newSchema.scene_tree = get_tree()
	$Synchronizer.set_schema({
		":nodeUser" : newSchema
	})

func _rollback_tick(_delta : float, _tick : int, _isFresh : bool) -> void:
	updateInteraction()
	changeHighlight(nodePickUpArea.get_overlapping_bodies().size() > 0 and not nodeUser)
	updatePhysics()

# --|| LOGIC FUNCTIONS ||--

func updateInteraction() -> void:
	if nodeUser:
		if not nodeUser.nodeInput.isItemInteracting: return
		unequip()
	else:
		for body : PhysicsBody2D in nodePickUpArea.get_overlapping_bodies():
			if nodeUser: return
			equip(body)

func updatePhysics() -> void:
	if not nodeUser: return
	var displacement : Vector3 = getDisplacement()
	var positionDisplacement : Vector2 = Vector2(displacement.x,displacement.y)
	var rotationDisplacement : float = displacement.z
	
	var force : Vector2 = springLinearStiffness * positionDisplacement - springLinearDamping * linear_velocity
	var torque : float = -springAngularStiffness * rotationDisplacement - springAngularDamping * angular_velocity
	
	applyTorque(self,torque)
	applyCentralForce(self, force)
	applyCentralForce(nodeUser, -force)

# --|| PHYSICS HELPER FUNCTIONS ||--

## Applies torque equal to [param value] to a specified physics body by [param body]
func applyTorque(body : PhysicsBody2D,value : float) -> void:
	if body is not RigidBody2D: return
	body.apply_torque(value)

## Applies a central force equal to [param force] to the physics body specified by [param body].
func applyCentralForce(body : PhysicsBody2D, force : Vector2) -> void:
	if body is not RigidBody2D: return
	body.apply_central_force(force)

## Returns the displacement value used by the spring-like simulation.
func getDisplacement() -> Vector3:
	var userInput : PlayerInput = nodeUser.nodeInput
	
	var targetDirection : Vector2 = userInput.aimPosition - nodeUser.global_position
	
	var tDirectionLength : float = clamp(targetDirection.length(),0,springLength) + springOffset
	var targetPosition : Vector2 = nodeUser.global_position + targetDirection.normalized()*tDirectionLength
	var positionDisplacement : Vector2 = targetPosition - global_position
	
	var targetRot : float = atan2(targetDirection.y,targetDirection.x)
	var currentRot : float = global_rotation
	
	var rotationDisplacement : float = angle_difference(targetRot,currentRot)
	
	return Vector3(positionDisplacement.x,positionDisplacement.y,rotationDisplacement)

# --|| ITEM HELPER FUNCTIONS ||--

## Call this function when you want to use the item.
func use() -> void:
	if not nodeUser: return
	used.emit()

## Call this function when you want to equip the item.
func equip(newUser : Node) -> void:
	if not (newUser is  NetworkCharacter2D): return
	if not newUser.nodeInput.isItemInteracting: return
	nodeUser = newUser
	equipped.emit()

## Call this function when you want to unequip the item.
func unequip() -> void:
	nodeUser = null
	unequipped.emit()

## Call this function when you want to change the state of the highlight
func changeHighlight(value : bool) -> void:
	isHighlighted = value
	nodeHighlight.visible = value
