extends Node

# --|| VARIABLES ||--

# The newest error to happen that needs to be displayed.
var pendingError : String = ""
# The main menu scene. We go to this scene when handling multiplayer errors.
var scene_mainMenu : PackedScene = load("res://objects/scenes/main/mainMenu.tscn")

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	LobbyManager.failedToJoinLobby.connect(onFailedToJoinLobby)

# --|| LOGIC FUNCTIONS ||--

## Function called when something wants to handle an error.
func handlePendingError() -> String:
	if pendingError.is_empty(): return ""
	var returnableError : String = pendingError
	pendingError = ""
	return returnableError

## When we fail to join lobby. (Wow, such unexpecteds)
func onFailedToJoinLobby(errorMessage : String) -> void:
	pendingError = errorMessage
	SceneManager.goToScene(scene_mainMenu)
