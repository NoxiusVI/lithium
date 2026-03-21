## A simple class for items.

class_name Item2D extends NetworkRigidBody2D

# --|| VARIABLES ||--

@export_group("Grip")
## The amount to offset the spring by.
@export var springOffset : float = 0.0

@export_group("Nodes","node")
## The synchronizer responsible for this node.
@export var nodeSynchronizer : RollbackSynchronizer
## The object that is enabled to highlight the item.
@export var nodeHighlight : Node2D

## A bool telling us if this item is equipped.
var isEquipped : bool = false
## A bool telling us if this item is highlighted.
var isHighlighted : bool = false
## The current user of this item.
var currentUser : NetworkCharacter2D

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	nodeHighlight.visible = isHighlighted
	NodeSerializer.scene_tree = get_tree()
	nodeSynchronizer.set_schema({
		":currentUser" : NodeSerializer.new()
	})

func _rollback_tick(_delta : float, _tick : int, _isFresh : bool) -> void:
	updateIsEquipped()
	updatePhysics()

# --|| LOGIC FUNCTIONS ||--

func updateIsEquipped() -> void:
	var players : Array[Node] = get_tree().get_nodes_in_group("player")
	
	isEquipped = false
	currentUser = null
	
	for player : Node in players:
		if not (player is NetworkCharacter2D): continue
		var playerItem : Item2D = player.nodeWeaponHandler.currentItem
		if playerItem != self: continue
		
		currentUser = player
		isEquipped = true
		return

## Call this function when you want to change the state of the highlight
func changeHighlight(value : bool) -> void:
	isHighlighted = value
	nodeHighlight.visible = value

func updatePhysics() -> void:
	if not currentUser: return
	if not currentUser.nodeWeaponHandler: return
	
	var springLinearStiffness : float = currentUser.nodeWeaponHandler.springLinearStiffness
	var springLinearDamping : float = currentUser.nodeWeaponHandler.springLinearDamping
	var springAngularStiffness : float = currentUser.nodeWeaponHandler.springAngularStiffness
	var springAngularDamping : float = currentUser.nodeWeaponHandler.springAngularDamping
	
	var displacement : Vector3 = getDisplacement()
	var positionDisplacement : Vector2 = Vector2(displacement.x,displacement.y)
	var rotationDisplacement : float = displacement.z
	
	var force : Vector2 = springLinearStiffness * positionDisplacement - springLinearDamping * linear_velocity
	var torque : float = -springAngularStiffness * rotationDisplacement - springAngularDamping * angular_velocity
	
	applyTorque(self,torque)
	applyCentralForce(self, force)
	applyCentralForce(currentUser, -force)

# --|| HELPER FUNCTIONS ||--


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
	if not currentUser: return Vector3.ZERO
	if not currentUser.nodeInput: return Vector3.ZERO
	if not currentUser.nodeWeaponHandler: return Vector3.ZERO
	
	var springLength : float = currentUser.nodeWeaponHandler.springLength
	var userInput : PlayerInput = currentUser.nodeInput
	
	var targetDirection : Vector2 = userInput.aimPosition - currentUser.global_position
	
	var tDirectionLength : float = clamp(targetDirection.length(),0,springLength + springOffset) - springOffset
	var targetPosition : Vector2 = currentUser.global_position + targetDirection.normalized()*tDirectionLength
	var positionDisplacement : Vector2 = targetPosition - global_position
	
	var targetRot : float = atan2(targetDirection.y,targetDirection.x)
	var currentRot : float = global_rotation
	
	var rotationDisplacement : float = angle_difference(targetRot,currentRot)
	
	return Vector3(positionDisplacement.x,positionDisplacement.y,rotationDisplacement)
