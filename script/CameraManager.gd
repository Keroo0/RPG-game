extends Camera2D

func _ready():
	# Ambil nama file level yang sedang aktif
	var current_level = get_tree().current_scene.scene_file_path
	
	# Reset Limit Kiri & Atas (Selalu 0)
	limit_left = 0
	limit_top = 0
	
	# --- LOGIKA BATAS (HARDCODED) ---
	
	# LEVEL 1
	if "world.tscn" in current_level or "lvl_1.tscn" in current_level or "level1.tscn" in current_level:
		limit_right = 1161
		limit_bottom = 649
		print("[Camera] Mode: Level 1 (Luas)")
		
	# LEVEL 2 (Angka dari screenshotmu)
	elif "lvl_2.tscn" in current_level:
		limit_right = 640
		limit_bottom = 470
		print("[Camera] Mode: Level 2 (Kecil)")
		
	# LEVEL 3 (Persiapan)
	elif "lvl_3.tscn" in current_level:
		limit_right = 1161
		limit_bottom = 649
