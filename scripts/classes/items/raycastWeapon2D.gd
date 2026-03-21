## A class that handles weapons that fire raycasts. Primarily bullet-based weapons.

class_name RaycastWeapon2D extends Item2D

# --|| VARIABLES ||--

@export_group("Basics")
## How many ticks the cooldown lasts.
@export var cooldown : int = 12
## If the weapon is automatic.
@export var isAutomatic : bool = true
## How much damage a single raycast does.[br]
## For reference, players have 100 HP.
@export var damage : int = 5
## How many shots the weapon has.
@export var magSize : int = 30

@export_group("Firing")
## The offset the pellets are spawned at relative to the weapon.
@export var pelletOffset : Vector2 = Vector2.ZERO
## How many raycasts per a single shot.
@export var pelletCount : int = 1
## How far the raycasts travel.
@export var pelletRange : float = 1000.0
## How far the raycast can deviate from the center in degrees.
@export var pelletSpread : float = 30.0
## How long to keep the pellet visuals for.
@export var pelletLifetime : float = 0.1

@export_group("Recoil","recoil")
## If the linear recoil should also be applied to the user.
@export var recoilAffectsUser : bool = true
## How strong is the recoil linear impulse.
@export var recoilLinearPower : float = 120.0
## How strong is the recoil angular impulse
@export var recoilAngularPower : float = 600.0

@export_group("Effects")
## The gradient to use for each pellet.
@export var pelletGradient : GradientTexture2D
## The particle emitter responsible for muzzle flashes.
@export var muzzleFlashEmitter : GPUParticles2D
## The sound that plays when we shoot.
@export var fireSound : AudioStreamPlayer2D


@export_group("Nodes","node")
## The action responsible for item use.
@export var nodeUseAction : RewindableAction

## How many ticks of cooldown we have left.
var cooldownTicksLeft : int = 0
## How many shots are left in your mag.
var shotsLeft : int = 0
## To tell us if we already fired. Used for semi-auto weapons.
var hasFired : bool = false

## The random number generator responsible for RNG.
var rng : RewindableRandomNumberGenerator = RewindableRandomNumberGenerator.new(69)

var debugger : NetfoxLogger = NetfoxLogger.new("items","RayCastWeapon2D")

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	shotsLeft = magSize
	super._ready()

func _rollback_tick(delta : float, tick : int, isFresh : bool) -> void:
	super._rollback_tick(delta, tick, isFresh)
	if nodeSynchronizer.is_predicting(): return
	updateAction()

# --|| LOGIC FUNCTIONS ||--

func updateAction() -> void:
	cooldownTicksLeft = max(cooldownTicksLeft - 1, 0)
	
	if not currentUser: 
		onActionReleased()
		return
	
	var isAttacking : bool = currentUser.nodeInput.isAttacking
	
	if not isAttacking: onActionReleased()
	
	nodeUseAction.set_active(isAttacking and canFire())
	match nodeUseAction.get_status():
		RewindableAction.ACTIVE, RewindableAction.CONFIRMING:
			onActionConfirmed()
		RewindableAction.CANCELLING:
			onActionCancelled()

func onActionReleased() -> void:
	hasFired = false

func onActionConfirmed() -> void:
	shotsLeft -= 1
	cooldownTicksLeft = cooldown
	hasFired = not isAutomatic
	
	var origin : Vector2 = global_position + pelletOffset.rotated(global_rotation)
	var direction : Vector2 = Vector2(pelletRange, 0.0).rotated(global_rotation)
	
	var origins : Array[Vector2]
	var targets : Array[Vector2]
	
	for _index : int in range(pelletCount):
		var rNum : float = rng.randf_range(-pelletSpread, pelletSpread)
		var rDirection : Vector2 = direction.rotated(deg_to_rad(rNum))
		var raycastData : Dictionary = raycast(origin,rDirection)
		
		origins.append(origin)
		if raycastData.is_empty():
			targets.append(origin + rDirection)
		else:
			targets.append(raycastData.position)
	
	debugger.debug("Action confirmed?")
	
	if not nodeUseAction.has_context():
		nodeUseAction.set_context(true)
		shotEffects(origins,targets)
	
	var linearRecoil : Vector2 = Vector2(-recoilLinearPower, 0.0).rotated(global_rotation)
	
	if recoilAffectsUser: currentUser.apply_central_impulse(linearRecoil)
	apply_central_impulse(linearRecoil)
	apply_torque_impulse(-recoilAngularPower)

func onActionCancelled() -> void:
	debugger.debug("Unfired!")

## --|| HELPER FUNCTIONS ||--

func canFire() -> bool:
	return shotsLeft > 0 and cooldownTicksLeft <= 0 and not hasFired

func shotEffects(origins : Array[Vector2], targets : Array[Vector2]) -> void:
	if muzzleFlashEmitter: muzzleFlashEmitter.restart()
	if fireSound: fireSound.play()
	
	if origins.is_empty(): return
	
	var newPellets : Pellets2D = Pellets2D.new()
	newPellets.global_position = origins[0]
	newPellets.visualizePellets(0.1,origins,targets,pelletGradient)
	get_parent().add_child.call_deferred(newPellets)

func raycast(origin : Vector2, direction : Vector2) -> Dictionary:
	var target : Vector2 = origin + direction
	
	var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, target, 7)
	query.hit_from_inside = true

	return space.intersect_ray(query)
