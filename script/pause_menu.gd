extends CanvasLayer
@onready var lanjut: Button = $MarginContainer/pause/Lanjut
@onready var main_menu: Button = $MarginContainer/pause/MainMenu
@onready var sfx_button: AudioStreamPlayer = $SfxButton



func _on_lanjut_pressed() -> void:
	sfx_button.play()
	await sfx_button.finished # Tunggu suara selesai
	get_tree().paused = false
	queue_free()
	

func _on_main_menu_pressed() -> void:
	sfx_button.play()
	await sfx_button.finished
	get_tree().paused = false
	GameManager.reset_data() # Reset data dulu
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
