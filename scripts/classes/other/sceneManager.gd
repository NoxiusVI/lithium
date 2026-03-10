## Handles transitioning between scenes.

extends Node

# --|| VARIABLES ||--

# --|| LOGIC FUNCTIONS ||--

## Go to the scene specified by [param scene]
func goToScene(scene : PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
