## Class responsible for visualizing pellets.

class_name Pellets2D extends Node2D

## Call this function to visualize pellets.
func visualizePellets(lifetime : float, origins : Array[Vector2],endPoints : Array[Vector2], gradient : GradientTexture2D) -> void:
	if origins.size() != endPoints.size(): return
	
	for index : int in range(origins.size()):
		var origin : Vector2 = origins[index]
		var end : Vector2 = endPoints[index]
		createPellet(origin,end,gradient)
	
	var newTimer : Timer = Timer.new()
	newTimer.one_shot = true
	newTimer.autostart = true
	newTimer.wait_time = lifetime
	newTimer.timeout.connect(timerTimeout,CONNECT_ONE_SHOT)
	add_child(newTimer)

func createPellet(origin : Vector2, end : Vector2, gradient : GradientTexture2D) -> void:
	var newLine : Line2D = Line2D.new()
	newLine.width = 4
	newLine.texture = gradient
	newLine.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	newLine.add_point(origin - global_position)
	newLine.add_point(end - global_position)
	add_child(newLine)

func timerTimeout() -> void:
	queue_free()
