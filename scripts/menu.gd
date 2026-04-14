extends Control

@onready var address_edit: LineEdit = $CenterContainer/VBoxContainer/AddressLineEdit
@onready var port_edit: LineEdit = $CenterContainer/VBoxContainer/PortLineEdit
@onready var join_button: Button = $CenterContainer/VBoxContainer/JoinButton
@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	join_button.pressed.connect(_on_join_pressed)
	host_button.pressed.connect(_on_host_pressed)
	NetworkManager.client_connected.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _on_join_pressed() -> void:
	var address := address_edit.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var port := int(port_edit.text) if not port_edit.text.is_empty() else NetworkManager.DEFAULT_PORT
	status_label.text = "Laczenie z %s:%d..." % [address, port]
	NetworkManager.join_server(address, port)

func _on_host_pressed() -> void:
	var port := int(port_edit.text) if not port_edit.text.is_empty() else NetworkManager.DEFAULT_PORT
	if NetworkManager.host_server(port):
		_load_game()
	else:
		status_label.text = "Blad hostowania"

func _on_connected() -> void:
	_load_game()

func _on_connection_failed() -> void:
	status_label.text = "Nie udalo sie polaczyc"

func _load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
