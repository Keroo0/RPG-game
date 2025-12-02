extends Area2D

func _ready():
	# 1. Sambungkan sinyal tabrakan secara otomatis
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 2. Animasi Floating (Naik Turun Cantik)
	# Pastikan node gambarnya bernama "Sprite2D"
	if has_node("Sprite2D"):
		var tween = create_tween().set_loops()
		# Naik 5 pixel selama 1 detik
		tween.tween_property($Sprite2D, "position:y", -5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
		# Turun 5 pixel selama 1 detik
		tween.tween_property($Sprite2D, "position:y", 5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)

func _on_body_entered(body):
	# Cek apakah body yang nabrak punya fungsi aktivasi (yaitu Player)
	if body.has_method("activate_power_up"):
		print("[ITEM] Kunci diambil!")
		
		# PANGGIL FUNGSI DI PLAYER
		body.activate_power_up()
		
		# (Opsional) Tambahkan suara 'cling' disini nanti
		
		# Hapus diri sendiri dari dunia
		queue_free()
