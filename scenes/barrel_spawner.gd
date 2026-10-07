extends Node3D

@export var barrel_scene: PackedScene
@export var spawn_interval := 15.0

func _ready():
	spawn_barrel()

func spawn_barrel():
	if barrel_scene == null:
		return

	var barrel = barrel_scene.instantiate()
	add_child(barrel)

	barrel.global_position = Vector3(
		randf_range(-10.0, 10.0),
		0.0,
		-20.0
	)

	await get_tree().create_timer(spawn_interval).timeout
	spawn_barrel()
