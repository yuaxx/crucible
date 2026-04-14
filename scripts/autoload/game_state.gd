extends Node

signal score_changed

var scores: Dictionary = {}

func _ready() -> void:
	NetworkManager.peer_joined.connect(_on_peer_joined)
	NetworkManager.peer_left.connect(_on_peer_left)
	NetworkManager.server_started.connect(_on_server_started)

func _on_server_started() -> void:
	scores[1] = 0
	_broadcast_scores()

func _on_peer_joined(peer_id: int) -> void:
	if multiplayer.is_server():
		scores[peer_id] = 0
		_broadcast_scores()

func _on_peer_left(peer_id: int) -> void:
	if multiplayer.is_server():
		scores.erase(peer_id)
		_broadcast_scores()

func register_kill(attacker_id: int, victim_id: int) -> void:
	if not multiplayer.is_server():
		return
	if attacker_id == victim_id or attacker_id == 0:
		return
	scores[attacker_id] = scores.get(attacker_id, 0) + 1
	_broadcast_scores()

func _broadcast_scores() -> void:
	if not multiplayer.is_server():
		return
	_receive_scores.rpc(scores)
	_receive_scores(scores)

@rpc("authority", "call_remote", "reliable")
func _receive_scores(new_scores: Dictionary) -> void:
	scores = new_scores
	score_changed.emit()
