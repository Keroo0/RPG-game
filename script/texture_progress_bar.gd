extends TextureProgressBar

func _ready():
	# 1. HAPUS LOGIKA MENUNGGU PLAYER!
	# UI tidak perlu tahu Player ada atau mati. UI hanya perlu tahu DATA.
	
	# 2. Ambil Data Awal dari GameManager (Bank Pusat)
	max_value = GameManager.max_health
	value = GameManager.current_health
	
	# 3. Dengarkan Sinyal dari GameManager
	# "Kalau data di GameManager berubah, UI ikut berubah"
	if not GameManager.health_changed.is_connected(_update_bar):
		GameManager.health_changed.connect(_update_bar)

# Fungsi ini jalan otomatis saat GameManager teriak "Darah Berubah!"
func _update_bar(new_health):
	value = new_health
