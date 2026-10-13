extends CharacterBody3D

@export var raft_lv2_scene: PackedScene
@export var raft_lv3_scene: PackedScene
@export var raft_lv4_scene: PackedScene

@export var speed := 5.0
@export var gravity := 9.8
@export var fall_death_height := -10.0
@export var jump_velocity := 8.0

@onready var eat_sound: AudioStreamPlayer = $EatSound
@onready var pickup_sound: AudioStreamPlayer = $PickupSound
@onready var animation_player: AnimationPlayer = $"Root Scene/AnimationPlayer"
@onready var player_model: Node3D = $"Root Scene"

@onready var upgrade_sound: AudioStreamPlayer = $UpgradeSound
@onready var shark_attack_sound: AudioStreamPlayer = $SharkAttackSound

# ==================================================
# RAFT
# ==================================================

var wood_count := 0
var max_wood := 100

var raft_level := 1
var max_raft_level := 4

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

var game_time := 80.0
var time_left := 80.0

# ==================================================
# UI
# ==================================================

@onready var wood_count_label: Label = get_tree().current_scene.find_child("WoodCount", true, false)
@onready var food_count_label: Label = get_tree().current_scene.find_child("FoodCount", true, false)

@onready var hunger_bar: ProgressBar = get_tree().current_scene.find_child("HungerBar", true, false)
@onready var health_bar: ProgressBar = get_tree().current_scene.find_child("HealthBar", true, false)

@onready var timer_label: Label = get_tree().current_scene.find_child("TimerLabel", true, false)

@onready var game_over_panel: ColorRect = get_tree().current_scene.find_child("GameOverPanel", true, false)
@onready var restart_button: Button = get_tree().current_scene.find_child("RestartButton", true, false)

@onready var win_panel: ColorRect = get_tree().current_scene.find_child("WinPanel", true, false)
@onready var win_home_button: Button = get_tree().current_scene.find_child("WinHomeButton", true, false)

@onready var upgrade_button: Button = get_tree().current_scene.find_child("UpgradeButton", true, false)
@onready var upgrade_panel: Panel = get_tree().current_scene.find_child("UpgradePanel", true, false)

@onready var level2_button: Button = get_tree().current_scene.find_child("Level2Button", true, false)
@onready var level3_button: Button = get_tree().current_scene.find_child("Level3Button", true, false)
@onready var level4_button: Button = get_tree().current_scene.find_child("Level4Button", true, false)

@onready var close_upgrade_button: Button = get_tree().current_scene.find_child("CloseUpgradeButton", true, false)

@onready var dock: Node3D = get_tree().current_scene.find_child("Dock", true, false)


# ==================================================
# READY
# ==================================================

func _ready():

	if hunger_bar != null:
		hunger_bar.max_value = max_hunger
		hunger_bar.value = hunger

	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = health

	if wood_count_label != null:
		wood_count_label.text = "   x  " + str(wood_count)

	if food_count_label != null:
		food_count_label.text = "   x  " + str(food_count)

	time_left = game_time
	update_timer_ui()

	if game_over_panel != null:
		game_over_panel.visible = false

	if win_panel != null:
		win_panel.visible = false

	if win_home_button != null:
		win_home_button.pressed.connect(_on_win_home_button_pressed)

	if upgrade_panel != null:
		upgrade_panel.visible = false

	if upgrade_button != null:
		upgrade_button.pressed.connect(open_upgrade_panel)

	if level2_button != null:
		level2_button.pressed.connect(upgrade_raft)

	if level3_button != null:
		level3_button.pressed.connect(upgrade_raft)

	if level4_button != null:
		level4_button.pressed.connect(upgrade_raft)

	if close_upgrade_button != null:
		close_upgrade_button.pressed.connect(close_upgrade_panel)

	if restart_button != null:
		restart_button.pressed.connect(restart_game)

	update_upgrade_buttons()
	update_raft_size()


# ==================================================
# TIMER
# ==================================================

func update_timer_ui():

	if timer_label == null:
		return

	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60

	timer_label.text = "%02d:%02d" % [minutes, seconds]


func time_up():

	time_left = 0
	update_timer_ui()

	is_dead = true
	velocity = Vector3.ZERO

	if timer_label != null:
		timer_label.visible = false

	if raft_level >= 4:

		print("🏆 YOU WIN!")

		if win_panel != null:
			win_panel.visible = true

	else:

		print("💀 GAME OVER")

		if game_over_panel != null:
			game_over_panel.visible = true


# ==================================================
# RAFT MODEL
# ==================================================

func update_raft_size():

	var current_dock = get_tree().current_scene.find_child("Dock", true, false)

	if current_dock == null:
		print("⚠️ หา Dock ไม่เจอ")
		return

	var next_scene: PackedScene = null

	if raft_level == 2:
		next_scene = raft_lv2_scene
	elif raft_level == 3:
		next_scene = raft_lv3_scene
	elif raft_level == 4:
		next_scene = raft_lv4_scene

	if next_scene == null:
		return

	var new_dock = next_scene.instantiate()
	new_dock.name = "Dock"
	new_dock.global_transform = current_dock.global_transform

	get_tree().current_scene.add_child(new_dock)
	current_dock.queue_free()

	print("🛶 เปลี่ยนแพเป็น Lv.", raft_level, " สำเร็จ!")


# ==================================================
# WOOD
# ==================================================

func add_wood():

	if wood_count >= max_wood:
		return

	wood_count += 1

	print("🪵 เก็บไม้ได้: ", wood_count)

	if wood_count_label != null:
		wood_count_label.text = "  x  " + str(wood_count)

	update_upgrade_buttons()


# ==================================================
# UPGRADE PANEL
# ==================================================

func open_upgrade_panel():

	if upgrade_panel == null:
		return

	upgrade_panel.visible = true
	update_upgrade_buttons()


func close_upgrade_panel():

	if upgrade_panel == null:
		return

	upgrade_panel.visible = false


# ==================================================
# UPGRADE RAFT
# ==================================================

func upgrade_raft():

	if raft_level >= max_raft_level:
		print("🛶 แพถึง Lv.4 แล้ว")
		update_upgrade_buttons()
		return

	var next_level = raft_level + 1
	var required_wood = raft_upgrade_costs[next_level]

	if wood_count < required_wood:
		print("🪵 ไม้ไม่พอ ต้องการ ", required_wood, " มี ", wood_count)
		return

	wood_count -= required_wood
	raft_level = next_level

	play_upgrade_sound()
	update_raft_size()

	if wood_count_label != null:
		wood_count_label.text = "  x  " + str(wood_count)

	update_upgrade_buttons()

	print("🛶 อัปเกรดแพเป็น Lv.", raft_level)


# ==================================================
# UPGRADE BUTTONS
# ==================================================

func update_upgrade_buttons():

	if level2_button != null:

		level2_button.disabled = raft_level >= 2 or wood_count < 5

		if raft_level >= 2:
			level2_button.text = "Lv.2 - Completed"
		else:
			level2_button.text = "Lv.2 - 5 Wood"

	if level3_button != null:

		level3_button.disabled = raft_level < 2 or raft_level >= 3 or wood_count < 8

		if raft_level >= 3:
			level3_button.text = "Lv.3 - Completed"
		elif raft_level < 2:
			level3_button.text = "Lv.3 - Locked"
		else:
			level3_button.text = "Lv.3 - 8 Wood"

	if level4_button != null:

		level4_button.disabled = raft_level < 3 or raft_level >= 4 or wood_count < 10

		if raft_level >= 4:
			level4_button.text = "Lv.4 - Completed"
		elif raft_level < 3:
			level4_button.text = "Lv.4 - Locked"
		else:
			level4_button.text = "Lv.4 - 10 Wood"


# ==================================================
# FOOD
# ==================================================

func add_food():

	if food_count >= max_food:
		return

	food_count += 1

	print("🍖 เก็บอาหารได้: ", food_count)

	if food_count_label != null:
		food_count_label.text = "  x  " + str(food_count)


func eat_food():

	if food_count <= 0:
		print("ไม่มี Food ให้กิน")
		return

	food_count -= 1
	hunger = min(hunger + 10, max_hunger)

	if eat_sound != null:
		eat_sound.play()

	if food_count_label != null:
		food_count_label.text = "  x  " + str(food_count)

	if hunger_bar != null:
		hunger_bar.value = hunger

	print("🍖 กินอาหารแล้ว Hunger = ", hunger)


# ==================================================
# PHYSICS, MOVEMENT & JUMP
# ==================================================

func _physics_process(delta):

	if is_dead:
		velocity = Vector3.ZERO
		return

	# GAME TIMER
	time_left -= delta

	if time_left <= 0:
		time_up()
		return

	update_timer_ui()

	# HUNGER
	hunger_timer += delta

	if hunger_timer >= hunger_interval:

		hunger_timer = 0.0

		if hunger > 0:
			hunger -= 1

			if hunger_bar != null:
				hunger_bar.value = hunger

		if hunger <= 0:

			health = max(health - 1, 0)

			if health_bar != null:
				health_bar.value = health

		elif hunger > 70:

			health = min(health + 1, max_health)

			if health_bar != null:
				health_bar.value = health

		if health <= 0:
			show_game_over()
			return

	# EAT FOOD
	if Input.is_action_just_pressed("eat_food"):
		eat_food()

	# MOVEMENT INPUT
	var input = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction = Vector3(input.x, 0, -input.y)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# ROTATE PLAYER MODEL
	if direction.length() > 0.1 and player_model != null:

		var target_rotation = atan2(direction.x, direction.z)

		player_model.rotation.y = lerp_angle(
			player_model.rotation.y,
			target_rotation,
			10.0 * delta
		)

	# GRAVITY & JUMP — ทำงานเพียงจุดเดียว
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_velocity
	else:
		velocity.y = 0.0

	move_and_slide()

	# FALL OFF RAFT
	if global_position.y <= fall_death_height:
		show_game_over()
		return

	# ANIMATION
	if animation_player != null:

		if direction.length() > 0.1:

			if animation_player.current_animation != "Walk":
				animation_player.play("Walk")

		else:
			animation_player.stop()


# ==================================================
# GAME OVER
# ==================================================

func show_game_over():

	if is_dead:
		return

	is_dead = true
	velocity = Vector3.ZERO

	if timer_label != null:
		timer_label.visible = false

	if game_over_panel != null:
		game_over_panel.visible = true

	print("💀 GAME OVER")


func take_damage(amount: int):

	if is_dead:
		return

	health = max(health - amount, 0)

	if health_bar != null:
		health_bar.value = health

	print("🦈 โดนฉลามโจมตี! Health เหลือ = ", health)

	if health <= 0:
		show_game_over()


# ==================================================
# RESTART
# ==================================================

func restart_game():

	get_tree().reload_current_scene()


# ==================================================
# HOME BUTTONS
# ==================================================

func _on_home_button_pressed() -> void:

	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_win_home_button_pressed() -> void:

	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ==================================================
# SOUND
# ==================================================

func play_pickup_sound():

	if pickup_sound != null:
		pickup_sound.play()


func play_upgrade_sound():

	if upgrade_sound != null:
		upgrade_sound.play()


func play_shark_attack_sound():

	if shark_attack_sound != null:
		shark_attack_sound.play()


# ==================================================
# NEXT LEVEL BUTTON
# ==================================================

func _on_next_level_button_pressed() -> void:

	get_tree().change_scene_to_file("res://scenes/level_2.tscn")
