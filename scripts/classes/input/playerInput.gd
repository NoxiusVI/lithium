## This class handles player input and stores them in exported variables.

class_name PlayerInput extends BaseNetInput

# --|| VARIABLES ||--

@export_category("Input")
## The vector2 that represents the movement input of the player.
@export var movement : Vector2 = Vector2.ZERO
## Aim Position. Used for well... aiming.
@export var aimPosition : Vector2 = Vector2.ZERO
## A bool telling us if we are attacking.
@export var isAttacking : bool = false
## A bool telling us if we are trying to interact with an item.
@export var isItemInteracting : bool = false

## The amount of movement we accumulated.
var accumulatedMovement : Vector2 = Vector2.ZERO
## The amount of times we have accumulated input.
var accumulationCount : int = 0
## If we are attacking. Used for continual attacking.
var localAttacking : bool = false
## A latch for the attack input. Used for one off attacks.
var latchedAttacking : bool = false
## A latch for the item interact input.
var latchedItemInteracting : bool = false
# --|| MAIN FUNCTIONS ||--

func _process(_delta : float) -> void:
	if not is_multiplayer_authority(): return
	updateAccumulators()

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	updateLatches(event)
	updateOthers(event)

func _gather() -> void:
	if not is_multiplayer_authority(): return
	setLatches()
	setAccumulators()
	setOthers()

# --|| LOGIC FUNCTIONS ||--

## Finalizes latching inputs.
func setLatches() -> void:
	isAttacking = latchedAttacking or localAttacking
	latchedAttacking = false
	
	isItemInteracting = latchedItemInteracting
	latchedItemInteracting = false

## Finalizes accumulating inputs.
func setAccumulators() -> void:
	if get_viewport().gui_get_focus_owner() == null:
		updateAccumulators()
	
	if accumulationCount == 0:
		movement = Vector2.ZERO
		return
	
	movement = accumulatedMovement / accumulationCount
	
	accumulatedMovement = Vector2.ZERO
	accumulationCount = 0

func setOthers() -> void:
	var viewport : Viewport = get_viewport()
	var viewportTrans : Transform2D = viewport.get_canvas_transform()
	var localMousePos : Vector2 = viewport.get_mouse_position()
	aimPosition = viewportTrans.affine_inverse() * localMousePos

## Updates latching inputs.
func updateLatches(event : InputEvent) -> void:
	if event.is_action_pressed("weapon_attack"): latchedAttacking = true
	if event.is_action_pressed("weapon_interact"): latchedItemInteracting = true

## Updates accumulating inputs.
func updateAccumulators() -> void:
	if get_viewport().gui_get_focus_owner() != null: return
	
	accumulationCount += 1
	accumulatedMovement += Input.get_vector("move_left","move_right","move_up","move_down")

func updateOthers(event : InputEvent) -> void:
	if event.is_action_pressed("weapon_attack"):
		localAttacking = true
	elif event.is_action_released("weapon_attack"):
		localAttacking = false
