## This class handles item input and stores them in exported variables.

class_name ItemInput extends BaseNetInput

@export_group("Input")
## A bool telling us if the item is currently in use.
@export var isUsing : bool = false
@export_group("Nodes")
## The item itself the input is controlling.
@export var item : Item2D

func _gather() -> void:
	isUsing = item.currentUser.nodeInput.isAttacking if item.currentUser else false
