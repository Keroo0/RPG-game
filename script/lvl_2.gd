extends Node2D

# --- KONFIGURASI LEVEL ---
@export var next_level_path: String = "res://scene/lvl_3.tscn" 

# --- REFERENSI ---
@onready var status_game: Control = $CanvasLayer/StatusGame

# --- VARIABEL ---
var total_enemies: int = 0
var enemies_defeated: int = 0

func _ready():
	# 1. Refill Darah
	if GameManager:
		GameManager.refill_health()
	
	# ---------------------------------------------------------
	# LOGIKA GANTI GAMBAR (HARDCODED)
	# Kita cek nama file scene ini.
	# ---------------------------------------------------------
	var current_scene_file = scene_file_path # Mendapatkan path penuh (res://scene/lvl_2.tscn)
	
	var path_gambar = ""
	
	# CEK LEVEL 1 (Sesuaikan dengan nama file scene kamu!)
	if "world.tscn" in current_scene_file or "lvl_1.tscn" in current_scene_file or "level1.tscn" in current_scene_file:
		# GANTI PATH INI DENGAN LOKASI GAMBAR SLIME KAMU
		path_gambar =  "res://arts/chara/processed_image.png"
		
	# CEK LEVEL 2
	elif "lvl_2.tscn" in current_scene_file:
		# Path Vampir yang kamu kirim tadi
		path_gambar = "res://arts/chara/vampirPNG-removebg-preview.png"
	
	# EKSEKUSI GANTI GAMBAR
	if status_game and path_gambar != "":
		# Cari node EnemyIcon secara otomatis
		var icon_node = status_game.find_child("EnemyIcon", true, false)
		
		if icon_node:
			icon_node.texture = load(path_gambar)
			print("Berhasil ganti icon: ", path_gambar)
		else:
			print("ERROR: Node 'EnemyIcon' tidak ketemu di StatusGame!")
	elif path_gambar == "":
		print("Warning: Tidak ada gambar yang cocok untuk level ini: ", current_scene_file)
	# ---------------------------------------------------------

	# 3. HITUNG MUSUH
	var enemies = get_tree().get_nodes_in_group("Enemy")
	total_enemies = enemies.size()
	print("Total Musuh: ", total_enemies)
	
	# Update UI
	if status_game:
		status_game.update_enemy_count(enemies_defeated, total_enemies)
	
	if total_enemies == 0: return
		
	# 4. HUBUNGKAN SINYAL
	for enemy in enemies:
		if enemy.has_signal("on_died"):
			enemy.on_died.connect(_on_enemy_died)

func _on_enemy_died():
	enemies_defeated += 1
	if status_game:
		status_game.update_enemy_count(enemies_defeated, total_enemies)
	
	if enemies_defeated >= total_enemies:
		call_deferred("go_to_next_level")

func go_to_next_level():
	print("LEVEL SELESAI!")
	get_tree().paused = true
	var next_level_scene = load("res://scene/next_level.tscn")
	if next_level_scene:
		var instance = next_level_scene.instantiate()
		instance.target_level_path = next_level_path
		get_tree().get_root().add_child(instance)
