extends Area3D

@export var float_speed: float = 1.5
@export var move_speed: float = 8.0
@export var collect_distance: float = 4.5
@export var water_level: float = 0.0
@export var raft_margin: float = 0.3

var player: Node3D = null
var dock: Node3D = null
var raft_body: StaticBody3D = null
var raft_collision: CollisionShape3D = null

var collecting: bool = false


func _ready() -> void:
	print("✅ wood.gd ทำงานแล้ว")
	find_player()
	find_dock()


func find_player() -> void:
	var scene_root = get_tree().current_scene

	player = scene_root.find_child(
		"PlayerController", true, false
	) as Node3D


func find_dock() -> void:
	var scene_root = get_tree().current_scene

	var found_dock = scene_root.find_child(
		"Dock", true, false
	)

	if not found_dock is Node3D:
		dock = null
		raft_body = null
		raft_collision = null
		print("⚠️ ยังหา Dock ไม่เจอ")
		return

	dock = found_dock as Node3D

	raft_body = dock.get_node_or_null(
		"StaticBody3D"
	) as StaticBody3D

	if is_instance_valid(raft_body):
		raft_collision = raft_body.get_node_or_null(
			"CollisionShape3D"
		) as CollisionShape3D
	else:
		raft_collision = null

	if is_instance_valid(raft_collision):
		print("✅ พบ Collision ของแพ")
	else:
		print("⚠️ ไม่พบ CollisionShape3D ของแพ")


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		find_player()

		if not is_instance_valid(player):
			return

	if not is_instance_valid(dock):
		find_dock()

	# ไม้ลอยอยู่ระดับน้ำจนกว่าจะเริ่มดูด
	if not collecting:
		global_position.y = water_level

	# ==================================
	# ระบบดูดไม้เข้าหาตัวละคร
	# ==================================
	if collecting:
		var target_pos = player.global_position
		target_pos.y = global_position.y

		global_position = global_position.move_toward(
			target_pos,
			move_speed * delta
		)

		# ตรวจระยะในแนวราบ
		var horizontal_distance = Vector2(
			global_position.x - player.global_position.x,
			global_position.z - player.global_position.z
		).length()

		if horizontal_distance < 0.5:
			if player.has_method("play_pickup_sound"):
				player.play_pickup_sound()

			if player.has_method("add_wood"):
				player.add_wood()

			queue_free()

		return

	# ==================================
	# ตรวจระยะผู้เล่นในแนวราบ
	# ==================================
	var horizontal_distance = Vector2(
		global_position.x - player.global_position.x,
		global_position.z - player.global_position.z
	).length()

	if horizontal_distance <= collect_distance:
		collecting = true
		return

	# ==================================
	# ลอยเข้าหาแพ
	# ==================================
	if not is_instance_valid(dock):
		return

	var target_pos: Vector3 = dock.global_position
	target_pos.y = global_position.y

	var direction: Vector3 = target_pos - global_position
	direction.y = 0.0

	if direction.length() < 0.01:
		return

	var movement = (
		direction.normalized() * float_speed * delta
	)

	var next_position = global_position + movement

	# หยุดก่อนเข้าเขต Collision ของแพ
	if is_position_inside_raft(next_position):
		return

	global_position = next_position


# ==================================
# ตรวจตำแหน่งภายในแพ
# ==================================
func is_inside_raft() -> bool:
	return is_position_inside_raft(global_position)


func is_position_inside_raft(
	world_position: Vector3
) -> bool:
	if not is_instance_valid(raft_collision):
		return false

	if raft_collision.shape == null:
		return false

	if not raft_collision.is_inside_tree():
		return false

	var local_pos: Vector3 = (
		raft_collision.global_transform.affine_inverse()
		* world_position
	)

	var shape = raft_collision.shape

	if shape is BoxShape3D:
		var half_size: Vector3 = shape.size / 2.0

		return (
			abs(local_pos.x) <= half_size.x + raft_margin
			and
			abs(local_pos.z) <= half_size.z + raft_margin
		)

	elif shape is CylinderShape3D:
		return (
			Vector2(local_pos.x, local_pos.z).length()
			<= shape.radius + raft_margin
		)

	elif shape is SphereShape3D:
		return (
			Vector2(local_pos.x, local_pos.z).length()
			<= shape.radius + raft_margin
		)

	return false
