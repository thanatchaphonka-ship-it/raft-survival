extends Node

func _ready() -> void:
	# ค้นหา BGMButton ใน CanvasLayer แล้วเชื่อมต่อสัญญาณ
	var bgm_btn = get_node_or_null("CanvasLayer/BGMButton")
	if bgm_btn == null:
		bgm_btn = get_node_or_null("BGMButton")
		
	if bgm_btn != null:
		bgm_btn.toggled.connect(_on_bgm_button_toggled)

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	print("CLICKED! Mute status: ", toggled_on)
	
	# ปิด/เปิดเสียงผ่าน Audio Bus ชื่อ "Music"
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, toggled_on)
