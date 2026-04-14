class_name MovementController
extends RefCounted

enum State { IDLE, RUN, AIR, SLIDE, WALLRUN, GRAPPLE }

const SPEED: float = 5.0
const SPRINT_MULTIPLIER: float = 1.4
const JUMP_VELOCITY: float = 5.0

signal state_changed(new_state: int)

var body: CharacterBody3D
var state: int = State.IDLE
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _init(p_body: CharacterBody3D) -> void:
	body = p_body

func update(delta: float, input: Dictionary) -> void:
	_apply_gravity(delta)
	_handle_jump(input)
	_apply_wish_velocity(input)
	body.move_and_slide()
	_update_state()

func _apply_gravity(delta: float) -> void:
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta

func _handle_jump(input: Dictionary) -> void:
	if input.get("jump", false) and body.is_on_floor() and input.get("alive", true):
		body.velocity.y = JUMP_VELOCITY

func _apply_wish_velocity(input: Dictionary) -> void:
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
