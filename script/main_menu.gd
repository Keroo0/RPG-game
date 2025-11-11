extends Control
@onready var character: TextureRect = $character
@onready var judul: Label = $CenterContainer/wadahTombol/Judul
@onready var mulai: Button = $CenterContainer/wadahTombol/Mulai
@onready var keluar: Button = $CenterContainer/wadahTombol/Keluar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass	

	# --- (Bagian Opsional Animasi Fade-in) ---
	# Tweening ini menggunakan sintaks Godot 4 (create_tween)
	judul.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(judul, "modulate", Color(1, 1, 1, 1), 1.0).set_delay(0.5)
	
	character.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(character, "modulate", Color(1, 1, 1, 1), 1.0).set_delay(1.0)
	
	mulai.modulate = Color(1, 1, 1, 0)
	keluar.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(mulai, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(1.5)
	create_tween().tween_property(keluar, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(1.7)


func _on_keluar_pressed() -> void:
	get_tree().quit()


func _on_mulai_pressed() -> void:
	mulai.disabled = true
	#Transisi.fade_out("res://scene/world.tscn")
	get_tree().change_scene_to_file("res://scene/world.tscn")
