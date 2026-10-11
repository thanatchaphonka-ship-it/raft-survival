extends Control

@onready var play_button: TextureButton = $PlayButton
@onready var click_sound: AudioStreamPlayer = $ClickSound # ดึง Node เสียงคลิกเข้ามา
@onready var how_to_play_button: Button = $HowToPlayButton
@onready var how_to_play_panel: Control = $HowToPlayPanel
@onready var close_button: Button = $HowToPlayPanel/CloseButton # หรือ $HowToPlayPanel/HowToPlayImage/CloseButton

var default_scale: Vector2

func _ready() -> void:
	default_scale = play_button.scale
	play_button.pivot_offset = play_button.size / 2.0
	
	play_button.mouse_entered.connect(_on_play_button_mouse_entered)
	play_button.mouse_exited.connect(_on_play_button_mouse_exited)
	play_button.button_down.connect(_on_play_button_button_down)
	play_button.button_up.connect(_on_play_button_button_up)

func _on_play_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", default_scale * 1.1, 0.1)

func _on_play_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", default_scale, 0.1)

func _on_play_button_button_down() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", default_scale * 0.95, 0.05)

func _on_play_button_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", default_scale * 1.1, 0.05)

# เมื่อกดปุ่ม Play
func _on_play_button_pressed() -> void:
	click_sound.play() # 1. เล่นเสียงคลิก
	await click_sound.finished # 2. รอจนกว่าเสียงคลิกจะเล่นจบ
	get_tree().change_scene_to_file("res://scenes/main.tscn") # 3. สลับไปหน้าเกม
	

	# ซ่อนหน้าต่างวิธีเล่นไว้ก่อน
	how_to_play_panel.visible = false
	
	# 2. เชื่อมต่อสัญญาณการกดปุ่ม
	how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

# 3. เมื่อกดปุ่ม How to Play -> สั่งให้หน้าต่างเด้งขึ้นมา
func _on_how_to_play_button_pressed():
	how_to_play_panel.visible = true

# 4. เมื่อกดปุ่ม X -> สั่งปิดหน้าต่างกลับไปหน้าเมนู
func _on_close_button_pressed():
	how_to_play_panel.visible = false
