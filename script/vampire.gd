extends CharacterBody2D

signal died

# --- ATRIBUT ---
@export var speed: int = 70
@export var health: int = 400
@export var max_health: int = 400
@export var attack_damage: int = 60
@export var knockback_power: int = 200
@export var lunge_speed: int = 350
@export var windup_time: float = 0.3

# --- NODE ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var death_timer: Timer = $death_timer
@onready var patrol_timer: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar = $EnemyHealthBar

# --- STATUS ---
var player = null
var player_chase: bool = false
var player_in_attack_range: bool = false

var is_dead: bool = false
var is_hurting: bool = false
var is_attacking: bool = false
var is_in_knockback: bool = false

# --- PATROLI ---
var facing_dir: String = "front"
var patrol_direction: Vector2 = Vector2.ZERO
var is_patrol_walking: bool = false

func _ready():
	if health_bar: health_bar.init_health(max_health)
	$AttackArea/CollisionShape2D.disabled = false
	
	if not anim.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	
	if not $HurtBox.area_entered.is_connected(_on_hurt_box_area_entered):
		$HurtBox.area_entered.connect(_on_hurt_box_area_entered)
		
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	_pick_new_patrol_state()

func _physics_process(_delta: float) -> void:
	if is_dead: return
	# PRIORITAS 1: KNOCKBACK (Paling Kuat)
	# Jika kena pukul keras, harus terpental dulu, batalkan yang lain
	if is_in_knockback: 
		move_and_slide()
		return

	# PRIORITAS 2: MENYERANG (Super Armor dari Stun biasa, tapi kalah sama Knockback)
	if is_attacking:
		move_and_slide()
		return

	# PRIORITAS 3: TERLUKA BIASA (Stun)
	if is_hurting: 
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# --- AI LOGIC ---
	
	# 1. SERANG (Prioritas Tinggi)
	if player_in_attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		
		# Selalu update arah hadap ke player saat diam
		if player: update_animation_parameters(player.global_position - global_position)
			
		if attack_cooldown.is_stopped():
			attack()
		else:
			anim.play("idle_" + facing_dir)
			
	# 2. KEJAR (Prioritas Menengah)
	elif player_chase and player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		update_animation_parameters(direction)
		anim.play("run_" + facing_dir)
		
	# 3. PATROLI
	else:
		if is_patrol_walking:
			velocity = patrol_direction * speed
			move_and_slide()
			update_animation_parameters(patrol_direction)
			anim.play("walk_" + facing_dir)
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			anim.play("idle_" + facing_dir)

# --- FUNGSI PENTING: UPDATE ARAH ---
func update_animation_parameters(move_input: Vector2):
	if move_input != Vector2.ZERO:
		# Logika prioritas sumbu (Lebih condong horizontal atau vertikal?)
		if abs(move_input.x) > abs(move_input.y):
			facing_dir = "side"
			anim.flip_h = (move_input.x < 0)
		else:
			if move_input.y > 0: facing_dir = "front" # Bawah
			else: facing_dir = "back" # Atas
			anim.flip_h = false

# --- SERANGAN ---
func attack():
	if player == null: return
	
	is_attacking = true
	velocity = Vector2.ZERO
	
	# Debug Arah
	update_animation_parameters(player.global_position - global_position)
	print("[DEBUG] Vampir Serang! Arah: ", facing_dir, " | Posisi Player: ", player.global_position)
	
	anim.play("attack_" + facing_dir)
	
	await get_tree().create_timer(windup_time).timeout
	if is_dead: return
	
	# Lunge
	if player != null:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * lunge_speed
	
	await get_tree().create_timer(0.3).timeout
	velocity = Vector2.ZERO
	
	if player_in_attack_range and not is_dead:
		if player.has_method("receive_damage"):
			player.receive_damage(attack_damage, global_position)
			heal_self(10)
	
	attack_cooldown.start()

func heal_self(amount):
	health += amount
	if health > max_health: health = max_health
	if health_bar: health_bar._on_health_updated(health)

# --- SINYAL PENDUKUNG ---
func _on_animated_sprite_2d_animation_finished():
	# Debugging Nama Animasi
	# print("[DEBUG] Animasi Selesai: ", anim.animation)
	
	if anim.animation.begins_with("attack"): 
		is_attacking = false
	elif anim.animation.begins_with("hurt"): 
		is_hurting = false

func _on_detect_area_body_entered(body):
	if body.is_in_group("Player"):
		print("[DEBUG] Mata: Player Masuk Radius Kejar")
		player = body
		player_chase = true

func _on_detect_area_body_exited(body):
	if body.is_in_group("Player"):
		
		# PENGAMAN LOGIKA:
		# Jika sinyal Exit bunyi TAPI Vampir sedang melompat (Lunge), 
		# itu biasanya kesalahan fisika/glitch. ABAIKAN sinyalnya.
		if is_attacking:
			print("[DEBUG] Sinyal Exit muncul saat Serang. Abaikan.")
			return
		# Jika sedang jalan biasa, baru kita anggap Player benar-benar hilang
		print("[DEBUG] Mata: Player Benar-benar Hilang.")
		player = null
		player_chase = false

# --- SINYAL JARAK SERANG ---

func _on_attack_area_body_entered(body):
	if body.is_in_group("Player"):
		print("[DEBUG] Range: Masuk Jarak Pukul -> Stop Kejar, Siap Serang")
		player_in_attack_range = true

func _on_attack_area_body_exited(body):
	if body.is_in_group("Player"):
		print("[DEBUG] Range: Keluar Jarak Pukul -> Kejar Lagi")
		player_in_attack_range = false
	
# --- TERIMA DAMAGE (Copy paste fungsi lama Anda yang sudah benar di sini) ---
func _on_hurt_box_area_entered(area):
	if area.is_in_group("attack_hitbox"):
		var attacker = area.get_parent()
		take_damage(attacker.global_position, attacker.attack_damage)

func take_damage(attacker_pos, amount):
	if is_dead: return
	print("[DEBUG] Vampir Kena Pukul! Sisa HP: ", health)
	health -= amount
	if health_bar: health_bar._on_health_updated(health)
	
	if is_attacking:
		# Opsi A: Super Armor TOTAL (Tidak kena stun/animasi hurt, TAPI kena knockback dikit)
		is_in_knockback = true
		var dir = (global_position - attacker_pos).normalized()
		velocity = dir * (knockback_power * 0.5) # Knockback separuh jika sedang menyerang
		
		get_tree().create_timer(0.1).timeout.connect(func(): is_in_knockback = false; velocity = Vector2.ZERO)
		
		# Cek mati di sini juga
		if health <= 0: die()
		return 
	

func die():
	if is_dead: return
	# Set status
	is_dead = true
	is_hurting = false
	is_attacking = false
	is_in_knockback = false
	velocity = Vector2.ZERO
	anim.play("die_" + facing_dir)
	died.emit()
	death_timer.start()

func _on_death_timer_timeout(): queue_free()
func _on_patrol_timer_timeout(): _pick_new_patrol_state()
func _pick_new_patrol_state():
	is_patrol_walking = not is_patrol_walking
	if is_patrol_walking:
		patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		patrol_timer.wait_time = randf_range(2.0, 4.0)
	else:
		patrol_timer.wait_time = randf_range(1.0, 3.0)
	patrol_timer.start()
