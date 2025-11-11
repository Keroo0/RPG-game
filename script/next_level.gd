extends CanvasLayer

var target_level_path: String

func _on_lvl_sel_pressed() -> void:
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scene/lvl_2.tscn")

func _on_ulang_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()
	
func _on_kel_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
