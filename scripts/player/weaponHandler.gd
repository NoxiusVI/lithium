## A script that handles updating the SpringGrip2D while also pointing item towards the mouse.

extends SpringGrip2D

@export_group("Settings")
## The length at which we hold the weapon.
@export var gripLength : float = 100.0
## The stiffness constant used in our torque calculations.
@export var torqueStiffness : float = 240.0
## The damping constant used in our torque calculations.
@export var torqueDamping : float = 10.0
@export_group("Nodes","node")
## The node responsible for authorizing. Used for getting if we are a local.
@export var nodeAuthorizer : Authorizer
## The node responsible for input.
@export var nodeInput : PlayerInput
## The node responsible for checking the area for items.
@export var nodeEquipCast : ShapeCast2D

## The list of all available items to pick up.
var pickUpList : Array[Item2D]
## The currently highlighted item, that is ready to be picked up.
var highlightedItem : Item2D

# --|| MAIN FUNCTIONS ||--

func _rollback_tick(_delta : float, _tick : int, _isFresh : bool) -> void:
	updateArea()
	updateHighlights()
	pickUpItem()
	update()

# --|| LOGIC FUNCTIONS ||--

func updateArea() -> void:
	pickUpList = []
	nodeEquipCast.force_shapecast_update()
	for i : int in range(nodeEquipCast.get_collision_count()):
		var node : CollisionObject2D = nodeEquipCast.get_collider(i)
		if not (node is Item2D): continue
		pickUpList.append(node)

func updateHighlights() -> void:
	var candidate : Item2D
	var prevCandidate : Item2D = highlightedItem
	var distance : float = INF
	
	#highlightedItem = null
	
	for thisItem in pickUpList:
		if thisItem.isEquipped: continue
		var distToItem : float = global_position.distance_to(thisItem.global_position)
		if distToItem < distance:
			distance = distToItem
			candidate = thisItem
	
	highlightedItem = candidate
	if (candidate == prevCandidate): return
	if nodeAuthorizer.peerId != multiplayer.get_unique_id(): return
	if prevCandidate:	prevCandidate.changeHighlight(false)
	if candidate:	candidate.changeHighlight(true)

func update() -> void:
	if not holder or not item: return
	var targetDelta : Vector2 = (nodeInput.aimPosition - global_position)
	var targetMagnitude : float = clamp(targetDelta.length(), 0, gripLength)
	var targetVector : Vector2 = targetDelta.normalized() * targetMagnitude
	targetPosition = targetVector.rotated(-global_rotation)
	
	var torqueForce : float = -torqueStiffness * getTorqueDisplacement() - torqueDamping * getTorque(item)
	
	applyTorque(item,torqueForce)
	
	super.update()

func pickUpItem() -> void:
	if not nodeInput.isItemInteracting: return
	if not highlightedItem and not item: return
	if highlightedItem == item: return
	equipItem()

func equipItem() -> void:
	if item: item.unequip()
	if highlightedItem: highlightedItem.equip()
	item = highlightedItem

## Adds [param node] to the pick up list.
func addItemToPickUp(node : Node2D) -> void:
	if node is not Item2D: return
	if node in pickUpList: return
	pickUpList.append(node)

## Removes [param item] from the pick up list.
func removeItemFromPickUp(node : Node2D) -> void:
	if node is not Item2D: return
	if node not in pickUpList: return
	pickUpList.remove_at(pickUpList.find(node))

# --|| HELPER FUNCTIONS ||--

## Returns the displacement between [member item]'s rotation and [member nodeInput]'s aim position.
func getTorqueDisplacement() -> float:
	var targetDirection : Vector2 = (nodeInput.aimPosition - global_position)
	var targetRot : float = atan2(targetDirection.y,targetDirection.x)
	var currentRot : float = item.global_rotation
	return angle_difference(targetRot,currentRot)

## Returns angular_velocity of a specified physics body by [param body]
func getTorque(body : PhysicsBody2D) -> float:
	if body is not RigidBody2D: return 0.0
	return body.angular_velocity

## Applies torque equal to [param value] to a specified physics body by [param body]
func applyTorque(body : PhysicsBody2D,value : float) -> void:
	if body is not RigidBody2D: return
	body.apply_torque(value)
