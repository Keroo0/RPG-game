extends Control
@onready var pause: Button = $Pause
@onready var counter: Label = $ConCounter/Counter

func update_enemy_count(defeated,total):
	counter.text = str(defeated)+"/"+str(total)

func _on_pause_pressed() -> void:
	get_tree().paused = true
	var MenuPause = load("res://scene/pause_menu.tscn")
	var pause_instance = MenuPause.instantiate()
	add_child(pause_instance)
