extends CanvasLayer

# Variabel ini akan diisi oleh script level sebelumnya (lvl_1.gd / lvl_2.gd)
# JANGAN DIISI MANUAL DI SINI.
var target_level_path: String = ""

func _on_lvl_sel_pressed() -> void:
	# 1. Unpause game dulu
	get_tree().paused = false
	
	# 2. Cek apakah path valid?
	if target_level_path != "":
		# GUNAKAN VARIABEL, JANGAN STRING MANUAL!
		get_tree().change_scene_to_file(target_level_path)
	else:
		print("ERROR: Target Level Path masih kosong! Cek script level anda.")
		# Fallback darurat ke Main Menu kalau error
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	
	# 3. Hapus UI ini
	queue_free()

func _on_ulang_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()
	
func _on_kel_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	queue_free()
