extends MenuControl

# --|| VARIABLES ||--
@export_group("Scenes","scene_")
## The scene we load into when we successfully host.
@export var scene_mainScene : PackedScene
@export_group("Nodes","node_")
## The node responsible for naming the lobby.
@export var node_nameInput : LineEdit
## The node responsible for setting the visibility of the lobby.
@export var node_visibilityInput : OptionButton
@export_group("Menus","menu_")
## The menu we go to when we press the "Back" button.
@export var menu_back : MenuControl

# --|| MAIN FUNCTIONS ||--
func _ready() -> void:
	super._ready()
	LobbyManager.createdLobby.connect(onLobbyCreated)

# --|| LOGIC FUNCTIONS ||--
func onLobbyCreated(lobbyId : int) -> void:
	Steam.setLobbyData(lobbyId,"name",node_nameInput.text)

func onStartPressed() -> void:
	if node_nameInput.text == "": return
	
	var visibility : int = Steam.LOBBY_TYPE_PRIVATE
	if node_visibilityInput.selected == 1:
		visibility = Steam.LOBBY_TYPE_PUBLIC
		
	LobbyManager.createLobby(visibility)

func onBackPressed() -> void:
	closeMenu()
	menu_back.openMenu()
