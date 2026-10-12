extends Control

@onready var play_button: TextureButton = $PlayButton
@onready var how_to_play_button: TextureButton = $HowToPlayButton # เปลี่ยนเป็น TextureButton
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var how_to_play_panel: Control = $HowToPlayPanel
@onready var close_button: Button = $HowToPlayPanel/CloseButton

var play_default_scale: Vector2
var howto_default_scale: Vector2

func _ready() -> void:
	# ตั้งค่า Pivot Offset ปุ่มให้อยู่ตรงกลาง เพื่อให้ขยาย/ย่อสวยงาม
	play_button.pivot_offset = play_button.size / 2.0
	how_to_play_button.pivot_offset = how_to_play_button.size / 2.0
	
	play_default_scale = play_button.scale
	howto_default_scale = how_to_play_button.scale
	
	# เชื่อมสัญญาณปุ่ม Play
	play_button.mouse_entered.connect(_on_play_button_mouse_entered)
	play_button.mouse_exited.connect(_on_play_button_mouse_exited)
	play_button.button_down.connect(_on_play_button_button_down)
	play_button.button_up.connect(_on_play_button_button_up)
	play_button.pressed.connect(_on_play_button_pressed)
	
	# เชื่อมสัญญาณปุ่ม How to Play ( Animation + เปิดหน้าต่าง )
	how_to_play_button.mouse_entered.connect(_on_howto_button_mouse_entered)
	how_to_play_button.mouse_exited.connect(_on_howto_button_mouse_exited)
	how_to_play_button.button_down.connect(_on_howto_button_button_down)
	how_to_play_button.button_up.connect(_on_howto_button_button_up)
	how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
	
	# เชื่อมสัญญาณปุ่ม Close (X)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# ซ่อนหน้าต่างไว้ตอนเริ่มเกม
	how_to_play_panel.visible = false

# ==================== Animation ปุ่ม Play ====================
func _on_play_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", play_default_scale * 1.1, 0.1)

func _on_play_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", play_default_scale, 0.1)

func _on_play_button_button_down() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", play_default_scale * 0.95, 0.05)

func _on_play_button_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(play_button, "scale", play_default_scale * 1.1, 0.05)

# ==================== Animation ปุ่ม How to Play ====================
func _on_howto_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(how_to_play_button, "scale", howto_default_scale * 1.1, 0.1)

func _on_howto_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(how_to_play_button, "scale", howto_default_scale, 0.1)

func _on_howto_button_button_down() -> void:
	var tween = create_tween()
	tween.tween_property(how_to_play_button, "scale", howto_default_scale * 0.95, 0.05)

func _on_howto_button_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(how_to_play_button, "scale", howto_default_scale * 1.1, 0.05)

# ==================== ฟังก์ชันเมื่อกดปุ่มต่างๆ ====================
func _on_play_button_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_how_to_play_button_pressed() -> void:
	click_sound.play() # เล่นเสียงคลิกด้วย
	how_to_play_panel.visible = true

func _on_close_button_pressed() -> void:
	click_sound.play()
	how_to_play_panel.visible = false
