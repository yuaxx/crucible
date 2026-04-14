extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.002

const PRIMARY_MODEL: PackedScene = preload("res://assets/models/weapons/blasters/blaster-c.glb")
const HEAVY_MODEL: PackedScene = preload("res://assets/models/weapons/blasters/blaster-m.glb")

const ANIM_SOURCES: Dictionary = {
	"idle": preload("res://assets/animations/Rifle Aiming Idle.fbx"),
	"run": preload("res://assets/animations/Rifle Start Run.fbx"),
	"jump": preload("res://assets/animations/Jumping.fbx"),
	"fall": preload("res://assets/animations/Falling Idle.fbx"),
}

const SHOOT_PRIMARY_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/laserSmall_000.ogg"),
	preload("res://assets/audio/laserSmall_001.ogg"),
	preload("res://assets/audio/laserSmall_002.ogg"),
	preload("res://assets/audio/laserSmall_003.ogg"),
	preload("res://assets/audio/laserSmall_004.ogg"),
]
const SHOOT_HEAVY_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/laserLarge_000.ogg"),
	preload("res://assets/audio/laserLarge_001.ogg"),
	preload("res://assets/audio/laserLarge_002.ogg"),
	preload("res://assets/audio/laserLarge_003.ogg"),
	preload("res://assets/audio/laserLarge_004.ogg"),
]
const HIT_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/impactMetal_000.ogg"),
	preload("res://assets/audio/impactMetal_001.ogg"),
	preload("res://assets/audio/impactMetal_002.ogg"),
	preload("res://assets/audio/impactMetal_003.ogg"),
	preload("res://assets/audio/impactMetal_004.ogg"),
]
const DEATH_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/explosionCrunch_000.ogg"),
	preload("res://assets/audio/explosionCrunch_001.ogg"),
	preload("res://assets/audio/explosionCrunch_002.ogg"),
]

@export var hp: int = DamageSystem.MAX_HP
@export var current_weapon: String = "primary"
@export var anim_state: String = "idle"

signal died(attacker_id: int)
signal weapon_changed(new_weapon: String)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var gun_raycast: RayCast3D = $CameraPivot/GunRaycast
@onready var melee_area: Area3D = $CameraPivot/MeleeArea
@onready var character_model: Node3D = $CharacterModel
@onready var viewmodel: Node3D = $CameraPivot/Camera3D/Viewmodel

var anim_player: AnimationPlayer = null
var current_anim: String = ""

const CAMERA_HEIGHT_NORMAL: float = 0.7
const CAMERA_HEIGHT_SLIDE: float = 0.3

var primary_gun: WeaponGun = WeaponGun.new(20, 0.12)
var heavy_gun: WeaponGun = WeaponGun.new(50, 0.7)
var melee: WeaponMelee = WeaponMelee.new()
var movement: MovementController = null

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	_setup_animations()
	if is_multiplayer_authority():
		movement = MovementController.new(self)
		movement.state_changed.connect(_on_movement_state_changed)
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		character_model.visible = false
		viewmodel.visible = true
		_equip_weapon(current_weapon)
	else:
		camera.current = false
		character_model.visible = true
		viewmodel.visible = false
		_play_anim("idle")

func _setup_animations() -> void:
	anim_player = character_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		push_warning("Brak AnimationPlayer w CharacterModel")
		return
	var lib: AnimationLibrary = AnimationLibrary.new()
	for key in ANIM_SOURCES:
		var scene: PackedScene = ANIM_SOURCES[key]
		var inst: Node = scene.instantiate()
		var src_ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if src_ap != null:
			var anim: Animation = _find_real_animation(src_ap)
			if anim != null:
				lib.add_animation(key, anim)
		inst.queue_free()
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	anim_player.add_animation_library("", lib)

func _find_real_animation(ap: AnimationPlayer) -> Animation:
	for anim_name in ap.get_animation_list():
		if String(anim_name).to_upper() != "RESET":
			return ap.get_animation(anim_name)
	return null

func _play_anim(name: String) -> void:
	if anim_player == null or current_anim == name:
		return
	if not anim_player.has_animation(name):
		return
	current_anim = name
	anim_player.play(name, 0.15)

func _compute_anim_state() -> void:
	var horizontal: float = Vector2(velocity.x, velocity.z).length()
	if hp <= 0:
		anim_state = "idle"
	elif not is_on_floor():
		anim_state = "jump" if velocity.y > 0.5 else "fall"
	elif horizontal > 0.5:
		anim_state = "run"
	else:
		anim_state = "idle"

func _apply_anim_state() -> void:
	_play_anim(anim_state)

func _equip_weapon(weapon_name: String) -> void:
	current_weapon = weapon_name
	for child in viewmodel.get_children():
		child.queue_free()
	var model_scene: PackedScene = null
	if weapon_name == "primary":
		model_scene = PRIMARY_MODEL
	elif weapon_name == "heavy":
		model_scene = HEAVY_MODEL
	if model_scene != null:
		viewmodel.add_child(model_scene.instantiate())
	weapon_changed.emit(weapon_name)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/2 + 0.05, PI/2 - 0.05)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("weapon_1"):
		_equip_weapon("primary")
	elif event.is_action_pressed("weapon_2"):
		_equip_weapon("heavy")
	var active_gun: WeaponGun = null
	if current_weapon == "primary":
		active_gun = primary_gun
	elif current_weapon == "heavy":
		active_gun = heavy_gun
	if event.is_action_pressed("shoot") and active_gun != null and hp > 0:
		var shot: Dictionary = active_gun.try_fire(gun_raycast, self)
		if shot.fired:
			var muzzle_world: Vector3 = camera.global_transform * Vector3(0.35, -0.3, -1.0)
			_show_shot_effect.rpc(muzzle_world, shot.to)
	if event.is_action_pressed("melee") and hp > 0:
		melee.try_swing(melee_area, self)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		_apply_anim_state()
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wishdir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	movement.update(delta, {
		"wishdir": wishdir,
		"jump": Input.is_action_just_pressed("jump"),
		"sprint": Input.is_action_pressed("sprint"),
		"crouch": Input.is_action_pressed("crouch"),
		"alive": hp > 0,
	})
	_compute_anim_state()
	_apply_anim_state()

@rpc("authority", "call_local", "unreliable_ordered")
func _show_shot_effect(from: Vector3, to: Vector3) -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	LaserTracer.spawn_between(root, from, to)
	MuzzleFlash.spawn_at(root, from)
	var pool: Array[AudioStream] = SHOOT_HEAVY_SOUNDS if current_weapon == "heavy" else SHOOT_PRIMARY_SOUNDS
	_play_sound(pool[randi() % pool.size()], from)

func _play_sound(stream: AudioStream, pos: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.unit_size = 8.0
	player.max_distance = 60.0
	get_tree().current_scene.add_child(player)
	player.global_position = pos
	player.finished.connect(player.queue_free)
	player.play()

@rpc("any_peer", "call_local", "reliable")
func take_damage(damage: int, attacker_id: int, is_headshot: bool = false) -> void:
	if not multiplayer.is_server():
		return
	if hp <= 0:
		return
	var new_hp: int = DamageSystem.apply_damage(hp, damage, is_headshot)
	hp = new_hp
	var auth: int = get_multiplayer_authority()
	if auth != 1:
		_apply_hp.rpc_id(auth, new_hp)
	print("[SERVER] Player %s HP: %d (dmg %d from %d, auth=%d)" % [name, new_hp, damage, attacker_id, auth])
	_play_hit_feedback.rpc(global_position)
	if DamageSystem.is_dead(new_hp):
		_play_death_feedback.rpc(global_position)
		died.emit(attacker_id)
		_on_died(attacker_id)

@rpc("authority", "call_local", "unreliable")
func _play_hit_feedback(pos: Vector3) -> void:
	_play_sound(HIT_SOUNDS[randi() % HIT_SOUNDS.size()], pos)

@rpc("authority", "call_local", "unreliable")
func _play_death_feedback(pos: Vector3) -> void:
	_play_sound(DEATH_SOUNDS[randi() % DEATH_SOUNDS.size()], pos)

@rpc("any_peer", "call_remote", "reliable")
func _apply_hp(new_hp: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 1:
		return
	hp = new_hp
	print("[CLIENT %d] Player %s HP: %d" % [multiplayer.get_unique_id(), name, new_hp])

func _on_died(attacker_id: int) -> void:
	if not multiplayer.is_server():
		return
	print("[SERVER] Player %s zabity przez %d" % [name, attacker_id])
	GameState.register_kill(attacker_id, int(name))
	_respawn.call_deferred()

func _on_movement_state_changed(new_state: int) -> void:
	var target_y: float = CAMERA_HEIGHT_SLIDE if new_state == MovementController.State.SLIDE else CAMERA_HEIGHT_NORMAL
	var tween := create_tween()
	tween.tween_property(camera_pivot, "position:y", target_y, 0.15)

func _respawn() -> void:
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	var spawn_points := get_tree().get_nodes_in_group("spawn_points")
	var spawn_pos: Vector3 = global_position
	if spawn_points.size() > 0:
		var sp: Marker3D = spawn_points[randi() % spawn_points.size()]
		spawn_pos = sp.global_position
	hp = DamageSystem.MAX_HP
	var auth: int = get_multiplayer_authority()
	if auth == 1:
		global_position = spawn_pos
	else:
		_do_respawn.rpc_id(auth, spawn_pos)

@rpc("any_peer", "call_remote", "reliable")
func _do_respawn(pos: Vector3) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 1:
		return
	hp = DamageSystem.MAX_HP
	if is_multiplayer_authority():
		global_position = pos
	print("[CLIENT %d] Player %s respawned" % [multiplayer.get_unique_id(), name])
