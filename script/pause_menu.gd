extends CanvasLayer
@onready var lanjut: Button = $MarginContainer/pause/Lanjut
@onready var main_menu: Button = $MarginContainer/pause/MainMenu



func _on_lanjut_pressed() -> void:
	get_tree().paused = false
	queue_free()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
