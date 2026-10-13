extends Area3D

# =========================================================
# 🦈 SHARK SETTINGS
# =========================================================

@export var swim_speed: float = 2.5
@export var swim_direction: float = 1.0
@export var raft_margin: float = 8.0
@export var attack_speed: float = 9.0
@export var attack_distance: float = 1.2
@export var min_attack_cooldown: float = 5.0
@export var max_attack_cooldown: float = 8.0
@export var damage: int = 17
@export var turn_speed: float = 5.0
@export var retreat_distance: float = 10.0
@export var retreat_speed: float = 5.0


# =========================================================
# REFERENCES
# =========================================================

var player: Node3D = null
var dock: Node3D = null
var dock_collision: CollisionShape3D = null

@onready var shark_attack_sound: AudioStreamPlayer = get_node_or_null(
    "SharkAttackSound"
)


# =========================================================
# SHARK STATE
# =========================================================

var swim_angle: float = 0.0

var is_attacking: bool = false
var is_retreating: bool = false
var has_damaged: bool = false

var attack_timer: float = 3.0

var target_position: Vector3 = Vector3.ZERO
var retreat_target: Vector3 = Vector3.ZERO


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	randomize()

	player = get_tree().current_scene.find_child(
		"PlayerController", true, false
	)

	dock = get_tree().current_scene.find_child(
		"Dock", true, false
	)

	find_dock_collision()

	attack_timer = 3.0

	if player == null:
		print("⚠️ Shark หา PlayerController ไม่เจอ")

	if dock == null:
		print("⚠️ Shark หา Dock ไม่เจอ")

	if dock_collision == null:
		print("⚠️ Shark หา CollisionShape3D ของ Dock ไม่เจอ")
	else:
		print("✅ Shark เจอ CollisionShape3D ของ Dock แล้ว")

		# ปรับตำแหน่งเริ่มต้นให้อยู่นอกแพ
		push_shark_outside_raft()

		# คำนวณมุมว่ายจากตำแหน่งจริงของฉลาม
		update_swim_angle_from_position()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().current_scene.find_child(
			"PlayerController", true, false
		)

		if player == null:
			return

	if dock == null or not is_instance_valid(dock):
		dock = get_tree().current_scene.find_child(
			"Dock", true, false
		)
		dock_collision = null

	if dock_collision == null or not is_instance_valid(dock_collision):
		find_dock_collision()

	if dock == null:
		return

	# ขณะว่ายวน ถ้าฉลามถูกแพขยายมาทับ ให้ดันออก
	if not is_attacking and not is_retreating:
		push_shark_outside_raft()

	if is_attacking:
		attack_player(delta)
		return

	if is_retreating:
		retreat_from_raft(delta)
		return

	attack_timer -= delta

	if attack_timer <= 0.0:
		start_attack()

		if is_attacking:
			return

	swim_around_raft(delta)


# =========================================================
# FIND DOCK COLLISION
# =========================================================

func find_dock_collision() -> void:
	if dock == null:
		return

	dock_collision = dock.find_child(
		"CollisionShape3D", true, false
	)


# =========================================================
# GET RAFT SIZE
# =========================================================

func get_raft_half_size() -> Vector2:
	if dock_collision == null or not is_instance_valid(dock_collision):
		return Vector2(4.0, 4.0)

	var shape = dock_collision.shape

	if shape is BoxShape3D:
		var global_scale = dock_collision.global_transform.basis.get_scale()

		var half_x = shape.size.x * abs(global_scale.x) / 2.0
		var half_z = shape.size.z * abs(global_scale.z) / 2.0

		return Vector2(half_x, half_z)

	return Vector2(4.0, 4.0)


# =========================================================
# UPDATE SWIM ANGLE
# =========================================================

func update_swim_angle_from_position() -> void:
	if dock_collision == null:
		return

	var center = dock_collision.global_position
	var raft_size = get_raft_half_size()

	var radius_x = max(raft_size.x + raft_margin, 1.0)
	var radius_z = max(raft_size.y + raft_margin, 1.0)

	var offset = global_position - center

	# ใช้ตำแหน่งปัจจุบันคำนวณมุม
	swim_angle = atan2(
		offset.z / radius_z,
		offset.x / radius_x
	)


# =========================================================
# 🦈 SWIM AROUND RAFT
# =========================================================

func swim_around_raft(delta: float) -> void:
	if dock == null:
		return

	var raft_center = dock.global_position
	var raft_size = get_raft_half_size()

	var radius_x = raft_size.x + raft_margin
	var radius_z = raft_size.y + raft_margin

	var radius = max((radius_x + radius_z) / 2.0, 1.0)

	swim_angle += (
		swim_direction * swim_speed / radius
	) * delta

	var target = raft_center

	target.x += cos(swim_angle) * radius_x
	target.z += sin(swim_angle) * radius_z

	target = keep_outside_raft(target)

	var old_position = global_position

	global_position = global_position.move_toward(
		target, swim_speed * delta
	)

	var movement_direction = global_position - old_position

	rotate_toward_direction(movement_direction, delta)


# =========================================================
# 🛡️ KEEP POSITION OUTSIDE RAFT
# =========================================================

func keep_outside_raft(position: Vector3) -> Vector3:
	if dock_collision == null:
		return position

	var raft_center = dock_collision.global_position
	var raft_size = get_raft_half_size()

	var safe_x = raft_size.x + 1.0
	var safe_z = raft_size.y + 1.0

	var offset = position - raft_center

	if abs(offset.x) >= safe_x or abs(offset.z) >= safe_z:
		return position

	var distance_x = safe_x - abs(offset.x)
	var distance_z = safe_z - abs(offset.z)

	if distance_x < distance_z:
		position.x = raft_center.x + safe_x * (1.0 if offset.x >= 0.0 else -1.0)
	else:
		position.z = raft_center.z + safe_z * (1.0 if offset.z >= 0.0 else -1.0)

	return position


# =========================================================
# 🚨 PUSH SHARK OUTSIDE RAFT
# =========================================================

func push_shark_outside_raft() -> void:
	if dock_collision == null or not is_instance_valid(dock_collision):
		return

	var raft_center = dock_collision.global_position
	var raft_size = get_raft_half_size()

	var safe_x = raft_size.x + 1.0
	var safe_z = raft_size.y + 1.0

	var offset = global_position - raft_center

	if abs(offset.x) >= safe_x or abs(offset.z) >= safe_z:
		return

	var distance_x = safe_x - abs(offset.x)
	var distance_z = safe_z - abs(offset.z)

	if distance_x < distance_z:
		global_position.x = raft_center.x + safe_x * (1.0 if offset.x >= 0.0 else -1.0)
	else:
		global_position.z = raft_center.z + safe_z * (1.0 if offset.z >= 0.0 else -1.0)

	# คำนวณมุมใหม่หลังขยับตำแหน่ง
	update_swim_angle_from_position()


# =========================================================
# 🦈 START ATTACK
# =========================================================

func start_attack() -> void:
	if player == null or dock == null:
		return

	var raft_center = dock.global_position
	var raft_size = get_raft_half_size()

	# ทิศจากกลางแพออกไปหาฉลาม
	var outward = global_position - raft_center
	outward.y = 0.0

	if outward.length() < 0.1:
		outward = Vector3(1.0, 0.0, 0.0)

	outward = outward.normalized()

	# เลือกขอบแพด้านที่ฉลามอยู่
	var edge_x = raft_size.x + 0.8
	var edge_z = raft_size.y + 0.8

	var target_offset = Vector3.ZERO

	if abs(outward.x) > abs(outward.z):
		target_offset.x = sign(outward.x) * edge_x
		target_offset.z = outward.z / max(abs(outward.x), 0.001) * edge_x
	else:
		target_offset.z = sign(outward.z) * edge_z
		target_offset.x = outward.x / max(abs(outward.z), 0.001) * edge_z

	target_position = raft_center + target_offset
	target_position.y = global_position.y

	is_attacking = true
	has_damaged = false

	print("🦈 Shark กำลังพุ่งเข้าโจมตี!")


# =========================================================
# 🦈 ATTACK
# =========================================================

func attack_player(delta: float) -> void:
	if dock == null:
		is_attacking = false
		return

	var old_position = global_position

	var direction = target_position - global_position
	direction.y = 0.0

	# ถึงจุดโจมตีแล้ว
	if direction.length() <= attack_distance:
		do_shark_damage()
		play_shark_attack_sound()
		finish_attack()
		return

	direction = direction.normalized()

	global_position += direction * attack_speed * delta

	var movement_direction = global_position - old_position
	rotate_toward_direction(movement_direction, delta)

	# ตรวจระยะห่างจากขอบแพ
	if get_raft_distance() <= attack_distance:
		do_shark_damage()
		play_shark_attack_sound()
		finish_attack()


# =========================================================
# 💥 DAMAGE
# =========================================================

func do_shark_damage() -> void:
	if has_damaged:
		return

	has_damaged = true

	if player != null and player.has_method("take_damage"):
		player.take_damage(damage)
		print("🦈 ฉลามกัด! Damage = ", damage)


# =========================================================
# FINISH ATTACK
# =========================================================

func finish_attack() -> void:
	is_attacking = false
	start_retreat()


# =========================================================
# 🏃 START RETREAT
# =========================================================

func start_retreat() -> void:
	if dock == null:
		return

	var raft_center = dock.global_position

	var retreat_dir = global_position - raft_center
	retreat_dir.y = 0.0

	if retreat_dir.length() < 0.1:
		retreat_dir = Vector3(1.0, 0.0, 0.0)

	retreat_dir = retreat_dir.normalized()

	retreat_target = global_position + retreat_dir * retreat_distance
	retreat_target = keep_outside_raft(retreat_target)

	is_attacking = false
	is_retreating = true

	print("🦈 ฉลามว่ายถอยออกจากแพ!")


# =========================================================
# 🏃 RETREAT
# =========================================================

func retreat_from_raft(delta: float) -> void:
	var old_position = global_position

	global_position = global_position.move_toward(
		retreat_target, retreat_speed * delta
	)

	var movement_direction = global_position - old_position
	rotate_toward_direction(movement_direction, delta)

	if global_position.distance_to(retreat_target) < 0.5:
		is_retreating = false
		has_damaged = false

		attack_timer = randf_range(
			min_attack_cooldown,
			max_attack_cooldown
		)

		# ตั้งมุมว่ายใหม่ตามตำแหน่งหลังถอย
		update_swim_angle_from_position()


# =========================================================
# 📏 DISTANCE TO RAFT
# =========================================================

func get_raft_distance() -> float:
	if dock_collision == null:
		return 999.0

	var raft_center = dock_collision.global_position
	var raft_size = get_raft_half_size()

	var dx = abs(global_position.x - raft_center.x)
	var dz = abs(global_position.z - raft_center.z)

	var outside_x = max(dx - raft_size.x, 0.0)
	var outside_z = max(dz - raft_size.y, 0.0)

	return sqrt(outside_x * outside_x + outside_z * outside_z)


# =========================================================
# 🔄 ROTATION
# =========================================================

func rotate_toward_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0.0

	if direction.length() < 0.01:
		return

	direction = direction.normalized()

	var target_angle = atan2(direction.x, direction.z)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		turn_speed * delta
	)


# =========================================================
# 🔊 SHARK ATTACK SOUND
# =========================================================

func play_shark_attack_sound() -> void:
	if player != null and player.has_method("play_shark_attack_sound"):
		player.play_shark_attack_sound()
	elif shark_attack_sound != null:
		shark_attack_sound.play()
