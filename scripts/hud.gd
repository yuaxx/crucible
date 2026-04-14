extends CanvasLayer

@onready var hp_label: Label = $HPPanel/HPLabel
@onready var score_label: Label = $ScorePanel/ScoreLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var respawn_overlay: Control = $RespawnOverlay

var local_player: Node = null

func _ready() -> void:
	respawn_overlay.visible = false
	GameState.score_changed.connect(_update_score)
	_update_score()

func set_local_player(player: Node) -> void:
	local_player = player

const WEAPON_NAMES: Dictionary = {
	"primary": "ASSAULT",
	"heavy": "HEAVY",
}

func _process(_delta: float) -> void:
	if local_player and is_instance_valid(local_player):
		hp_label.text = "HP: %d" % local_player.hp
		var wname: String = String(local_player.current_weapon)
		weapon_label.text = WEAPON_NAMES.get(wname, wname.to_upper())
		respawn_overlay.visible = local_player.hp <= 0

func _update_score() -> void:
	var parts: PackedStringArray = []
	var ids := GameState.scores.keys()
	ids.sort()
	for pid in ids:
		parts.append("P%d:%d" % [pid, GameState.scores[pid]])
	score_label.text = "  ".join(parts)
