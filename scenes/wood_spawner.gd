extends Node3D

@export var wood_scene: PackedScene
@export var spawn_interval := 3.0

# 👈 ปรับระยะเกิดให้ใกล้เข้ามาเห็นชัดๆ (ประมาณ 8.0 - 10.0)
@export var spawn_distance := 9.0


func _ready():
	spawn_wood()


func spawn_wood():
	if wood_scene == null:
		return

	# หาตำแหน่งแพ
	var dock = get_tree().current_scene.find_child("Dock", true, false)
	var center_pos = Vector3.ZERO
	if dock != null:
		center_pos = dock.global_position

	var wood = wood_scene.instantiate()
	get_tree().current_scene.add_child(wood)

	# สุ่มมุมรอบแพ
	var random_angle = randf_range(0, TAU)

	# คำนวณพิกัด X, Z วงกลมรอบแพโดยอ้างอิงจากตำแหน่งแพจริง
	var spawn_x = center_pos.x + (cos(random_angle) * spawn_distance)
	var spawn_z = center_pos.z + (sin(random_angle) * spawn_distance)

	wood.global_position = Vector3(spawn_x, 0.0, spawn_z)

	await get_tree().create_timer(spawn_interval).timeout
	spawn_wood()
