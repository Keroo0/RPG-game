extends Node2D

# 1. Variabel untuk melacak musuh
var total_enemies: int = 0
var enemies_defeated: int = 0

# 2. Path untuk level berikutnya (bisa diisi di Inspector)
@export var next_level_path: String = "res://scene/lvl2.tscn"
@onready var status_game: Control = $CanvasLayer/StatusGame


func _ready():
	# 3. Dapatkan semua node yang ada di grup "enemy"
	var enemies = get_tree().get_nodes_in_group("Enemy")
	total_enemies = enemies.size()
	
	print("Level ini memiliki total musuh: ", total_enemies)
	
	# Jika tidak ada musuh di level ini, jangan lakukan apa-apa
	if total_enemies == 0:
		return
		
	# 4. Hubungkan sinyal "died" dari SETIAP musuh ke fungsi di skrip ini
	for enemy in enemies:
		enemy.died.connect(_on_enemy_died)
		
	status_game.update_enemy_count(enemies_defeated, total_enemies)
# 5. Fungsi ini dipanggil setiap kali ada musuh yang 'died.emit()'
func _on_enemy_died():
	enemies_defeated += 1
	print("Musuh dikalahkan: ", enemies_defeated, " / ", total_enemies)
	status_game.update_enemy_count(enemies_defeated, total_enemies)
	# 6. Cek apakah semua musuh sudah mati
	if enemies_defeated == total_enemies:
		go_to_next_level()

func go_to_next_level():
	print("LEVEL SELESAI!")
	
	# 7. Jeda game dan tampilkan layar "Level Selesai"
	get_tree().paused = true
	
	var next_level_scene = load("res://scene/next_level.tscn") # Pastikan path ini benar
	var instance = next_level_scene.instantiate()
	
	# 8. Beri tahu 'next_level.tscn' apa level berikutnya
	instance.target_level_path = next_level_path 
	
	get_tree().get_root().add_child(instance)
