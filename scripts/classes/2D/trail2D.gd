## Renders a trail on the parent.[br]
## Note: By itself it doesn't render a trail, you need to move the parent for the trail to appear.

class_name Trail2D extends Line2D

## Describes what method should we use to update the trail.
enum updateMode {
	## We update the trail in [method _physics_process]
	Physics,
	## We update the trail in [method _process]
	Idle
}

# --|| VARIABLES ||--
@export_group("Settings")
## The max length of the trail.
@export var maxLength : float = 100.0
## The max amount of seconds the trail's end can exist for.
@export var maxLifetime : float = 0.2
@export_group("Flags","flag_")
## If we should spawn new points.
@export var flag_enabled : bool = true
## Which process we should use for updating the trail.
@export var flag_updateMode : updateMode = updateMode.Idle

## The time of birth of each point. The index matches the points array.
var pointBirthTimes : Array[float]
## The parent node we use to display the trail.
var parent : Node2D
## The offset within the parent we display the trial at.
var offset : Vector2 = Vector2.ZERO
## The last global position of the trail's beginning.
var lastPoint : Vector2 = Vector2.ZERO
## The time that has passed since we started.
var time : float = 0.0

# --|| MAIN FUNCTIONS  ||--

func _ready() -> void:
	if get_parent() is Node2D: parent = get_parent()
	else: push_warning("CANNOT DISPLAY TRAIL, PARENT IS NOT Node2D")
	offset = position
	top_level = true
	points = []

func _process(delta: float) -> void:
	if flag_updateMode != updateMode.Idle: return
	updateTrail(delta)

func _physics_process(delta: float) -> void:
	if flag_updateMode != updateMode.Physics: return
	updateTrail(delta)

# --|| LOGIC FUNCTIONS ||--

## Updates the entirety of the trail. [br]
## Called by either [method _process] or [method _physics_process] depending on [member flag_updateMode]
func updateTrail(delta : float) -> void:
	if not parent: return
	
	time += delta
	global_position = Vector2.ZERO
	var point : Vector2 = parent.global_position + offset.rotated(parent.global_rotation)
	var isSameAsLast : bool = point.is_equal_approx(lastPoint)
	lastPoint = point
	if flag_enabled and not isSameAsLast: birthPoint(point)
	
	var pointsToRemove : Array[int] =[]
	
	var currentDistance : float = 0.0
	var prevPoint : Vector2 = get_point_position(0) if get_point_count() > 0 else Vector2.ZERO
	
	for i : int in range(get_point_count()):
		var pPosition : Vector2 = get_point_position(i)
		if i >= pointBirthTimes.size(): pointBirthTimes.append(time)
		var lifetime : float = time - pointBirthTimes[i]
		var distance : float = prevPoint.distance_to(pPosition)
		
		prevPoint = pPosition
		currentDistance += distance
		
		if currentDistance > maxLength or lifetime > maxLifetime:
			pointsToRemove.append(i)
	
	pointsToRemove.reverse()
	for i : int in pointsToRemove:
		killPoint(i)

## Remove a point specified by [param index]
func killPoint(index : int) -> void:
	pointBirthTimes.remove_at(index)
	remove_point(index)

## Creates a point at the position specified by [param point]
func birthPoint(point : Vector2) -> void:
	add_point(point, 0)
	pointBirthTimes.insert(0, time)
	
