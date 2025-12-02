extends Node

# --- DATA YANG DISIMPAN (PERSISTEN) ---
# Nilai ini tidak akan hilang saat pindah scene/level
var max_health: int = 500
var current_health: int = 500
var coin : int = 0

# --- SINYAL KOMUNIKASI ---
# UI (HealthBar) akan mendengarkan sinyal ini agar update otomatis
signal health_changed(new_value)
signal player_died
signal coins_changed(new_amount)

func _ready():
	# Inisialisasi awal saat game dibuka
	reset_data()

# --- FUNGSI RESET (Start Game Baru) ---
func reset_data():
	coin = 0
	current_health = max_health
	health_changed.emit(current_health)
	coins_changed.emit(coin)
	print("[GameManager] Data Reset: HP Full ", current_health)

# --- FUNGSI REFILL (Sesuai permintaanmu: Darah penuh tiap level) ---
# Panggil fungsi ini di script Level (_ready) jika mau darah penuh lagi
func refill_health():
	current_health = max_health
	health_changed.emit(current_health)
	print("[GameManager] Health Refilled for New Level")

# --- FUNGSI UPDATE ---
# Dipanggil oleh Player.gd saat dia kena pukul
func update_health(new_val):
	current_health = new_val
	health_changed.emit(current_health)
	
	if current_health <= 0:
		player_died.emit()

# --- FUNGSI UPGRADE (Opsional Masa Depan) ---
# Panggil ini kalau Player ambil item "Jantung Naga"
func increase_max_health(amount):
	max_health += amount
	current_health += amount # Tambah darahnya juga
	health_changed.emit(current_health)
	print("[GameManager] Max Health Upgraded to: ", max_health)
	
func add_coin(amount):
	coin += amount
	coins_changed.emit(coin)
	print("total coin =", coin)
