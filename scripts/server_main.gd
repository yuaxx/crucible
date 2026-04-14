extends Node

const PORT: int = 27015

func _ready() -> void:
	print("[SERVER-MAIN] Startuje dedicated server...")
	NetworkManager.is_headless = true
	if not NetworkManager.host_server(PORT):
		print("[SERVER-MAIN] FATAL: nie udalo sie uruchomic serwera")
		get_tree().quit(1)
		return
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = game_scene.instantiate()
	get_tree().root.add_child(game)
	print("[SERVER-MAIN] Gra zaladowana, czekam na graczy na porcie %d" % PORT)
