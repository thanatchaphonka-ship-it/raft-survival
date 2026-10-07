extends Area3D

# =========================================================
# 🦈 SHARK SETTINGS
# =========================================================

@export var swim_speed: float = 2.5

# ระยะที่ฉลามว่ายห่างจากขอบแพ
@export var raft_margin: float = 8.0

# ความเร็วตอนพุ่งเข้าแพ
@export var attack_speed: float = 9.0

# ระยะที่ถือว่าถึงแพแล้ว
@export var attack_distance: float = 1.2

# เวลาระหว่างการโจมตี
@export var min_attack_cooldown: float = 5.0
@export var max_attack_cooldown: float = 8.0

@export var damage: int = 17

@export var turn_speed: float = 5.0

# ระยะถอยหลังหลังโจมตี
@export var retreat_distance: float = 10.0
@export var retreat_speed: float = 5.0


# =========================================================
# REFERENCES
# =========================================================

var player: Node3D = null
var dock: Node3D = null
var dock_collision: CollisionShape3D = null


# =========================================================
# SHARK STATE
# =========================================================

var swim_angle := 0.0

var is_attacking := false
var is_retreating := false

var has_damaged := false

var attack_timer := 3.0

# จุดที่ฉลามจะพุ่งไป
var target_position := Vector3.ZERO

# จุดที่ฉลามจะถอยไป
var retreat_target := Vector3.ZERO


# =========================================================
# READY
# =========================================================

func _ready():

	player = get_tree().current_scene.get_node_or_null(
		"PlayerController"
	)

	dock = get_tree().current_scene.get_node_or_null(
		"Dock"
	)

	find_dock_collision()

	swim_angle = randf_range(
		0.0,
		TAU
	)

	# ครั้งแรกให้รอประมาณ 3 วิ
	attack_timer = 3.0

	if player == null:
		print("⚠️ Shark หา PlayerController ไม่เจอ")

	if dock == null:
		print("⚠️ Shark หา Dock ไม่เจอ")

	if dock_collision == null:
		print("⚠️ Shark หา CollisionShape3D ของ Dock ไม่เจอ")
	else:
		print("✅ Shark เจอ CollisionShape3D ของ Dock แล้ว")


# =========================================================
# PROCESS
# =========================================================

func _process(delta):

	# หา Player ใหม่ถ้าหาย
	if player == null:

		player = get_tree().current_scene.get_node_or_null(
			"PlayerController"
		)

		if player == null:
			return


	# หา Dock ใหม่ถ้าหาย
	if dock == null:

		dock = get_tree().current_scene.get_node_or_null(
			"Dock"
		)


	# หา Collision ใหม่
	if dock_collision == null:

		find_dock_collision()


	# =====================================================
	# ถ้าไม่ได้กำลังโจมตี/ถอย
	# ตรวจว่าฉลามโดนแพทับหรือไม่
	# =====================================================

	if not is_attacking and not is_retreating:

		push_shark_outside_raft()


	# =====================================================
	# กำลังโจมตี
	# =====================================================

	if is_attacking:

		attack_player(delta)

		return


	# =====================================================
	# กำลังถอย
	# =====================================================

	if is_retreating:

		retreat_from_raft(delta)

		return


	# =====================================================
	# ลดเวลาโจมตี
	# =====================================================

	attack_timer -= delta


	# =====================================================
	# ถึงเวลาโจมตี
	# =====================================================

	if attack_timer <= 0.0:

		start_attack()

		if is_attacking:

			return


	# =====================================================
	# ว่ายรอบแพ
	# =====================================================

	swim_around_raft(delta)


# =========================================================
# FIND DOCK COLLISION
# =========================================================

func find_dock_collision():

	if dock == null:
		return

	dock_collision = dock.find_child(
		"CollisionShape3D",
		true,
		false
	)


# =========================================================
# GET RAFT SIZE
# =========================================================

func get_raft_half_size() -> Vector2:

	if dock_collision == null:

		return Vector2(
			6.0,
			6.0
		)

	var shape = dock_collision.shape

	if not shape is BoxShape3D:

		return Vector2(
			6.0,
			6.0
		)

	var half_x = (
		shape.size.x
		* dock_collision.global_transform.basis.x.length()
		/ 2.0
	)

	var half_z = (
		shape.size.z
		* dock_collision.global_transform.basis.z.length()
		/ 2.0
	)

	return Vector2(
		half_x,
		half_z
	)


# =========================================================
# 🦈 SWIM AROUND RAFT
# =========================================================

func swim_around_raft(delta):

	if dock == null:
		return

	var raft_center = dock.global_position

	var raft_size = get_raft_half_size()

	var radius_x = (
		raft_size.x
		+ raft_margin
	)

	var radius_z = (
		raft_size.y
		+ raft_margin
	)

	var radius = max(
		(radius_x + radius_z) / 2.0,
		1.0
	)

	swim_angle += (
		swim_speed
		/ radius
	) * delta

	var target = raft_center

	target.x += (
		cos(swim_angle)
		* radius_x
	)

	target.z += (
		sin(swim_angle)
		* radius_z
	)

	target = keep_outside_raft(
		target
	)

	var old_position = global_position

	global_position = global_position.move_toward(
		target,
		swim_speed * delta
	)

	var movement_direction = (
		global_position
		- old_position
	)

	rotate_toward_direction(
		movement_direction,
		delta
	)


# =========================================================
# 🛡️ KEEP POSITION OUTSIDE RAFT
# =========================================================

func keep_outside_raft(
	position: Vector3
) -> Vector3:

	if dock_collision == null:
		return position

	var raft_center = dock_collision.global_position

	var raft_size = get_raft_half_size()

	var safe_x = raft_size.x + 1.0
	var safe_z = raft_size.y + 1.0

	var offset = position - raft_center

	# อยู่นอกแพแล้ว
	if (
		abs(offset.x) >= safe_x
		or abs(offset.z) >= safe_z
	):

		return position


	# อยู่ในแพ
	var distance_x = (
		safe_x
		- abs(offset.x)
	)

	var distance_z = (
		safe_z
		- abs(offset.z)
	)


	if distance_x < distance_z:

		if offset.x >= 0:

			position.x = (
				raft_center.x
				+ safe_x
			)

		else:

			position.x = (
				raft_center.x
				- safe_x
			)

	else:

		if offset.z >= 0:

			position.z = (
				raft_center.z
				+ safe_z
			)

		else:

			position.z = (
				raft_center.z
				- safe_z
			)

	return position


# =========================================================
# 🚨 PUSH SHARK OUTSIDE RAFT
# ใช้แก้ตอนอัปเกรดแพแล้วแพทับฉลาม
# =========================================================

func push_shark_outside_raft():

	if dock_collision == null:
		return

	var raft_center = dock_collision.global_position

	var raft_size = get_raft_half_size()

	var safe_x = raft_size.x + 1.0
	var safe_z = raft_size.y + 1.0

	var offset = global_position - raft_center

	# ฉลามอยู่นอกแพแล้ว
	if (
		abs(offset.x) >= safe_x
		or abs(offset.z) >= safe_z
	):

		return


	# =====================================================
	# ฉลามอยู่ในแพ
	# =====================================================

	var distance_x = (
		safe_x
		- abs(offset.x)
	)

	var distance_z = (
		safe_z
		- abs(offset.z)
	)


	if distance_x < distance_z:

		if offset.x >= 0:

			global_position.x = (
				raft_center.x
				+ safe_x
			)

		else:

			global_position.x = (
				raft_center.x
				- safe_x
			)

	else:

		if offset.z >= 0:

			global_position.z = (
				raft_center.z
				+ safe_z
			)

		else:

			global_position.z = (
				raft_center.z
				- safe_z
			)


	# =====================================================
	# รีเซ็ตสถานะ
	# =====================================================

	is_attacking = false
	is_retreating = false

	has_damaged = false

	# เริ่มนับเวลาโจมตีใหม่
	attack_timer = randf_range(
		min_attack_cooldown,
		max_attack_cooldown
	)


# =========================================================
# 🦈 START ATTACK
# =========================================================

func start_attack():

	if player == null:
		return

	if dock == null:
		return


	var raft_center = dock.global_position

	var direction = (
		raft_center
		- global_position
	)

	direction.y = 0


	if direction.length() < 0.1:

		return


	direction = direction.normalized()

	var raft_size = get_raft_half_size()

	var edge_distance = max(
		raft_size.x,
		raft_size.y
	) + 0.8


	var attack_target = (
		raft_center
		+ direction * edge_distance
	)


	# เริ่มโจมตี
	is_attacking = true

	has_damaged = false

	target_position = attack_target

	print(
		"🦈 Shark กำลังพุ่งเข้าโจมตี!"
	)


# =========================================================
# 🦈 ATTACK
# =========================================================

func attack_player(delta):

	if dock == null:

		is_attacking = false

		return


	var old_position = global_position

	var direction = (
		target_position
		- global_position
	)

	direction.y = 0


	if direction.length() < 0.1:

		do_shark_damage()

		finish_attack()

		return


	direction = direction.normalized()


	var movement = (
		direction
		* attack_speed
		* delta
	)

	global_position += movement


	var movement_direction = (
		global_position
		- old_position
	)

	rotate_toward_direction(
		movement_direction,
		delta
	)


	# ตรวจว่าถึงแพหรือยัง
	var distance_to_raft = (
		get_raft_distance()
	)


	if distance_to_raft <= attack_distance:

		do_shark_damage()

		finish_attack()


# =========================================================
# 💥 DAMAGE
# =========================================================

func do_shark_damage():

	if has_damaged:
		return

	has_damaged = true


	if player != null:

		if player.has_method(
			"take_damage"
		):

			player.take_damage(
				damage
			)

			print(
				"🦈 ฉลามกัด! Damage = ",
				damage
			)


# =========================================================
# FINISH ATTACK
# =========================================================

func finish_attack():

	is_attacking = false

	has_damaged = false

	start_retreat()


# =========================================================
# 🏃 START RETREAT
# =========================================================

func start_retreat():

	if dock == null:
		return


	var raft_center = (
		dock.global_position
	)

	var direction = (
		global_position
		- raft_center
	)

	direction.y = 0


	if direction.length() < 0.1:

		direction = Vector3(
			1,
			0,
			0
		)


	direction = direction.normalized()


	retreat_target = (
		global_position
		+ direction
		* retreat_distance
	)


	retreat_target = keep_outside_raft(
		retreat_target
	)


	is_retreating = true


# =========================================================
# 🏃 RETREAT
# =========================================================

func retreat_from_raft(delta):

	var old_position = global_position

	global_position = global_position.move_toward(
		retreat_target,
		retreat_speed * delta
	)

	var movement_direction = (
		global_position
		- old_position
	)

	rotate_toward_direction(
		movement_direction,
		delta
	)


	if global_position.distance_to(
		retreat_target
	) < 0.5:

		is_retreating = false

		attack_timer = randf_range(
			min_attack_cooldown,
			max_attack_cooldown
		)


# =========================================================
# 📏 DISTANCE TO RAFT
# =========================================================

func get_raft_distance() -> float:

	if dock_collision == null:
		return 999.0

	var raft_center = (
		dock_collision.global_position
	)

	var raft_size = get_raft_half_size()

	var dx = abs(
		global_position.x
		- raft_center.x
	)

	var dz = abs(
		global_position.z
		- raft_center.z
	)

	var outside_x = max(
		dx - raft_size.x,
		0.0
	)

	var outside_z = max(
		dz - raft_size.y,
		0.0
	)

	return sqrt(
		outside_x * outside_x
		+ outside_z * outside_z
	)


# =========================================================
# 🔄 ROTATION
# =========================================================

func rotate_toward_direction(
	direction: Vector3,
	delta: float
):

	if direction.length() < 0.01:
		return

	direction.y = 0

	if direction.length() < 0.01:
		return

	direction = direction.normalized()

	var target_angle = atan2(
		direction.x,
		direction.z
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		turn_speed * delta
	)
