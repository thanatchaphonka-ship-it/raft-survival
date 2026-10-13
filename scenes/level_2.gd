extends Node3D

func _ready() -> void:
	# 1. ค้นหา BGMButton ใน CanvasLayer ของฉาก level_2
	var bgm_btn = get_node_or_null("CanvasLayer/BGMButton")
	if bgm_btn == null:
		bgm_btn = get_node_or_null("BGMButton")
		
	if bgm_btn != null:
		# เชื่อมสัญญาณเมื่อกดปุ่ม
		bgm_btn.toggled.connect(_on_bgm_button_toggled)
		
		# อัปเดตหน้าตาปุ่มให้ตรงกับสถานะ Mute ปัจจุบันของ AudioServer
		var bus_idx = AudioServer.get_bus_index("Music")
		if bus_idx != -1:
			bgm_btn.button_pressed = AudioServer.is_bus_mute(bus_idx)

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	# 2. สั่ง ปิด/เปิด เสียง Audio Bus "Music"
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, toggled_on)
