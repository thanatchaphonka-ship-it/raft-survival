extends Area3D

@export var float_speed := 1.5
@export var move_speed := 8.0
@export var collect_distance := 3.0

var player: Node3D = null
var dock: Node3D = null
var collecting := false
var collected := false


func _ready():
	find_player()
	find_dock()


func find_player():
	player = get_tree().current_scene.get_node_or_null("PlayerController")


func find_dock():
	dock = get_tree().current_scene.find_child("Dock", true, false)


func _process(delta):
	if player == null or not is_instance_valid(player):
		find_player()
		if player == null:
			return

	# ค้นหา Dock ใหม่เมื่อแพเดิมถูกลบหรือเปลี่ยน
	if dock == null or not is_instance_valid(dock):
		find_dock()

	# กำลังถูกดึงเข้าหาผู้เล่น
	if collecting:
		global_position = global_position.move_toward(
			player.global_position,
			move_speed * delta
		)

		if global_position.distance_to(player.global_position) < 0.3:
			if not collected:
				collected = true

				if player.has_method("play_pickup_sound"):
					player.play_pickup_sound()

				if player.has_method("add_food"):
					player.add_food()
					print("🐟 เก็บปลาแล้ว! Food +1")

				queue_free()
		return

	# ตรวจระยะผู้เล่น
	if global_position.distance_to(player.global_position) <= collect_distance:
		collecting = true
		return

	# ตรวจขอบเขตแพปัจจุบัน
	if is_inside_raft():
		return

	# ลอยไปข้างหน้าตามระบบเดิม
	global_position.z += float_speed * delta


func is_inside_raft() -> bool:
	if dock == null or not is_instance_valid(dock):
		return false

	# เลือก CollisionShape3D ที่อยู่ใต้ StaticBody3D
	var static_body = dock.find_child("StaticBody3D", true, false)

	if static_body == null:
		return false

	var collision = static_body.find_child(
		"CollisionShape3D", true, false
	)

	if collision == null or collision.shape == null:
		return false

	if not collision.shape is BoxShape3D:
		return false

	var shape: BoxShape3D = collision.shape
	var local_pos = collision.to_local(global_position)

	var half_x = shape.size.x / 2.0
	var half_z = shape.size.z / 2.0

	return (
		abs(local_pos.x) <= half_x
		and abs(local_pos.z) <= half_z
	)
