extends Node

func _ready() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--server" in args or "--dedicated" in args:
		print("[BOOTSTRAP] Server mode, laduje server.tscn")
		get_tree().change_scene_to_file.call_deferred("res://scenes/server.tscn")
