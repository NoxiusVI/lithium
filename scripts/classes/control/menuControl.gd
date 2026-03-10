## Handles smoothly tweening children control nodes in and out of frame when the menu is opened and closed.[br]
## To open and close the menu use [method openMenu] and [method closeMenu]

class_name MenuControl extends Control

# --|| VARIABLES ||--

@export_group("Nodes","node_")
## The node we focus on when the menu is opened.
@export var node_openFocus : Control

@export_group("Flags","flag_")
## If the menu is currently open.[br]
## Additionally plays open animation on scene launch if true.
@export var flag_isOpen : bool = false

## The array of elements we animate when we open and close our menus
var elements : Array[Control]
## The array of the elements original anchor offsets. X = Left, y = Right
var originalOffsets : Dictionary[Control,Vector2]
## The amount we offset the left and right anchors so that the elements are out of view.
var hAnchorOffset : float = 0.0

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	get_viewport().size_changed.connect(updateAnchorOffsets)
	
	updateAnchorOffsets()
	initElements()
	
	if flag_isOpen: openMenu()

# --|| INIT FUNCTIONS ||--
## Initializes [member elements] and [member originalOffsets].
func initElements() -> void:
	for child : Node in get_children():
		if child is not Control: continue
		elements.append(child)
		originalOffsets.set(child,Vector2(child.offset_left,child.offset_right))

# --|| LOGIC FUNCTIONS ||--

## Updates [member hAnchorOffset] that is used to offset the nodes in [member elements] array.
func updateAnchorOffsets() -> void:
	var viewportSize : Vector2 = get_viewport().size
	var hRatio : float = 1920.0/viewportSize.x
	var vRatio : float = 1080.0/viewportSize.y
	hAnchorOffset = 1920.0 * max(hRatio,vRatio)

## Opens the menu by tweening all the nodes in [member elements]
## one by one towards their original position from their offset position from the left of the screen.
func openMenu() -> void:
	resetElements(-hAnchorOffset)
	visible = true
	flag_isOpen = true
	
	var tweens : Array[Tween] = []
	
	for element : Control in elements:
		var originalOffset : Vector2 = originalOffsets.get(element,Vector2.ZERO)
		var tween : Tween = createTween(element,originalOffset)
		tweens.append(tween)
	
	for tween : Tween in tweens:
		tween.play()
		await tween.finished
	
	if node_openFocus: node_openFocus.grab_focus()

## Opens the menu by tweening all of the nodes in [member elements]
## at the same time towards their offset position to the right of the screen from their original position.
func closeMenu() -> void:
	var tweens : Array[Tween] = []
	
	for element : Control in elements:
		var originalOffset : Vector2 = originalOffsets.get(element,Vector2.ZERO)
		var tweenOffset : Vector2 = originalOffset + Vector2(hAnchorOffset, hAnchorOffset)
		var tween : Tween = createTween(element,tweenOffset)
		tweens.append(tween)
	
	var visTween : Tween = get_tree().create_tween()
	visTween.set_parallel(true)
	visTween.set_ease(Tween.EASE_OUT)
	visTween.set_trans(Tween.TRANS_CUBIC)
	visTween.tween_property(self, "visible", false, 0.25)
	visTween.tween_property(self,"flag_isOpen",false,0.25)
	tweens.append(visTween)
	
	for tween : Tween in tweens:
		tween.play()

# --|| HELPER FUNCTIONS ||--

## Creates a tween for [param element] with a anchor target of [param targetOffset]
func createTween(element : Control, targetOffset : Vector2) -> Tween:
	var tween : Tween = get_tree().create_tween()
	
	tween.stop()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(element, "offset_left", targetOffset.x, 0.25)
	tween.tween_property(element, "offset_right", targetOffset.y, 0.25)
	
	return tween

## Resets all the nodes in the [member elements] array to an anchor offset specified with [param hOffset]
func resetElements(hOffset : float) -> void:
	for element : Control in elements:
		var originalOffset : Vector2 = originalOffsets.get(element,Vector2.ZERO)
		var newOffset : Vector2 = originalOffset + Vector2(hOffset, hOffset)
		element.offset_left = newOffset.x
		element.offset_right = newOffset.y
