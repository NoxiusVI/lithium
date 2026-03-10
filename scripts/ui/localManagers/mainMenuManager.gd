extends CanvasLayer

# --|| VARIABLES ||--
@export_group("Menus","menu_")
## The menu we open when nothing special happens.
@export var menu_startMenu : MenuControl
## The menu we open when we get an error.
@export var menu_errorMenu : MenuControl

# --|| MAIN FUNCTIONS ||--
func _ready() -> void:
	var errorString : String = ErrorManager.handlePendingError()
	if errorString.is_empty():
		menu_startMenu.openMenu()
		return
	
	menu_errorMenu.openMenu()
	var windowCtrl : Control = menu_errorMenu.get_node_or_null("Window")
	if not windowCtrl: return
	var label : Label = windowCtrl.get_node_or_null("Label")
	if not label: return
	label.text = errorString
