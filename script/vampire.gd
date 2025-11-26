extends Entity # <--- WARISI DARI ENTITY

# --- CONFIG VAMPIRE (BALANCING) ---
@export_group("Vampire AI")
@export var speed: int = 50             # Jalan santai saat patroli
@export var run_speed: int = 100        # Lari saat mengejar
@export var attack_range: int = 50      # Jarak pukul (Pixel)
@export var detect_range: int = 150     # Jarak pandang (Dikecilkan biar fair)
@export var lifesteal_amount: int = 20  # Heal diri sendiri
@export var attack_cooldown_time: float = 2.0 # Jeda antar serangan (Lebih lama)

# --- REFERENSI ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var death_timer: Timer = $death_timer
@onready var patrol_timer: Timer = $PatrolTimer
@onready var health_bar = $EnemyHealthBar
@onready var weapon_collider: CollisionShape2D = $AttackArea/CollisionShape2D

# --- STATE ---
var player = null
var is_attacking: bool = false   # Sedang sibuk nyerang
var is_patrol_walking: bool = false
var facing_dir: String = "front"
var patrol_direction: Vector2 = Vector2.DOWN

func _ready():
	# 1. Matikan pedang saat lahir
	if weapon_collider: weapon_collider.disabled = true
	
	# 2. Setup Health Bar
	if health_bar:
		health_bar.init_health(max_health, current_health)
		on_health_changed.connect(health_bar._on_health_updated)
	
	# 3. Setup Sinyal Visual
	# Hapus koneksi lama via kode biar bersih
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)
		
	on_hit.connect(_play_hurt_anim)
	on_died.connect(_play_death_anim)
	
	if not death_timer.timeout.is_connected(_on_death_timer_timeout):
		death_timer.timeout.connect(_on_death_timer_timeout)
	# 4. Mulai Patroli
	if not patrol_timer.timeout.is_connected(_pick_new_patrol_state):
		patrol_timer.timeout.connect(_pick_new_patrol_state)
	_pick_new_patrol_state()

func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Entity Knockback
	if is_dead: return
	
	# JANGAN BERGERAK KALAU SEDANG MENYERANG (KUNCI ANIMASI)
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return 

	# Cari Player
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	
	var dist = 9999.0
	if player:
		dist = global_position.distance_to(player.global_position)
	
	# --- LOGIKA AI PRIORITY ---
	
	# 1. DEKAT? -> SERANG
	if player and dist <= attack_range and attack_cooldown.is_stopped():
		attack_sequence()
		
	# 2. NAMPAK? -> KEJAR
	elif player and dist <= detect_range:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * run_speed
		update_facing_direction(dir)
		anim.play("run_" + facing_dir)
		move_and_slide()
		
	# 3. AMAN? -> PATROLI
	else:
		process_patrol()

# --- LOGIKA SERANGAN (SINKRONISASI ANIMASI) ---
func attack_sequence():
	is_attacking = true # KUNCI STATUS (Gak bisa gerak)
	velocity = Vector2.ZERO
	
	# Hadap ke player sebelum pukul
	var dir_to_player = (player.global_position - global_position).normalized()
	update_facing_direction(dir_to_player)
	
	# 1. Mainkan Animasi
	anim.play("attack_" + facing_dir)
	
	# 2. Tunggu Windup (Misal frame ke-2 baru pukul)
	# Kita pakai timer manual singkat agar pas dengan gerakan tangan
	await get_tree().create_timer(0.3).timeout
	if is_dead: return
	
	# 3. NYALAKAN HITBOX
	if weapon_collider: weapon_collider.disabled = false
	heal(lifesteal_amount) 
	
	# 4. Tunggu Sebentar (Durasi hitbox aktif)
	await get_tree().create_timer(0.2).timeout
	
	# 5. MATIKAN HITBOX
	if weapon_collider: weapon_collider.disabled = true
	
	# 6. TUNGGU ANIMASI SELESAI (Fairness: Player bisa pukul balik saat ini)
	await anim.animation_finished
	
	# 7. Selesai
	is_attacking = false
	attack_cooldown.start(attack_cooldown_time) # Mulai cooldown panjang

# --- LOGIKA PATROLI (LEBIH RAPI) ---
func process_patrol():
	if is_patrol_walking:
		velocity = patrol_direction * speed
		update_facing_direction(patrol_direction)
		anim.play("walk_" + facing_dir)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		anim.play("idle_" + facing_dir)
		move_and_slide()

func _pick_new_patrol_state():
	if is_dead or is_attacking: return # Jangan ganti state kalau lagi sibuk
	
	is_patrol_walking = not is_patrol_walking
	
	if is_patrol_walking:
		# PILIH 4 ARAH KARDINAL (Atas, Bawah, Kiri, Kanan) - Bukan Diagonal
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		patrol_direction = directions.pick_random()
		patrol_timer.wait_time = randf_range(1.5, 3.0) # Jalan agak lama
	else:
		patrol_timer.wait_time = randf_range(1.0, 2.0) # Istirahat sebentar
		
	patrol_timer.start()

# --- FUNGSI PENDUKUNG ---
func heal(amount):
	current_health += amount
	if current_health > max_health: current_health = max_health
	on_health_changed.emit(current_health)

func update_facing_direction(move_input: Vector2):
	if move_input == Vector2.ZERO: return
	if abs(move_input.x) > abs(move_input.y):
		facing_dir = "side"
		anim.flip_h = (move_input.x < 0)
	else:
		if move_input.y > 0: facing_dir = "front"
		else: facing_dir = "back"
		anim.flip_h = false

# --- VISUAL ---
func _play_hurt_anim(_attacker_pos):
	# Vampir tangguh, kalau lagi nyerang gak bisa distun (Super Armor)
	if is_attacking: return 
	anim.play("hurt_" + facing_dir)

func _play_death_anim():
	anim.play("die_" + facing_dir)
	
	if health_bar: 
		health_bar.visible = false # Sembunyikan bar HP seketika
		
	if weapon_collider: weapon_collider.disabled = true
	patrol_timer.stop()
	set_physics_process(false) # Matikan otak AI
	death_timer.start()

func _on_death_timer_timeout():
	queue_free()

func _on_anim_finished():
	pass
