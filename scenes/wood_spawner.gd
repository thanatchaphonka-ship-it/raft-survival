extends Node3D

@export var wood_scene: PackedScene
@export var spawn_interval := 3.0

# ระยะที่ไม้เริ่มเกิด
@export var spawn_distance := 15.0

# ความกว้างในการสุ่ม
@export var spawn_width := 10.0


func _ready():
	spawn_wood()


func spawn_wood():
	var wood = wood_scene.instantiate()
	add_child(wood)

	# สุ่มตำแหน่งซ้าย-ขวา
	var spawn_x = randf_range(-spawn_width, spawn_width)

	# ให้ไม้เกิดด้านหน้า แล้วค่อยลอยเข้ามา
	wood.global_position = Vector3(
		spawn_x,
		0.0,
		-spawn_distance
	)

	# รอแล้วสร้างไม้ชิ้นต่อไป
	await get_tree().create_timer(spawn_interval).timeout
	spawn_wood()
