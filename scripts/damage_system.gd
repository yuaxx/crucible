class_name DamageSystem
extends RefCounted

const MAX_HP: int = 100
const HEADSHOT_MULTIPLIER: float = 2.0

static func apply_damage(current_hp: int, damage: int, is_headshot: bool = false) -> int:
	var final_damage := damage
	if is_headshot:
		final_damage = int(damage * HEADSHOT_MULTIPLIER)
	return max(0, current_hp - final_damage)

static func is_dead(hp: int) -> bool:
	return hp <= 0
