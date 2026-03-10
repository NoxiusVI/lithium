extends MenuControl

# --|| VARIABLES ||--
@export_group("Prefabs","prefab_")
## The scene that is instantiated to represent a single lobby.
@export var prefab_lobbyBar : PackedScene
@export_group("Nodes","node_")
## The node responsible for searching by name.
@export var node_nameSearch : LineEdit
## The node that has lobby bars added to it.
@export var node_lobbyHolder : Control
@export_group("Menus","menu_")
## The menu we go to when we press the "Back" button.
@export var menu_back : MenuControl
## The menu we go to when we fail to join a lobby.
@export var menu_joinFail : MenuControl

# --|| MAIN FUNCTIONS ||--
func _ready() -> void:
	super._ready()
	LobbyManager.lobbyListReturned.connect(newServerList)

# --|| LOGIC FUNCTIONS ||--
func openMenu() -> void:
	super.openMenu()
	LobbyManager.getLobbyList("")

func newServerList(lobbies : Array) -> void:
	print(lobbies)
	
	for lobbyBars : Node in node_lobbyHolder.get_children():
		lobbyBars.queue_free()
	
	for thisLobbyId : int in lobbies:
		var lobbyBar : Node = prefab_lobbyBar.instantiate()
		if lobbyBar.has_method("initLobbyBar"): lobbyBar.initLobbyBar(thisLobbyId)
		node_lobbyHolder.add_child(lobbyBar)

func onBackPressed() -> void:
	closeMenu()
	menu_back.openMenu()

func onRefreshPressed() -> void:
	LobbyManager.getLobbyList(node_nameSearch.text)
