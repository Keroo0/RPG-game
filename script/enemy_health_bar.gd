extends TextureProgressBar

func _ready():
	# Sembunyi dulu kalau belum dipukul (Opsional)
	# visible = false 
	pass

# Fungsi ini dipanggil oleh Slime saat spawn
func init_health(max_hp, current_hp):
	max_value = max_hp
	value = current_hp

# Fungsi ini dipanggil saat sinyal 'on_health_changed' bunyi
func _on_health_updated(new_health):
	value = new_health
	visible = true
