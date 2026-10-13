extends Control

@onready var resume_button: Button = $Background/PausePanel/ResumeButton
@onready var home_button: Button = $Background/PausePanel/HomeButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	resume_button.pressed.connect(resume_game)
	home_button.pressed.connect(go_home)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

		get_viewport().set_input_as_handled()


func pause_game():
	show()
	get_tree().paused = true


func resume_game():
	get_tree().paused = false
	hide()


func go_home():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
