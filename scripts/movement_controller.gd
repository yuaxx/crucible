class_name MovementController
extends RefCounted

enum State { IDLE, RUN, AIR, SLIDE, WALLRUN, GRAPPLE }

const SPEED: float = 5.0
const SPRINT_MULTIPLIER: float = 1.4
const JUMP_VELOCITY: float = 5.0

const BHOP_WINDOW: float = 0.15
const BHOP_BOOST: float = 1.02
const MAX_HORIZONTAL_SPEED: float = 15.0

signal state_changed(new_state: int)

var body: CharacterBody3D
var state: int = State.IDLE
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var time_since_land: float = 999.0
var bhop_chain: int = 0
var was_on_floor: bool = true

func _init(p_body: CharacterBody3D) -> void:
	body = p_body

func update(delta: float, input: Dictionary) -> void:
	_track_floor(delta)
	_apply_gravity(delta)
	_apply_wish_velocity(input)
	_handle_jump(input)
	body.move_and_slide()
	_update_state()

func _track_floor(delta: float) -> void:
	var on_floor := body.is_on_floor()
	if on_floor:
		if not was_on_floor:
			time_since_land = 0.0
		else:
			time_since_land += delta
	else:
		time_since_land += delta
	was_on_floor = on_floor

func _apply_gravity(delta: float) -> void:
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta

func _handle_jump(input: Dictionary) -> void:
	if not input.get("jump", false):
		return
	if not body.is_on_floor() or not input.get("alive", true):
		return
	body.velocity.y = JUMP_VELOCITY
	if time_since_land <= BHOP_WINDOW:
		bhop_chain += 1
		var h := Vector2(body.velocity.x, body.velocity.z)
		if h.length() > 0.01:
			var new_speed: float = min(h.length() * BHOP_BOOST, MAX_HORIZONTAL_SPEED)
			h = h.normalized() * new_speed
			body.velocity.x = h.x
			body.velocity.z = h.y
	else:
		bhop_chain = 0

func _apply_wish_velocity(input: Dictionary) -> void:
	if not body.is_on_floor():
		return
	var speed: float = SPEED * (SPRINT_MULTIPLIER if input.get("sprint", false) else 1.0)
	if not input.get("alive", true):
		speed = 0.0
	var wishdir: Vector3 = input.get("wishdir", Vector3.ZERO)
	if wishdir.length() > 0.01:
		body.velocity.x = wishdir.x * speed
		body.velocity.z = wishdir.z * speed
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, speed)
		body.velocity.z = move_toward(body.velocity.z, 0.0, speed)

func _update_state() -> void:
	var new_state: int
	var horizontal: float = Vector2(body.velocity.x, body.velocity.z).length()
	if not body.is_on_floor():
		new_state = State.AIR
	elif horizontal > 0.5:
		new_state = State.RUN
	else:
		new_state = State.IDLE
	if new_state != state:
		state = new_state
		state_changed.emit(new_state)
