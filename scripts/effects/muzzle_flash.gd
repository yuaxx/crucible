class_name MuzzleFlash
extends Node3D

const LIFETIME: float = 0.06

static func spawn_at(tree_root: Node, pos: Vector3) -> void:
	var flash := MuzzleFlash.new()
	tree_root.add_child(flash)
	flash.global_position = pos
	flash._configure()

func _configure() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.2)
	light.light_energy = 5.0
	light.omni_range = 4.0
	add_child(light)
	var quad := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	mesh.radial_segments = 8
	mesh.rings = 4
	quad.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.3, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1)
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material_override = mat
	add_child(quad)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(light, "light_energy", 0.0, LIFETIME)
	tween.tween_property(mat, "albedo_color:a", 0.0, LIFETIME)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, LIFETIME)
	tween.chain().tween_callback(queue_free)
