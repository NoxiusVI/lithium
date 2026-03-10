## A simple class for items.

class_name Item2D extends NetworkRigidBody2D

# --|| SIGNALS ||--

## Signal called when the item gets used by a player.
signal used
## Signal called when the item gets equipped by a player.
signal equipped
## Signal called when the item is unequipped by a player.
signal unequipped
## Signal called when the item's highlight state changes.
signal highlightChanged (value : bool)

# --|| VARIABLES ||--

@export var highlightObject : Node2D

## A bool to tell us if the item is already equipped.
var isEquipped : bool = false
## A bool telling us if this item is highlighted.
var isHighlighted : int = 0

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	highlightObject.visible = isHighlighted

# --|| LOGIC FUNCTIONS ||--

## Call this function when you want to use the item.
func use() -> void:
	if not isEquipped: return
	used.emit()

## Call this function when you want to equip the item.
func equip() -> void:
	if isEquipped: return
	isEquipped = true
	equipped.emit()

## Call this function when you want to unequip the item.
func unequip() -> void:
	if not isEquipped: return
	isEquipped = false
	unequipped.emit()

## Call this function when you want to change the state of the highlight
func changeHighlight(value : bool) -> void:
	isHighlighted = value
	highlightObject.visible = value
	highlightChanged.emit(value)
