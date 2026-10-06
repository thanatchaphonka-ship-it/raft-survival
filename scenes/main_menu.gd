extends Control

@onready var play_button: TextureButton = $PlayButton
@onready var click_sound: AudioStreamPlayer = $ClickSound # ดึง Node เสียงคลิกเข้ามา

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
