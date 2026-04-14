class_name LaserTracer
extends MeshInstance3D

const LIFETIME: float = 0.08
const THICKNESS: float = 0.04

static func spawn_between(parent: Node, from: Vector3, to: Vector3) -> void:
	var tracer := LaserTracer.new()
	parent.add_child(tracer)
	tracer._configure(from, to)

func _configure(from: Vector3, to: Vector3) -> void:
	var distance: float = from.distance_to(to)
	if distance < 0.01:
		queue_free()
		return
	var mid: Vector3 = (from + to) * 0.5
	global_position = mid
	look_at(to, Vector3.UP)
	var box := BoxMesh.new()
	box.size = Vector3(THICKNESS, THICKNESS, distance)
	mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.3, 0.1, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = mat
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mat, "albedo_color:a", 0.0, LIFETIME)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, LIFETIME)
	tween.chain().tween_callback(queue_free)
