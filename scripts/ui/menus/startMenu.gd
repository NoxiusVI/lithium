extends MenuControl

# --|| VARIABLES ||--
@export_group("Menus","menu_")
## The menu we go to when we press the "Host" button.
@export var menu_host : MenuControl
## The menu we go to when we press the "Lobby Browser" button.
@export var menu_lobbyBrowser : MenuControl

# --|| LOGIC FUNCTIONS ||--
func onHostPressed() -> void:
	if NetworkManager.USE_ENET:
		NetworkManager.createHost()
		return
	closeMenu()
	menu_host.openMenu()

func onLobbyBrowserPressed() -> void:
	if NetworkManager.USE_ENET:
		NetworkManager.createClient(0)
		return
	closeMenu()
	menu_lobbyBrowser.openMenu()
