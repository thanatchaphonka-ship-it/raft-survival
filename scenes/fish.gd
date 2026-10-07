extends Area3D

@export var float_speed := 1.5
@export var move_speed := 8.0
@export var collect_distance := 3.0

var player: Node3D = null
var dock: Node3D = null

var collecting := false
var collected := false


func _ready():

	player = get_tree().current_scene.get_node_or_null("PlayerController")
	dock = get_tree().current_scene.get_node_or_null("Dock")


func _process(delta):

	# ==================================================
	# หา Player
	# ==================================================

	if player == null:

		player = get_tree().current_scene.get_node_or_null("PlayerController")

		if player == null:
			return


	# ==================================================
	# กำลังถูกเก็บ
	# ==================================================

	if collecting:

		global_position = global_position.move_toward(
			player.global_position,
			move_speed * delta
		)

		if global_position.distance_to(player.global_position) < 0.3:

			if not collected:

				collected = true

				# ปลาให้ Food +1
				if player.has_method("add_food"):

					player.add_food()

					print("🐟 เก็บปลาแล้ว! Food +1")

				queue_free()

		return


	# ==================================================
	# ตรวจระยะจากผู้เล่น
	# ==================================================

	var distance_to_player = global_position.distance_to(
		player.global_position
	)

	if distance_to_player <= collect_distance:

		collecting = true

		return


	# ==================================================
	# ตรวจแพ
	# ==================================================

	if dock != null:

		# หา CollisionShape3D ที่อยู่ข้างใน Dock
		var collision = dock.find_child(
			"CollisionShape3D",
			true,
			false
		)

		if collision != null:

			var shape = collision.shape

			# ตรวจว่า Collision เป็น BoxShape3D
			if shape is BoxShape3D:

				var raft_center = collision.global_position

				# ขนาด Collision จริงหลังจากโดน Scale
				var half_x = (
					shape.size.x
					* collision.global_transform.basis.x.length()
					/ 2.0
				)

				var half_z = (
					shape.size.z
					* collision.global_transform.basis.z.length()
					/ 2.0
				)


				# ==========================================
				# ตรวจว่าปลาอยู่ในพื้นที่แพหรือไม่
				# ==========================================

				var inside_x = abs(
					global_position.x - raft_center.x
				) <= half_x

				var inside_z = abs(
					global_position.z - raft_center.z
				) <= half_z


				if inside_x and inside_z:

					# ปลาอยู่บนแพแล้ว
					# หยุดการลอย
					return


	# ==================================================
	# ลอยไปข้างหน้า
	# ==================================================

	global_position.z += float_speed * delta
