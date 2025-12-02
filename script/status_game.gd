extends Control
@onready var pause: Button = $Pause
@onready var counter: Label = $ConCounter/Counter
@onready var dash_icon: TextureProgressBar = $DashIcon
@onready var jumlah_coin: Label = $HBoxContainer/JumlahCoin
@onready var power_up: TextureProgressBar = $PowerUp
@onready var sfx_button: AudioStreamPlayer = $SfxButton



func _ready() -> void:
	call_deferred("connect_to_player")
	update_coin_ui(GameManager.coin)
	
	if not GameManager.coins_changed.is_connected(update_coin_ui):
		GameManager.coins_changed.connect(update_coin_ui)

func connect_to_player():
	# Tunggu 1 frame biar aman
	await get_tree().process_frame
	
	# Cari player di grup "Player"
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# Hubungkan sinyal dash dari player ke fungsi UI
		if not player.dash_cooldown_update.is_connected(_update_dash_ui):
			player.dash_cooldown_update.connect(_update_dash_ui)
		if not player.powerup_updated.is_connected(_update_powerup_ui):
			player.powerup_updated.connect(_update_powerup_ui)
	else:
		print("UI Warning: Player tidak ditemukan untuk Dash Icon")
		


# --- FUNGSI UPDATE VISUAL ---
func _update_dash_ui(time_left, time_max):
	if dash_icon:
		# Set Max Value sesuai cooldown asli (misal 1.5)
		dash_icon.max_value = time_max
		
		# Set Value sesuai sisa waktu (misal 0.5)
		# Kita balik logikanya: Biar kelihatan "Terisi" kalau Ready
		# Kalau cooldown (time_left > 0), bar kosong
		dash_icon.value = time_max - time_left
		
		# EFEK VISUAL WARNA
		if time_left <= 0:
			dash_icon.modulate = Color(1, 1, 1, 1) # Putih Terang (Ready)
		else:
			dash_icon.modulate = Color(0.5, 0.5, 0.5, 1) # Gelap (Cooldown)
func update_enemy_count(defeated,total):
	counter.text = str(defeated)+"/"+str(total)

func _on_pause_pressed() -> void:
	if sfx_button: sfx_button.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = true
	var MenuPause = load("res://scene/pause_menu.tscn")
	var pause_instance = MenuPause.instantiate()
	add_child(pause_instance)
	
func update_coin_ui(amount):
	if jumlah_coin:
		jumlah_coin.text = str(amount)
func _update_powerup_ui(time_left, time_max, is_active):
	if not power_up: return
	
	if is_active:
		power_up.visible = true
		power_up.max_value = time_max
		power_up.value = time_left
	else:
		power_up.visible = false # Sembunyikan kalau durasi habis
