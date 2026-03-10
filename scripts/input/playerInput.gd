extends BaseNetInput
class_name PlayerInput

# --|| VARIABLES ||--

@export_category("Input")
## The vector2 that represents the movement input of the player.
@export var movement : Vector2
## Aim Position. Used for well... aiming.
@export var aimPosition : Vector2

# The amount of movement we accumulated.
var accumulatedMovement : Vector2 = Vector2.ZERO
# The amount of times we have accumulated input.
var accumulationCount : int = 0

# --|| MAIN FUNCTIONS ||--

func _process(_delta : float) -> void:
	if not is_multiplayer_authority(): return
	updateAccumulators()

func _gather() -> void:
	if not is_multiplayer_authority(): return
	setLatches()
	setAccumulators()

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	updateLatches(event)

# --|| LOGIC FUNCTIONS ||--

func setLatches() -> void:
	pass

func setAccumulators() -> void:
	accumulationCount += 1
	
	var newMovement : Vector2 = Input.get_vector("move_left","move_right","move_up","move_down") + accumulatedMovement
	movement = newMovement / accumulationCount
	
	accumulatedMovement = Vector2.ZERO
	accumulationCount = 0

func updateLatches(_event : InputEvent) -> void:
	pass

func updateAccumulators() -> void:
	accumulationCount += 1
	accumulatedMovement += Input.get_vector("move_left","move_right","move_up","move_down")
