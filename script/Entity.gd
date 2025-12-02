class_name Entity extends CharacterBody2D

@export var coin_drop_scene: PackedScene # Drag scene Coin.tscn ke sini di Inspector Entity
@export var coin_value: int = 10 # Slime=10, Vampir=30, Orc=50 (Atur di Inspector)
# --- STATS UNIVERSAL ---
# Semua makhluk punya HP. Tidak perlu nulis ini lagi di Player/Musuh.
@export var max_health: int = 100
@onready var current_health: int = max_health

# --- AUDIO SETTINGS [BARU] ---
# Drag file suara .wav ke sini di Inspector
@export_group("Audio Settings")
@export var audio_hurt: AudioStream 
@export var audio_die: AudioStream
# --- STATE ---
var is_dead: bool = false
var knockback_vector: Vector2 = Vector2.ZERO
@export var knockback_resistance: float = 0.0 # 0.0 = Terbang, 1.0 = Batu

# Node Audio Internal (Dibuat otomatis oleh kode)
var audio_player: AudioStreamPlayer2D
# --- SIGNALS ---
# Anak-anaknya (Player/Vampir) akan mendengarkan sinyal ini untuk mainkan animasi
signal on_hit(attacker_pos)
signal on_health_changed(new_hp)
signal on_died


func _ready():
	# [BARU] Pasang Speaker Otomatis
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
func _physics_process(delta):
	# Logika Knockback Universal
	# Jika ada gaya dorong, Entity akan meluncur mundur
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector
		# Gaya gesek: Knockback berkurang perlahan
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
		move_and_slide()

# --- FUNGSI UTAMA PENERIMA DAMAGE ---
func receive_damage(amount: int, knockback_force: float, attacker_pos: Vector2):
	if is_dead: return
	
	# 1. Kurangi Darah
	current_health -= amount
	# Batasi agar tidak minus
	if current_health < 0: current_health = 0
	
	print(name, " took ", amount, " damage. HP Left: ", current_health)
	
	# 2. Kabari UI dan Animasi
	on_health_changed.emit(current_health)
	on_hit.emit(attacker_pos)
	
	# [BARU] MAINKAN SUARA SAKIT
	if audio_hurt and audio_player:
		audio_player.stream = audio_hurt
		# Acak pitch sedikit biar natural (suara gak robot)
		audio_player.pitch_scale = randf_range(0.9, 1.1)
		audio_player.play()
		
	# 3. Hitung Knockback
	if knockback_force > 0:
		var direction = (global_position - attacker_pos).normalized()
		# Resistance mengurangi efek pentalan
		knockback_vector = direction * (knockback_force * (1.0 - knockback_resistance))
	
	# 4. Cek Kematian
	if current_health <= 0:
		die()

# Fungsi virtual (Bisa ditimpa/override oleh anak)
func die():
	is_dead = true
	on_died.emit()
	if audio_die:
		var temp_audio = AudioStreamPlayer2D.new()
		temp_audio.stream = audio_die
		temp_audio.global_position = global_position
		get_tree().current_scene.add_child(temp_audio)
		temp_audio.play()
		temp_audio.finished.connect(temp_audio.queue_free)
	call_deferred("drop_loot") 

func drop_loot():
	if coin_drop_scene:
		var coin = coin_drop_scene.instantiate()
		coin.global_position = global_position # Muncul di mayat
		coin.value = coin_value # Set nilainya sesuai jenis musuh
		get_tree().current_scene.add_child(coin)
