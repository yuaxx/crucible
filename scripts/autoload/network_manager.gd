extends Node

signal server_started
signal client_connected
signal client_disconnected
signal connection_failed
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const DEFAULT_PORT: int = 27015
const MAX_PLAYERS: int = 4

var is_server: bool = false
var is_headless: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_server(port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Nie udalo sie uruchomic serwera na porcie %d: %s" % [port, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	is_server = true
	print("[SERVER] Slucham na porcie %d" % port)
	server_started.emit()
	return true

func join_server(address: String, port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Blad klienta: %s" % error_string(err))
		return false
	multiplayer.multiplayer_peer = peer
	print("[CLIENT] Lacze sie z %s:%d..." % [address, port])
	return true

func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_server = false

func _on_peer_connected(peer_id: int) -> void:
	print("[NET] Peer %d dolaczyl" % peer_id)
	peer_joined.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("[NET] Peer %d odszedl" % peer_id)
	peer_left.emit(peer_id)

func _on_connected_to_server() -> void:
	print("[CLIENT] Polaczono z serwerem")
	client_connected.emit()

func _on_connection_failed() -> void:
	push_error("[CLIENT] Polaczenie nieudane")
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("[CLIENT] Rozlaczono z serwerem")
	client_disconnected.emit()
