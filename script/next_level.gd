extends CanvasLayer

# --- [PENTING] VARIABEL PENERIMA ALAMAT ---
# Variabel ini WAJIB ADA agar script level sebelumnya (lvl_3.gd)
# bisa mengisi tujuan level berikutnya ke sini.
var target_level_path: String = "" 
@onready var sfx_button: AudioStreamPlayer = $SfxButton

func _ready():
	# Pastikan cursor mouse terlihat saat menu muncul
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# --- TOMBOL: LEVEL SELANJUTNYA ---
func _on_lvl_sel_pressed() -> void:
	sfx_button.play()
	await sfx_button.finished
	get_tree().paused = false
	queue_free()
	
	# Cek apakah alamat tujuan valid?
	if target_level_path != "":
		# Pindah ke alamat yang dikirim oleh script level sebelumnya
		get_tree().change_scene_to_file(target_level_path)
	else:
		# Safety Net: Kalau lupa ngisi, balik ke menu biar gak crash
		print("ERROR: Target Path Kosong! Kembali ke Main Menu.")
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")

# --- TOMBOL: ULANGI LEVEL ---
func _on_ulang_pressed() -> void:
	sfx_button.play()
	await sfx_button.finished
	get_tree().paused = false
	# Muat ulang level yang sedang aktif di belakang layar
	get_tree().reload_current_scene()
	queue_free()

# --- TOMBOL: KELUAR KE MENU ---
func _on_kel_pressed() -> void:
	sfx_button.play()
	await sfx_button.finished
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	queue_free()
