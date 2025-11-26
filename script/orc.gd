extends Entity

# --- CONFIG ORC ---
@export_group("Orc Stats")
@export var speed: int = 10
@export var run_speed: int = 50
@export var detect_range: int = 150

@export_group("Attack Ranges")
@export var run_attack_range: int = 80
@export var walk_attack_range: int = 45
@export var stand_attack_range: int = 30

@export_group("Cooldowns")
@export var attack_cooldown_time: float = 2.0

# --- REFERENSI ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var death_timer: Timer = $death_timer
@onready var health_bar = $EnemyHealthBar
@onready var weapon_collider: CollisionShape2D = $AttackArea/CollisionShape2D

# --- STATE ---
var player = null
var is_attacking: bool = false
var current_attack_speed: int = 0
var facing_dir: String = "front" # Default arah

func _ready():
	if weapon_collider: weapon_collider.disabled = true
	
	if health_bar:
		health_bar.init_health(max_health, current_health)
		on_health_changed.connect(health_bar._on_health_updated)
	
	# Konek Sinyal
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)
	on_hit.connect(_play_hurt_anim)
	on_died.connect(_play_death_anim)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead: return

	# 1. LOGIKA SAAT MENYERANG (Movement Tech)
	if is_attacking:
		if player:
			# Meluncur ke arah player sambil animasi jalan
			var dir = (player.global_position - global_position).normalized()
			# Kita tidak update arah saat nyerang agar tidak glitch putar-putar
			velocity = dir * current_attack_speed
			move_and_slide()
		return

	# 2. CARI PLAYER
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		var dir = (player.global_position - global_position).normalized()
		
		# --- AI PENGAMBIL KEPUTUSAN ---
		
		if attack_cooldown.is_stopped():
			# A. SANGAT DEKAT -> PUKUL DIAM (Smash)
			if dist <= stand_attack_range:
				# Kirim nama dasar saja ("attack"), script akan nambahin "_front/side" otomatis
				perform_attack("attack", 0, 0.4, 0.4) 
				return
				
			# B. AGAK DEKAT -> PUKUL JALAN (Pressure)
			elif dist <= walk_attack_range:
				perform_attack("walk_attack", 30, 0.3, 0.5) 
				return
				
			# C. JARAK MENENGAH -> PUKUL LARI (Charge)
			elif dist <= run_attack_range:
				perform_attack("run_attack", 150, 0.2, 0.4)
				return

		# D. JAUH? -> KEJAR BIASA
		if dist <= detect_range:
			velocity = dir * run_speed
			update_facing_direction(dir)
			anim.play("run_" + facing_dir)
			move_and_slide()
		else:
			# E. SANGAT JAUH -> DIAM
			velocity = Vector2.ZERO
			anim.play("idle_" + facing_dir)
			move_and_slide()

# --- FUNGSI SERANGAN DINAMIS ---
func perform_attack(anim_base_name: String, move_speed: int, windup: float, duration: float):
	is_attacking = true
	current_attack_speed = move_speed
	
	# Update arah TERAKHIR sebelum mulai nyerang
	if player:
		var dir = (player.global_position - global_position).normalized()
		update_facing_direction(dir)
	
	# RAKIT NAMA ANIMASI: "run_attack" + "_" + "front" = "run_attack_front"
	var final_anim_name = anim_base_name + "_" + facing_dir
	anim.play(final_anim_name)
	
	# Super Armor saat Run Attack
	var old_resist = knockback_resistance
	if move_speed > 100: knockback_resistance = 1.0 
	
	# 1. Windup
	await get_tree().create_timer(windup).timeout
	if is_dead: return
	
	# 2. Hitbox ON
	if weapon_collider: weapon_collider.disabled = false
	
	# 3. Durasi Aktif
	await get_tree().create_timer(duration).timeout
	
	# 4. Hitbox OFF
	if weapon_collider: weapon_collider.disabled = true
	
	# 5. Tunggu Animasi Selesai
	await anim.animation_finished
	
	# Reset
	is_attacking = false
	current_attack_speed = 0
	knockback_resistance = old_resist
	attack_cooldown.start(attack_cooldown_time)

# --- UPDATE ARAH (LOGIKA 4 ARAH) ---
func update_facing_direction(move_input: Vector2):
	if move_input == Vector2.ZERO: return
	
	# Tentukan Dominasi Sumbu
	if abs(move_input.x) > abs(move_input.y):
		facing_dir = "side"
		anim.flip_h = (move_input.x < 0) # Kiri = Flip
	else:
		if move_input.y > 0: facing_dir = "front"
		else: facing_dir = "back"
		anim.flip_h = false

# --- VISUAL ---
func _play_hurt_anim(_pos):
	if is_attacking: return 
	anim.play("hurt_" + facing_dir)

func _play_death_anim():
	anim.play("die_" + facing_dir)
	if weapon_collider: weapon_collider.disabled = true
	set_physics_process(false)
	if health_bar: health_bar.visible = false
	death_timer.start(1.5)

func _on_death_timer_timeout():
	queue_free()

func _on_anim_finished():
	pass
