extends Node3D

@export var fish_scene: PackedScene
@export var spawn_interval := 6.0

# ระยะที่ปลาเริ่มเกิด
@export var spawn_distance := 15.0

# ความกว้างในการสุ่ม
@export var spawn_width := 10.0


func _ready():
	# รอตามเวลา spawn_interval ก่อนเสกปลาตัวแรก
	await get_tree().create_timer(spawn_interval).timeout
	spawn_fish()


func spawn_fish():
	var fish = fish_scene.instantiate()

	# สุ่มตำแหน่งซ้าย-ขวา
	var spawn_x = randf_range(-spawn_width, spawn_width)

	# ให้ปลาเกิดด้านหน้าแพ
	fish.position = Vector3(
		spawn_x,
		0.0,
		-spawn_distance
	)

	add_child(fish)

	# รอสร้างปลาตัวถัดไป
	await get_tree().create_timer(spawn_interval).timeout
	spawn_fish()
