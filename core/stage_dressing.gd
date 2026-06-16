# ステージの背景演出（グリッド床・月・山の稜線）— 外部アセットを使わず手続き的に生成する。
class_name StageDressing

const GRID_SHADER_CODE := "
shader_type spatial;
render_mode unshaded;

uniform float cell_size = 2.0;
uniform float line_width : hint_range(0.0, 0.5) = 0.04;
uniform vec3 line_color : source_color = vec3(0.3, 0.7, 1.0);
uniform vec3 base_color : source_color = vec3(0.05, 0.03, 0.09);

void fragment() {
	vec2 cell = fract(UV * 30.0 / cell_size);
	float line = step(cell.x, line_width) + step(cell.y, line_width);
	ALBEDO = mix(base_color, line_color, clamp(line, 0.0, 1.0));
}
"

static func build_grid_floor(size: Vector2) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	var shader := Shader.new()
	shader.code = GRID_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	plane.material = mat
	mesh_instance.mesh = plane
	mesh_instance.name = "GridFloor"
	return mesh_instance

static func build_moon() -> MeshInstance3D:
	var moon := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 4.0
	mesh.height = 8.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.92, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.85, 1.0)
	mat.emission_energy_multiplier = 1.5
	mesh.material = mat
	moon.mesh = mesh
	moon.position = Vector3(18.0, 22.0, -55.0)
	moon.name = "Moon"
	return moon

static func build_silhouette(peak_count: int, rng_seed: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Silhouette"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.01, 0.04)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in peak_count:
		var peak := MeshInstance3D.new()
		var box := BoxMesh.new()
		var width := rng.randf_range(6.0, 12.0)
		var height := rng.randf_range(8.0, 20.0)
		box.size = Vector3(width, height, 4.0)
		box.material = mat
		peak.mesh = box
		var x := -50.0 + i * (100.0 / float(peak_count)) + rng.randf_range(-3.0, 3.0)
		peak.position = Vector3(x, height * 0.5 - 1.0, -48.0)
		root.add_child(peak)
	return root

static func build_burst_particles(color: Color, amount: int) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.emitting = false

	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mesh.material = mat
	particles.draw_pass_1 = mesh

	var process_mat := ParticleProcessMaterial.new()
	process_mat.direction = Vector3(0.0, 1.0, 0.0)
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 2.0
	process_mat.initial_velocity_max = 4.0
	process_mat.gravity = Vector3(0.0, -4.0, 0.0)
	particles.process_material = process_mat
	return particles
