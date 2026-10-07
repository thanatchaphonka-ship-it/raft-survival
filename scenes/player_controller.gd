extends CharacterBody3D

@export var speed := 5.0
@export var gravity := 9.8
@export var fall_death_height := -10.0

# ==================================================
# RAFT
# ==================================================

var wood_count := 0
var max_wood := 100

var raft_level := 1
var max_raft_level := 4

# ราคาการอัปเกรดแพ
var raft_upgrade_costs = {
	2: 5,
	3: 8,
	4: 10
}

# ==================================================
# FOOD
# ==================================================

var food_count := 0
var max_food := 100

# ==================================================
# HUNGER
# ==================================================

var hunger := 100
var max_hunger := 100

var hunger_timer := 0.0
var hunger_interval := 0.8

# ==================================================
# HEALTH
# ==================================================

var health := 100
var max_health := 100
var is_dead := false

# ==================================================
# GAME TIMER
# ==================================================

var game_time := 90.0
var time_left := 90.0

# ==================================================
# NODE
# ==================================================

@onready var animation_player: AnimationPlayer = $"Root Scene/AnimationPlayer"
@onready var player_model: Node3D = $"Root Scene"

# ==================================================
# UI
# ==================================================

@onready var wood_count_label: Label = get_tree().current_scene.find_child("WoodCount", true, false)
@onready var food_count_label: Label = get_tree().current_scene.find_child("FoodCount", true, false)

@onready var hunger_bar: ProgressBar = get_tree().current_scene.find_child("HungerBar", true, false)
@onready var health_bar: ProgressBar = get_tree().current_scene.find_child("HealthBar", true, false)

# Timer
@onready var timer_label: Label = get_tree().current_scene.find_child("TimerLabel", true, false)

# Game Over
@onready var game_over_panel: ColorRect = get_tree().current_scene.find_child("GameOverPanel", true, false)
@onready var restart_button: Button = get_tree().current_scene.find_child("RestartButton", true, false)

# Win
@onready var win_panel: ColorRect = get_tree().current_scene.find_child("WinPanel", true, false)
@onready var win_home_button: Button = get_tree().current_scene.find_child("WinHomeButton", true, false)

# ==================================================
# UPGRADE UI
# ==================================================

@onready var upgrade_button: Button = get_tree().current_scene.find_child("UpgradeButton", true, false)
@onready var upgrade_panel: Panel = get_tree().current_scene.find_child("UpgradePanel", true, false)

@onready var level2_button: Button = get_tree().current_scene.find_child("Level2Button", true, false)
@onready var level3_button: Button = get_tree().current_scene.find_child("Level3Button", true, false)
@onready var level4_button: Button = get_tree().current_scene.find_child("Level4Button", true, false)

@onready var close_upgrade_button: Button = get_tree().current_scene.find_child("CloseUpgradeButton", true, false)

# ==================================================
# DOCK
# ==================================================

@onready var dock: Node3D = get_tree().current_scene.find_child("Dock", true, false)

# ==================================================
# READY
# ==================================================

func _ready():

	# =========================
	# Hunger Bar
	# =========================

	if hunger_bar != null:
		hunger_bar.max_value = max_hunger
		hunger_bar.value = hunger

	# =========================
	# Health Bar
	# =========================

	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = health

	# =========================
	# Wood UI
	# =========================

	if wood_count_label != null:
		wood_count_label.text = "Wood : " + str(wood_count)

	# =========================
	# Food UI
	# =========================

	if food_count_label != null:
		food_count_label.text = "Food : " + str(food_count)

	# =========================
	# Game Timer
	# =========================

	time_left = game_time
	update_timer_ui()

	# =========================
	# Game Over
	# =========================

	if game_over_panel != null:
		game_over_panel.visible = false

	# =========================
	# Win Panel
	# =========================

	if win_panel != null:
		win_panel.visible = false

	# =========================
	# Win Home Button
	# =========================

	if win_home_button != null:
		win_home_button.pressed.connect(_on_win_home_button_pressed)

	# =========================
	# Upgrade Panel
	# =========================

	if upgrade_panel != null:
		upgrade_panel.visible = false

	# =========================
	# Upgrade Button
	# =========================

	if upgrade_button != null:
		upgrade_button.pressed.connect(open_upgrade_panel)

	# =========================
	# Upgrade Level Buttons
	# =========================

	if level2_button != null:
		level2_button.pressed.connect(upgrade_raft)

	if level3_button != null:
		level3_button.pressed.connect(upgrade_raft)

	if level4_button != null:
		level4_button.pressed.connect(upgrade_raft)

	# =========================
	# Close Upgrade Button
	# =========================

	if close_upgrade_button != null:
		close_upgrade_button.pressed.connect(close_upgrade_panel)

	# =========================
	# Restart Button
	# =========================

	if restart_button != null:
		restart_button.pressed.connect(restart_game)

	# =========================
	# อัปเดตปุ่ม Upgrade
	# =========================

	update_upgrade_buttons()

	# =========================
	# ตั้งขนาดแพเริ่มต้น
	# =========================

	update_raft_size()


# ==================================================
# GAME TIMER
# ==================================================

func update_timer_ui():

	if timer_label == null:
		return

	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60

	timer_label.text = "%02d:%02d" % [minutes, seconds]


# ==================================================
# หมดเวลา
# ==================================================

func time_up():

	time_left = 0
	update_timer_ui()

	is_dead = true
	velocity = Vector3.ZERO

	# ซ่อน Timer

	if timer_label != null:
		timer_label.visible = false

	# =========================
	# เช็กว่าแพถึง Lv.4 หรือยัง
	# =========================

	if raft_level >= 4:

		print("🏆 YOU WIN!")

		if win_panel != null:
			win_panel.visible = true

	else:

		print("💀 GAME OVER")

		if game_over_panel != null:
			game_over_panel.visible = true


# ==================================================
# เปลี่ยนขนาดแพตาม Level
# ==================================================

func update_raft_size():

	if dock == null:
		print("⚠️ หา Dock ไม่เจอ")
		return

	if raft_level == 1:

		dock.scale = Vector3(
			3.0,
			3.0,
			3.0
		)

	elif raft_level == 2:

		dock.scale = Vector3(
			4.5,
			3.0,
			4.5
		)

	elif raft_level == 3:

		dock.scale = Vector3(
			6.0,
			3.0,
			6.0
		)

	elif raft_level == 4:

		dock.scale = Vector3(
			7.5,
			3.0,
			7.5
		)

	print(
		"🛶 Raft Level:",
		raft_level,
		" | Scale:",
		dock.scale
	)


# ==================================================
# เก็บไม้
# ==================================================

func add_wood():

	if wood_count >= max_wood:
		return

	wood_count += 1

	print(
		"🪵 เก็บไม้ได้: ",
		wood_count
	)

	if wood_count_label != null:
		wood_count_label.text = "Wood : " + str(wood_count)

	update_upgrade_buttons()


# ==================================================
# เปิดหน้าต่าง Upgrade
# ==================================================

func open_upgrade_panel():

	if upgrade_panel == null:
		return

	upgrade_panel.visible = true

	update_upgrade_buttons()

	print("🛶 เปิดหน้าต่างอัปเกรดแพ")


# ==================================================
# ปิดหน้าต่าง Upgrade
# ==================================================

func close_upgrade_panel():

	if upgrade_panel == null:
		return

	upgrade_panel.visible = false


# ==================================================
# อัปเกรดแพ
# ==================================================

func upgrade_raft():

	if raft_level >= max_raft_level:

		print("🛶 แพถึง Lv.4 แล้ว")

		update_upgrade_buttons()

		return

	var next_level = raft_level + 1

	var required_wood = raft_upgrade_costs[next_level]

	if wood_count < required_wood:

		print(
			"🪵 ไม้ไม่พอ | ต้องการ ",
			required_wood,
			" | มี ",
			wood_count
		)

		return

	# หักไม้
	wood_count -= required_wood

	# เพิ่ม Level
	raft_level = next_level

	# เปลี่ยนขนาดแพ
	update_raft_size()

	print(
		"🛶 อัปเกรดแพเป็น Lv.",
		raft_level
	)

	print(
		"🪵 ใช้ไม้:",
		required_wood
	)

	print(
		"🪵 ไม้เหลือ:",
		wood_count
	)

	# อัปเดต Wood UI
	if wood_count_label != null:
		wood_count_label.text = "Wood : " + str(wood_count)

	# อัปเดตปุ่ม
	update_upgrade_buttons()


# ==================================================
# อัปเดตสถานะปุ่ม Upgrade
# ==================================================

func update_upgrade_buttons():

	# =========================
	# Lv.2 = 5 Wood
	# =========================

	if level2_button != null:

		if raft_level >= 2:

			level2_button.disabled = true
			level2_button.text = "Lv.2  -  Completed"

		elif wood_count < 5:

			level2_button.disabled = true
			level2_button.text = "Lv.2  -  5 Wood"

		else:

			level2_button.disabled = false
			level2_button.text = "Lv.2  -  5 Wood"


	# =========================
	# Lv.3 = 8 Wood
	# =========================

	if level3_button != null:

		if raft_level < 2:

			level3_button.disabled = true
			level3_button.text = "Lv.3  -  Locked"

		elif raft_level >= 3:

			level3_button.disabled = true
			level3_button.text = "Lv.3  -  Completed"

		elif wood_count < 8:

			level3_button.disabled = true
			level3_button.text = "Lv.3  -  8 Wood"

		else:

			level3_button.disabled = false
			level3_button.text = "Lv.3  -  8 Wood"


	# =========================
	# Lv.4 = 10 Wood
	# =========================

	if level4_button != null:

		if raft_level < 3:

			level4_button.disabled = true
			level4_button.text = "Lv.4  -  Locked"

		elif raft_level >= 4:

			level4_button.disabled = true
			level4_button.text = "Lv.4  -  Completed"

		elif wood_count < 10:

			level4_button.disabled = true
			level4_button.text = "Lv.4  -  10 Wood"

		else:

			level4_button.disabled = false
			level4_button.text = "Lv.4  -  10 Wood"


# ==================================================
# เก็บ Food
# ==================================================

func add_food():

	print(
		"🍖 add_food ถูกเรียก | Food ก่อนเพิ่ม = ",
		food_count
	)

	if food_count >= max_food:
		return

	food_count += 1

	print(
		"🍖 Food หลังเพิ่ม = ",
		food_count
	)

	if food_count_label != null:
		food_count_label.text = "Food : " + str(food_count)


# ==================================================
# กิน Food
# ==================================================

func eat_food():

	if food_count <= 0:

		print("ไม่มี Food ให้กิน")

		return

	food_count -= 1

	hunger += 10

	if hunger > max_hunger:
		hunger = max_hunger

	print(
		"🍖 กิน Food! Food เหลือ = ",
		food_count,
		" | Hunger = ",
		hunger
	)

	if food_count_label != null:
		food_count_label.text = "Food : " + str(food_count)

	if hunger_bar != null:
		hunger_bar.value = hunger


# ==================================================
# PHYSICS
# ==================================================

func _physics_process(delta):

	# ==================================================
	# ถ้าจบเกมแล้ว
	# ==================================================

	if is_dead:

		velocity = Vector3.ZERO

		return


	# ==================================================
	# GAME TIMER
	# ==================================================

	time_left -= delta

	if time_left <= 0:

		time_up()

		return

	update_timer_ui()


	# ==================================================
	# Hunger Timer
	# ==================================================

	hunger_timer += delta

	if hunger_timer >= hunger_interval:

		hunger_timer = 0.0

		if hunger > 0:

			hunger -= 1

			if hunger_bar != null:
				hunger_bar.value = hunger

			print(
				"Hunger ลดลงเหลือ: ",
				hunger
			)


		if hunger <= 0:

			health -= 1

			if health < 0:
				health = 0

			if health_bar != null:
				health_bar.value = health

			print(
				"❤️ Health ลดลงเหลือ: ",
				health
			)


		elif hunger > 70:

			health += 1

			if health > max_health:
				health = max_health

			if health_bar != null:
				health_bar.value = health

			print(
				"💚 Health ฟื้นฟูเป็น: ",
				health
			)


		# Health = 0 → Game Over

		if health <= 0:

			health = 0

			is_dead = true

			print("💀 GAME OVER")

			if timer_label != null:
				timer_label.visible = false

			if game_over_panel != null:
				game_over_panel.visible = true

			velocity = Vector3.ZERO

			return


	# ==================================================
	# กด E กิน Food
	# ==================================================

	if Input.is_action_just_pressed("eat_food"):

		eat_food()


	# ==================================================
	# Movement
	# ==================================================

	var input = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction = Vector3(
		input.x,
		0,
		-input.y
	)


	# ==================================================
	# เดิน
	# ==================================================

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


	# ==================================================
	# หมุนเฉพาะตัวละคร
	# ==================================================

	if direction.length() > 0.1:

		var target_rotation = atan2(
			direction.x,
			direction.z
		)

		player_model.rotation.y = lerp_angle(
			player_model.rotation.y,
			target_rotation,
			10.0 * delta
		)


	# ==================================================
	# Gravity
	# ==================================================

	if not is_on_floor():

		velocity.y -= gravity * delta

	else:

		velocity.y = 0


	move_and_slide()


	# ==================================================
	# ตกจากแพ = ตาย
	# ==================================================

	if global_position.y <= fall_death_height:

		is_dead = true

		print("💀 ตกจากแพ! GAME OVER")

		velocity = Vector3.ZERO

		if timer_label != null:
			timer_label.visible = false

		if game_over_panel != null:
			game_over_panel.visible = true

		return


	# ==================================================
	# Animation
	# ==================================================

	if direction.length() > 0:

		if animation_player.current_animation != "Walk":

			animation_player.play("Walk")

	else:

		animation_player.stop()


# ==================================================
# โดนฉลามโจมตี
# ==================================================

func take_damage(amount: int):

	if is_dead:
		return

	health -= amount

	if health < 0:
		health = 0

	if health_bar != null:
		health_bar.value = health

	print(
		"🦈 โดนฉลามโจมตี! Health เหลือ = ",
		health
	)

	if health <= 0:

		is_dead = true

		print("💀 GAME OVER")

		if timer_label != null:
			timer_label.visible = false

		if game_over_panel != null:
			game_over_panel.visible = true

		velocity = Vector3.ZERO


# ==================================================
# RESTART GAME
# ==================================================

func restart_game():

	print("🔄 Restart Game")

	get_tree().reload_current_scene()


# ==================================================
# HOME BUTTON - GAME OVER
# ==================================================

func _on_home_button_pressed() -> void:

	get_tree().change_scene_to_file(
		"res://scenes/main_menu.tscn"
	)


# ==================================================
# HOME BUTTON - YOU WIN
# ==================================================

func _on_win_home_button_pressed() -> void:

	print("🏠 กลับหน้า Main Menu")

	get_tree().change_scene_to_file(
		"res://scenes/main_menu.tscn"
	)
