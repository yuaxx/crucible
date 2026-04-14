class_name WeaponGun
extends RefCounted

const MAX_RANGE: float = 50.0

var damage: int = 25
var fire_rate: float = 0.2
var _last_shot_time: float = 0.0

func _init(dmg: int = 25, rate: float = 0.2) -> void:
	damage = dmg
	fire_rate = rate

func try_fire(raycast: RayCast3D, shooter: Node) -> Dictionary:
	var result: Dictionary = {"fired": false, "from": Vector3.ZERO, "to": Vector3.ZERO}
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_shot_time < fire_rate:
		return result
	_last_shot_time = now
	result.fired = true
	result.from = raycast.global_position
	raycast.force_raycast_update()
	if raycast.is_colliding():
		result.to = raycast.get_collision_point()
		var target := raycast.get_collider() as CharacterBody3D
		if target != null and target.has_method("take_damage"):
			var hit_pos: Vector3 = result.to
			var local_y: float = hit_pos.y - target.global_position.y
			var is_headshot: bool = local_y > 0.6
			var shooter_id: int = int(shooter.name)
			target.take_damage.rpc_id(1, damage, shooter_id, is_headshot)
	else:
		result.to = raycast.global_position + raycast.global_transform.basis.z * -MAX_RANGE
	return result
