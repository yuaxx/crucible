class_name WeaponMelee
extends RefCounted

const DAMAGE: int = 50
const COOLDOWN: float = 0.5

var _last_swing_time: float = 0.0

func try_swing(melee_area: Area3D, shooter: Node) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_swing_time < COOLDOWN:
		return false
	_last_swing_time = now
	for body in melee_area.get_overlapping_bodies():
		if body == shooter:
			continue
		if body is CharacterBody3D and body.has_method("take_damage"):
			var shooter_id := int(shooter.name)
			body.take_damage.rpc_id(1, DAMAGE, shooter_id, false)
	return true
