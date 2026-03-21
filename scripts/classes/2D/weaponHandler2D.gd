## Handles weapon interactions (picking up and dropping) and also holds the values of the spring.

class_name WeaponHandler2D extends Area2D

# --|| VARIABLES ||--

@export_group("Settings")
## For how many ticks should we buffer interacting.
@export var interactBuffer : int = 12

@export_group("Spring","spring")
## How far away should the item be held.
@export var springLength : float = 100.0
## The stifness of the spring for linear forces.
@export var springLinearStiffness : float = 16.0
## The damping of the spring for linear forces.
@export var springLinearDamping : float = 1.0
## The stifness of the spring for angular forces.
@export var springAngularStiffness : float = 24000.0
## The damping of the spring for angular forces.
@export var springAngularDamping : float = 600.0

@export_group("Nodes","node")
## The input responsible for this weapon handler.
@export var nodeInput : PlayerInput
## The current item we are holding.
@export var currentItem : Item2D

## The item that is currently being highlighted.
var highlightedItem : Item2D
## How many interaction ticks we have left.
var interactTicksLeft : int = 0

# --|| MAIN FUNCTIONS ||--

func _rollback_tick(_delta : float, _tick : int, _isFresh : bool) -> void:
	updateHighlights()
	updateInteraction()

# --|| LOGIC FUNCTIONS ||--

## Highlights the item that we can pick up.
func updateHighlights() -> void:
	var selectedItem : Item2D
	var currentDistance : float = INF
	
	for item : Node2D in get_overlapping_bodies():
		if not (item is Item2D): continue
		if item.isEquipped: continue
		var distanceBetween : float = global_position.distance_squared_to(item.global_position)
		if distanceBetween > currentDistance: continue
		selectedItem = item
		currentDistance = distanceBetween
	
	if highlightedItem: highlightedItem.changeHighlight(false)
	if selectedItem: selectedItem.changeHighlight(true)
	highlightedItem = selectedItem

## Updates everything related to interacting (Picking up and dropping) with items.
func updateInteraction() -> void:
	interactTicksLeft = max(interactTicksLeft - 1, 0)
	
	if nodeInput.isItemInteracting: interactTicksLeft = interactBuffer
	if not highlightedItem and not currentItem: return
	if interactTicksLeft <= 0: return
	currentItem = highlightedItem
	interactTicksLeft = 0
