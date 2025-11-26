extends CanvasLayer

@onready var keluar: Button = $VBoxContainer/keluar
@onready var ulangi: Button = $VBoxContainer/ulangi

func _on_keluar_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	queue_free()



func _on_ulangi_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()
	
	
	
