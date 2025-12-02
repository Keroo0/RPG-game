extends CanvasLayer
@onready var sfx_button: AudioStreamPlayer = $SfxButton
@onready var keluar: Button = $VBoxContainer/keluar
@onready var ulangi: Button = $VBoxContainer/ulangi

func _on_keluar_pressed() -> void:
	sfx_button.play()
	await sfx_button.finished
	GameManager.reset_data()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	queue_free()
func _on_ulangi_pressed() -> void:
	sfx_button.play()
	await sfx_button.finished
	GameManager.reset_data()
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()
	
	
	
