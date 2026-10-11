extends Area3D

@export var float_speed := 1.5
@export var move_speed := 8.0
@export var collect_distance := 3.0
@export var water_level := 0.0 # ระดับความสูงผิวน้ำ

var player: Node3D = null
var dock: Node3D = null
var collecting := false
var is_touching_raft := false # เพิ่มตัวแปรเช็กขอบแพ


func _ready():
	player = get_tree().current_scene.get_node_or_null("PlayerController")
	dock = get_tree().current_scene.find_child("Dock", true, false)
	
	# เชื่อมสัญญาณการชน Area3D เข้ากับกลุ่ม RaftBound
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area3D):
	if area.is_in_group("RaftBound"):
		is_touching_raft = true


func _on_area_exited(area: Area3D):
	if area.is_in_group("RaftBound"):
		is_touching_raft = false


func _process(delta):

	# ==================================================
	# ค้นหา Player และ Dock (หาใหม่เสมอเผื่อมีการอัปเกรดแพ)
	# ==================================================

	if player == null:
		player = get_tree().current_scene.get_node_or_null("PlayerController")
		if player == null:
			return

	if dock == null or not is_instance_valid(dock):
		dock = get_tree().current_scene.find_child("Dock", true, false)


	# ==================================================
	# ล็อกความสูง Y ให้อยู่ผิวน้ำเสมอ (ไม่ให้ลอยยกขึ้นบนแพ)
	# ==================================================

	if not collecting:
		global_position.y = water_level


	# ==================================================
	# กำลังถูกดูดเข้าตัวผู้เล่น
	# ==================================================

	if collecting:

		global_position = global_position.move_toward(
			player.global_position,
			move_speed * delta
		)

		if global_position.distance_to(player.global_position) < 0.3:

			if player.has_method("add_wood"):
				player.add_wood()

			queue_free()

		return


	# ==================================================
	# ตรวจระยะผู้เล่นเพื่อเก็บของ
	# ==================================================

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= collect_distance:
		collecting = true
		return


	# ==================================================
	# ตรวจขอบแพ (ถ้าแตะกลุ่ม RaftBound แล้วให้หยุดลอยทันที)
	# ==================================================

	if is_touching_raft:
		return # หยุดการลอยขยับเข้าหาศูนย์กลางแพ


	# ==================================================
	# ลอยมุ่งตรงเข้าหาศูนย์กลางของแพ (จากทุกทิศทาง)
	# ==================================================

	if dock != null:
		var target_pos = dock.global_position
		target_pos.y = global_position.y # ไม่คิดความสูง Y
		
		# คำนวณทิศทางจากตำแหน่งไม้ปัจจุบัน พุ่งเข้าหาตำแหน่งแพ
		var dir_to_dock = (target_pos - global_position).normalized()
		global_position += dir_to_dock * float_speed * delta
	else:
		# ถ้าหาแพไม่เจอ ให้ลอยไปข้างหน้าตามปกติ
		global_position.z += float_speed * delta
