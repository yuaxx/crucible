extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

@onready var players_container: Node3D = $Players
@onready var hud: CanvasLayer = $HUD

var _spawner: MultiplayerSpawner = null

func _ready() -> void:
	_setup_spawner()
	players_container.child_entered_tree.connect(_on_player_spawned)
	if multiplayer.is_server():
		_spawn_player(1)
		NetworkManager.peer_joined.connect(_on_peer_joined)
		NetworkManager.peer_left.connect(_on_peer_left)
	_try_bind_local_player()

func _setup_spawner() -> void:
	_spawner = MultiplayerSpawner.new()
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(players_container)
	_spawner.add_spawnable_scene("res://scenes/player.tscn")

func _on_player_spawned(_node: Node) -> void:
	_try_bind_local_player()

func _try_bind_local_player() -> void:
	var my_id: int = multiplayer.get_unique_id()
	var my_player: Node = players_container.get_node_or_null(str(my_id))
	if my_player != null and hud.has_method("set_local_player"):
		hud.set_local_player(my_player)
		print("[HUD] Local player bound: %s" % my_player.name)

func _on_peer_joined(peer_id: int) -> void:
	_spawn_player(peer_id)

func _on_peer_left(peer_id: int) -> void:
	var player := players_container.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func _spawn_player(peer_id: int) -> void:
	var player: Node3D = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	var spawn_points := get_tree().get_nodes_in_group("spawn_points")
	if spawn_points.size() > 0:
		var sp: Marker3D = spawn_points[randi() % spawn_points.size()]
		player.position = sp.global_position
	players_container.add_child(player, true)
