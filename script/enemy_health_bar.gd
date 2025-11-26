# GANTI 'extends ProgressBar' MENJADI:
extends TextureProgressBar

func _ready():
	# Sembunyikan bar saat awal (opsional)
	# visible = false 
	pass

func init_health(_health):
	max_value = _health
	value = _health

func _on_health_updated(_health):
	value = _health
	visible = true
