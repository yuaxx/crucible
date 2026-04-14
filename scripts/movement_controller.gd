class_name MovementController
extends RefCounted

enum State { IDLE, RUN, AIR, SLIDE, WALLRUN, GRAPPLE }

const SPEED: float = 5.0
const SPRINT_MULTIPLIER: float = 1.4
const JUMP_VELOCITY: float = 5.0

const BHOP_WINDOW: float = 0.15
const BHOP_BOOST: float = 1.02
const MAX_HORIZONTAL_SPEED: float = 15.0

const AIR_ACCEL: float = 20.0
const AIR_WISH_SPEED: float = 3.5

const SLIDE_DURATION: float = 1.0
const SLIDE_BOOST: float = 1.3
const SLIDE_FRICTION: float = 4.0
const SLIDE_MIN_SPEED: float = 3.5
const SLIDE_ENTER_MIN_SPEED: float = 4.5

signal state_changed(new_state: int)

var body: CharacterBody3D
var state: int = State.IDLE
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var time_since_land: float = 999.0
var bhop_chain: int = 0
var was_on_floor: bool = true
var slide_time_left: float = 0.0

func _init(p_body: CharacterBody3D) -> void:
	body = p_body

func update(delta: float, input: Dictionary) -> void:
	_track_floor(delta)
	_apply_gravity(delta)
	_update_slide(delta, input)
	if state == State.SLIDE:
		_apply_slide_friction(delta)
	else:
		_apply_wish_velocity(delta, input)
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
	if state == State.SLIDE:
		slide_time_left = 0.0
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

func _update_slide(delta: float, input: Dictionary) -> void:
	var on_floor := body.is_on_floor()
	var h_speed := Vector2(body.velocity.x, body.velocity.z).length()
	if state == State.SLIDE:
		slide_time_left -= delta
		var crouch_held: bool = input.get("crouch", false)
		if slide_time_left <= 0.0 or h_speed < SLIDE_MIN_SPEED or not on_floor or not crouch_held:
			slide_time_left = 0.0
	else:
		if input.get("crouch", false) and input.get("sprint", false) and on_floor and h_speed >= SLIDE_ENTER_MIN_SPEED and input.get("alive", true):
			_enter_slide()

func _enter_slide() -> void:
	state = State.SLIDE
	slide_time_left = SLIDE_DURATION
	var h := Vector2(body.velocity.x, body.velocity.z)
	if h.length() > 0.01:
		var new_speed: float = min(h.length() * SLIDE_BOOST, MAX_HORIZONTAL_SPEED)
		h = h.normalized() * new_speed
		body.velocity.x = h.x
		body.velocity.z = h.y
	state_changed.emit(State.SLIDE)

func _apply_slide_friction(delta: float) -> void:
	var h := Vector2(body.velocity.x, body.velocity.z)
	var new_len: float = max(h.length() - SLIDE_FRICTION * delta, 0.0)
	if h.length() > 0.01:
		h = h.normalized() * new_len
		body.velocity.x = h.x
		body.velocity.z = h.y

func _apply_wish_velocity(delta: float, input: Dictionary) -> void:
	var wishdir: Vector3 = input.get("wishdir", Vector3.ZERO)
	var alive: bool = input.get("alive", true)
	if body.is_on_floor():
		var speed: float = SPEED * (SPRINT_MULTIPLIER if input.get("sprint", false) else 1.0)
		if not alive:
			speed = 0.0
		if wishdir.length() > 0.01:
			body.velocity.x = wishdir.x * speed
			body.velocity.z = wishdir.z * speed
		else:
			body.velocity.x = move_toward(body.velocity.x, 0.0, speed)
			body.velocity.z = move_toward(body.velocity.z, 0.0, speed)
	else:
		_air_accelerate(delta, wishdir, alive)

func _air_accelerate(delta: float, wishdir: Vector3, alive: bool) -> void:
	if not alive or wishdir.length_squared() < 0.001:
		return
	var wish2d: Vector2 = Vector2(wishdir.x, wishdir.z)
	var vel2d: Vector2 = Vector2(body.velocity.x, body.velocity.z)
	var current_in_wish: float = vel2d.dot(wish2d)
	var add_speed: float = AIR_WISH_SPEED - current_in_wish
	if add_speed <= 0.0:
		return
	var accel_amount: float = min(AIR_ACCEL * delta * AIR_WISH_SPEED, add_speed)
	body.velocity.x += wish2d.x * accel_amount
	body.velocity.z += wish2d.y * accel_amount
	var new_vel2d: Vector2 = Vector2(body.velocity.x, body.velocity.z)
	if new_vel2d.length() > MAX_HORIZONTAL_SPEED:
		new_vel2d = new_vel2d.normalized() * MAX_HORIZONTAL_SPEED
		body.velocity.x = new_vel2d.x
		body.velocity.z = new_vel2d.y

func _update_state() -> void:
	var new_state: int
	if state == State.SLIDE and slide_time_left > 0.0:
		new_state = State.SLIDE
	else:
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
