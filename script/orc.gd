extends Entity

# --- CONFIG ORC ---
@export_group("Orc Stats")
@export var patrol_speed: int = 15
@export var chase_speed: int = 30
@export var detect_range: int = 250

@export_group("Attack Logic")
@export var stand_attack_range: int = 45 
@export var walk_attack_range: int = 90
@export var run_attack_range: int = 160

@export_group("Cooldowns")
@export var global_attack_cooldown: float = 1.5 
@export var run_attack_cd_max: float = 5.0      
@export var walk_attack_cd_max: float = 3.0     

# --- REFERENSI ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var death_timer: Timer = $death_timer
@onready var patrol_timer: Timer = $PatrolTimer 
@onready var health_bar = $EnemyHealthBar
@onready var weapon_collider: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var sfx_attack: AudioStreamPlayer2D = $SfxAttack
@onready var sfx_run_attack: AudioStreamPlayer2D = $SfxRunAttack

# --- STATE ---
var player = null
var is_attacking: bool = false
var is_hurting: bool = false # State baru biar gak bug saat sakit
var current_attack_speed: int = 0
var facing_dir: String = "side"

# Timer Manual
var current_run_cd: float = 0.0
var current_walk_cd: float = 0.0

# Patroli
var is_patrolling: bool = true
var patrol_direction: Vector2 = Vector2.RIGHT

func _ready():
	if weapon_collider: weapon_collider.disabled = true
	
	if health_bar:
		health_bar.init_health(max_health, current_health)
		on_health_changed.connect(health_bar._on_health_updated)
	
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)
	
	on_hit.connect(_play_hurt_anim)
	on_died.connect(_play_death_anim)
	
	if not death_timer.timeout.is_connected(_on_death_timer_timeout):
		death_timer.timeout.connect(_on_death_timer_timeout)
		
	if not patrol_timer.timeout.is_connected(_pick_new_patrol_dir):
		patrol_timer.timeout.connect(_pick_new_patrol_dir)
	patrol_timer.start(3.0)
	_pick_new_patrol_dir()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Hitung mundur cooldown
	if current_run_cd > 0: current_run_cd -= delta
	if current_walk_cd > 0: current_walk_cd -= delta
	
	if is_dead: return
	
	# PRIORITAS 1: JIKA SAKIT, DIAM (STUN)
	if is_hurting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# PRIORITAS 2: SEDANG MENYERANG
	if is_attacking:
		if player and current_attack_speed > 0:
			var dir = (player.global_position - global_position).normalized()
			update_facing_direction(dir)
			velocity = dir * current_attack_speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
		return

	# PRIORITAS 3: AI MOVEMENT
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# A. DETEKSI PLAYER
		if dist <= detect_range:
			process_combat_state(dist)
		# B. PATROLI
		else:
			process_patrol_state()
	else:
		process_patrol_state()

func process_combat_state(dist: float):
	var dir = (player.global_position - global_position).normalized()
	update_facing_direction(dir)
	
	if attack_cooldown.is_stopped():
		# 1. Normal Attack
		if dist <= stand_attack_range:
			perform_attack("attack", 0, 0.4, 0.4)
			return
		# 2. Walk Attack
		elif dist > stand_attack_range and dist <= walk_attack_range:
			if current_walk_cd <= 0:
				current_walk_cd = walk_attack_cd_max
				perform_attack("walk_attack", 30, 0.3, 0.5)
				return
		# 3. Run Attack
		elif dist > walk_attack_range and dist <= run_attack_range:
			if current_run_cd <= 0:
				current_run_cd = run_attack_cd_max 
				perform_attack("run_attack", 100, 0.2, 0.4)
				return

	# 4. Kejar
	velocity = dir * chase_speed
	anim.play("run_" + facing_dir)
	move_and_slide()

func process_patrol_state():
	velocity = patrol_direction * patrol_speed
	update_facing_direction(patrol_direction)
	anim.play("walk_" + facing_dir)
	move_and_slide()

func _pick_new_patrol_dir():
	if is_dead or is_attacking or is_hurting: return
	var options = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO]
	patrol_direction = options.pick_random()
	patrol_timer.start(randf_range(2.0, 4.0))

# --- LOGIKA SERANGAN ---
func perform_attack(anim_base: String, move_spd: int, windup: float, duration: float):
	is_attacking = true
	current_attack_speed = move_spd
	if anim_base == "run_attack":
		# Suara Spesial Charge
		sfx_run_attack.play()
	else:
		# Suara Biasa (untuk "attack" dan "walk_attack")
		sfx_attack.play()
	anim.play(anim_base + "_" + facing_dir)
	
	# 1. Windup
	await get_tree().create_timer(windup).timeout
	# Cek lagi: apakah mati atau lagi sakit saat nunggu? kalau ya, batal.
	if is_dead or is_hurting: 
		force_stop_attack()
		return
	
	# 2. Hitbox ON
	if weapon_collider: weapon_collider.disabled = false
	
	# 3. Durasi Serangan
	await get_tree().create_timer(duration).timeout
	
	# 4. Selesai
	force_stop_attack()
	attack_cooldown.start(global_attack_cooldown)

# Fungsi Pembatal Serangan (Anti-Macet)
func force_stop_attack():
	if weapon_collider: 
		weapon_collider.set_deferred("disabled", true)
	is_attacking = false
	current_attack_speed = 0

# --- VISUAL & ARAH ---
func update_facing_direction(dir: Vector2):
	if dir == Vector2.ZERO: return
	if abs(dir.x) > abs(dir.y):
		facing_dir = "side"
		anim.flip_h = (dir.x < 0)
	else:
		if dir.y > 0: facing_dir = "front"
		else: facing_dir = "back"
		anim.flip_h = false

# --- UPDATE: ANIMASI HURT (MEMBATALKAN SERANGAN) ---
func _play_hurt_anim(_pos):
	# Jika sedang nyerang, kita paksa berhenti (INTERRUPT)
	if is_attacking:
		force_stop_attack()
	
	# Masuk state hurting
	is_hurting = true
	anim.play("hurt_" + facing_dir)
	
	# Tunggu animasi selesai baru boleh gerak lagi
	# (Atau pakai timer manual kalau animasi hurt tidak loop)
	await get_tree().create_timer(0.4).timeout 
	is_hurting = false

func _play_death_anim():
	# Reset semua status biar gak ada hantu nyerang
	force_stop_attack()
	patrol_timer.stop()
	set_physics_process(false)
	
	if health_bar: health_bar.visible = false
	anim.play("die_" + facing_dir)
	death_timer.start(1.5)
	

func _on_death_timer_timeout():
	queue_free()

func _on_anim_finished():
	pass
