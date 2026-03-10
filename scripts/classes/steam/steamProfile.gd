extends Node

# --|| VARIABLES ||--

## The id of our user.
var id : int = -1
## A bool that marks if we successfully initialized.
var initialized : bool = false

# --|| MAIN FUNCTIONS ||--
#
func _ready() -> void:
	var initResults : Dictionary = Steam.get_steam_init_result()
	if initResults.get("status") != Steam.STEAM_API_INIT_RESULT_OK: return
	
	id = Steam.getSteamID() 
	initialized = true

func _process(_delta: float) -> void:
	updateCallbacks()

# --|| LOGIC FUNCTIONS ||--

## If we are initialized, we run steam callbacks.
func updateCallbacks() -> void:
	if not initialized: return
	Steam.run_callbacks()
