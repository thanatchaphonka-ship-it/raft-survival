extends CharacterBody3D

@export var move_speed: float = 5.0
@export var rotation_speed: float = 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# 1. ระบบแรงดึงดูด ป้องกันตัวละครลอย
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. รับค่ากดปุ่มเดิน (ปุ่มลูกศร หรือ W A S D)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 3. คำนวณการเคลื่อนที่และหมุนตัว
	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		
		# หมุนหน้าตัวละครไปตามทิศทางที่กด
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()
