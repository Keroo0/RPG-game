extends Entity # <--- WARISI DARI ENTITY

# --- KONFIGURASI (Atur di Inspector) ---
@export_group("Slime Settings")
@export var speed: int = 40
@export var lunge_speed: int = 200
@export var windup_time: float = 0.5
@export var attack_range: int = 50   # Jarak mulai memukul (JANGAN KEKECILAN!)
@export var detect_range: int = 100 # Jarak mulai mengejar

# --- REFERENSI NODE ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var death_timer: Timer = $death_timer
@onready var health_bar = $EnemyHealthBar 
@onready var sfx_attack: AudioStreamPlayer2D = $SfxAttack

# Referensi ke CollisionShape Pedang (PENTING untuk sakelar on/off)
@onready var weapon_collider: CollisionShape2D = $AttackArea/CollisionShape2D

# --- STATE ---
var player = null
var is_attacking: bool = false
# is_dead dan knockback_vector SUDAH ADA DI ENTITY (Bapak)

func _ready():
	# 1. Pastikan Hitbox mati saat lahir (Biar gak curang)
	if weapon_collider:
		weapon_collider.disabled = true
	
	# 2. Setup Health Bar (Baca data dari Entity)
	if health_bar:
		health_bar.init_health(max_health, current_health)
		on_health_changed.connect(health_bar._on_health_updated)
	
	# 3. Setup Sinyal Visual
	anim.animation_finished.connect(_on_anim_finished)
	on_hit.connect(_play_hurt_anim)   # Kalau dipukul, nangis
	on_died.connect(_play_death_anim) # Kalau mati, main animasi

func _physics_process(delta: float) -> void:
	# 1. WAJIB: Panggil physics bapak buat urus Knockback otomatis
	super._physics_process(delta)
	
	if is_dead: return
	
	# 2. Cari Player Otomatis (Safety Net)
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	
	# 3. Logika AI Berbasis Jarak
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# A. Sedang Serang? Biarkan meluncur (Lunge)
		if is_attacking:
			move_and_slide()
			
		# B. Dekat & Siap Serang? -> HAJAR
		elif dist <= attack_range and attack_cooldown.is_stopped():
			attack_sequence()
			
		# C. Jarak Nanggung? -> KEJAR
		elif dist <= detect_range:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * speed
			update_facing_direction(player.global_position)
			anim.play("walk_side")
			move_and_slide()
			
		# D. Jauh? -> DIAM
		else:
			velocity = Vector2.ZERO
			anim.play("idle_front")
			move_and_slide()

# --- LOGIKA SERANGAN (URUTAN WAKTU) ---
func attack_sequence():
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("hit_side") # 1. Animasi Ancang-ancang
	
	# 2. Tunggu Windup (Persiapan)
	await get_tree().create_timer(windup_time).timeout
	if is_dead: return
	
	# 3. NYALAKAN PEDANG (Hitbox ON)
	if sfx_attack: sfx_attack.play()
	if weapon_collider: weapon_collider.disabled = false
	
	# 4. LUNGE! (Lompat ke arah player)
	if player:
		var lunge_dir = (player.global_position - global_position).normalized()
		velocity = lunge_dir * lunge_speed
	
	# 5. Durasi serangan aktif (misal 0.5 detik)
	await get_tree().create_timer(0.5).timeout
	
	# 6. MATIKAN PEDANG (Hitbox OFF)
	if weapon_collider: weapon_collider.disabled = true
	
	# 7. Selesai
	is_attacking = false
	velocity = Vector2.ZERO
	attack_cooldown.start()

# --- VISUAL EFEK (Override dari Entity) ---
func _play_hurt_anim(_attacker_pos):
	anim.play("cry_side") # Slime nangis visual doang
	velocity = Vector2.ZERO # Stop gerak pas sakit

func _play_death_anim():
	anim.play("die")
	# Pastikan hitbox mati pas mati
	if weapon_collider:
		weapon_collider.set_deferred("disabled", true)
	
	# Matikan hurtbox juga biar gak bisa dipukul lagi
	$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	death_timer.start()

func _on_death_timer_timeout():
	queue_free()

# --- PENDUKUNG ---
func _on_anim_finished():
	if anim.animation.begins_with("cry"):
		# Kembali ke state normal setelah nangis (opsional)
		pass

func update_facing_direction(target_pos):
	if target_pos.x < global_position.x: anim.flip_h = true
	else: anim.flip_h = false
