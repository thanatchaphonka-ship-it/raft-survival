extends Node3D

@export var wood_scene: PackedScene
@export var spawn_interval: float = 3.0

# ขนาดพื้นที่สุ่มรอบแพ
@export var spawn_range_x: float = 15.0
@export var spawn_range_z: float = 15.0

# ระยะห่างขั้นต่ำจากกึ่งกลางแพ
@export var min_spawn_distance: float = 8.0

@export var spawn_height: float = 0.0


func _ready() -> void:
	randomize()
	spawn_wood()


func spawn_wood() -> void:
	while is_inside_tree():
		var scene_root = get_tree().current_scene

		if wood_scene != null:
			var dock = scene_root.find_child(
				"Dock", true, false
			)

			if dock != null:
				var spawn_x: float
				var spawn_z: float

				# สุ่มตำแหน่งใหม่จนกว่าจะห่างจากกลางแพพอสมควร
				var attempts := 0

				while attempts < 20:
					spawn_x = randf_range(
						dock.global_position.x - spawn_range_x,
						dock.global_position.x + spawn_range_x
					)

					spawn_z = randf_range(
						dock.global_position.z - spawn_range_z,
						dock.global_position.z + spawn_range_z
					)

					var distance := Vector2(
						spawn_x - dock.global_position.x,
						spawn_z - dock.global_position.z
					).length()

					if distance >= min_spawn_distance:
						break

					attempts += 1

				var wood = wood_scene.instantiate()
				
				# 1. เพิ่ม child แบบ deferred เพื่อป้องกันการถูกบล็อกช่วง scene setup
				scene_root.add_child.call_deferred(wood)

				# 2. ตั้งค่าตำแหน่งหลังจาก wood ถูกเพิ่มเข้า scene tree เรียบร้อยแล้ว
				var target_position = Vector3(
					spawn_x,
					spawn_height,
					spawn_z
				)
				wood.set_deferred("global_position", target_position)
			else:
				print("⚠️ หา Dock ไม่เจอ")
		else:
			print("⚠️ ยังไม่ได้กำหนด wood_scene")

		await get_tree().create_timer(spawn_interval).timeout
