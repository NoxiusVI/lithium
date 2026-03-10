extends MenuControl

# --|| VARIABLES ||--
@export_group("Menus","menu_")
## The menu we go to when we press the "Back" button.
@export var menu_ok : MenuControl

# --|| LOGIC FUNCTIONS ||--

func onOkPressed() -> void:
	closeMenu()
	menu_ok.openMenu()
