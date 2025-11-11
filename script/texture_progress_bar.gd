# Pastikan skrip ini 'extends TextureProgressBar'
extends TextureProgressBar

# Fungsi ini akan berjalan saat node siap
func _ready():
	# TUNGGU SATU FRAME
	# Ini memberi waktu agar 'Player' bisa siap lebih dulu (FIX Error 'Nil')
	await get_tree().process_frame 
	
	# 1. Cari node 'player'
	var player = get_tree().get_first_node_in_group("Player")
	
	# 2. Cek apakah player-nya ketemu
	if player:
		# 3. Hubungkan sinyal "health_updated" dari player 
		#    ke fungsi "update_health_bar" di skrip INI
		player.healthChange.connect(update_health_bar)
		
		# 4. Atur nilai awal health bar (propertinya sama persis)
		max_value = player.max_health 
		value = player.current_health   
	else:
		# Jika player tidak ketemu, beri tahu di konsol
		print("ERROR: healthBar.gd (Texture) tidak bisa menemukan node di grup 'player'!")

# Fungsi ini akan dipanggil secara otomatis oleh sinyal dari player
func update_health_bar(new_health):
	# Propertinya sama, 'value'
	value = new_health
