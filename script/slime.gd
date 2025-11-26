extends CharacterBody2D

signal died

# --- ATRIBUT ---
@export var speed: int = 20
@export var health: int = 100
@export var attack_damage: int = 40
@export var knockback_power: int = 100
@export var windup_time: float = 0.15 
@export var lunge_speed: int = 200   

# --- REFERENSI NODE ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown 
@onready var death_timer: Timer = $death_timer
@onready var attack_area: Area2D = $AttackArea 
# (HurtBox tidak wajib di-var kalau sudah dikoneksikan sinyalnya, tapi oke disimpan)
@onready var hurt_box: Area2D = $HurtBox 

# --- TAMBAHAN: HEALTH BAR ---
# Pastikan Anda sudah menaruh scene EnemyHealthBar di dalam node Slime
@onready var health_bar = $EnemyHealthBar 
# ----------------------------

# --- STATUS ---
var player = null
var player_chase: bool = false
var player_in_attack_range: bool = false

var is_dead: bool = false
var is_hurting: bool = false
var is_attacking: bool = false
var is_in_knockback: bool = false

func _ready():
	# Inisialisasi Health Bar Penuh
	if health_bar:
		health_bar.init_health(health)
		
	$AttackArea/CollisionShape2D.disabled = false 
	print("[DEBUG] Slime Siap. HP: ", health)
	
	# Pastikan sinyal animasi terhubung
	if not anim.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(_delta: float) -> void:
	if is_dead: return 
	if is_in_knockback: move_and_slide(); return
	if is_hurting: velocity = Vector2.ZERO; move_and_slide(); return
		
	# Biarkan Slime meluncur saat menyerang
	if is_attacking:
		move_and_slide() 
		return

	# 1. LOGIKA SERANG
	if player_in_attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		
		if attack_cooldown.is_stopped():
			print("[DEBUG] Musuh dalam jangkauan Area2D -> SERANG")
			attack()
			
	# 2. LOGIKA KEJAR
	elif player_chase and player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		update_facing_direction(player.global_position)
		anim.play("walk_side")
		
	# 3. DIAM
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		anim.play("idle_front")

# --- FUNGSI SERANGAN (LUNGE) ---
func attack():
	if player == null: return
	
	is_attacking = true
	velocity = Vector2.ZERO # 1. Rem Mendadak (Ancang-ancang)
	
	update_facing_direction(player.global_position)
	anim.play("hit_side") 
	
	# 2. Tunggu (Wind-up)
	await get_tree().create_timer(windup_time).timeout
	
	# Cek jika mati saat nunggu
	if is_dead: return
	
	# 3. LUNGE! (Lompat ke arah player saat ini)
	if player != null:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * lunge_speed 
	
	# 4. Durasi Melayang 
	await get_tree().create_timer(0.3).timeout
	
	# 5. Impact
	velocity = Vector2.ZERO 
	
	if player_in_attack_range and not is_dead:
		print("[DEBUG] HIT SUKSES!")
		if player.has_method("receive_damage"):
			player.receive_damage(attack_damage, global_position)
	else:
		print("[DEBUG] MISS! Player menghindar.")
	
	attack_cooldown.start()

# --- TERIMA DAMAGE ---
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack_hitbox"):
		print("[DEBUG] DAMAGE: Slime Kena Pedang!")
		var attacker = area.get_parent()
		take_damage(attacker.global_position, attacker.attack_damage)

func take_damage(attacker_pos, amount):
	if is_dead: return
	
	health -= amount
	print("[DEBUG] Slime HP Sisa: ", health)
	
	# --- UPDATE HEALTH BAR ---
	if health_bar:
		health_bar._on_health_updated(health)
	# -------------------------
	
	is_hurting = true
	anim.play("cry_side")
	
	is_in_knockback = true
	var dir = (global_position - attacker_pos).normalized()
	velocity = dir * knockback_power
	
	get_tree().create_timer(0.2).timeout.connect(func(): is_in_knockback = false; velocity = Vector2.ZERO)
	get_tree().create_timer(0.4).timeout.connect(func(): is_hurting = false) 

	if health <= 0:
		die()

func die():
	if is_dead: return
	print("[DEBUG] Slime Mati.")
	is_dead = true
	is_hurting = false
	is_attacking = false
	is_in_knockback = false
	velocity = Vector2.ZERO
	
	anim.play("die")
	died.emit()
	death_timer.start()

func _on_death_timer_timeout():
	print("[DEBUG] Slime Dihapus.")
	queue_free()

# --- PENDUKUNG ---
func _on_animated_sprite_2d_animation_finished():
	# print("[DEBUG] Animasi selesai: ", anim.animation)
	if anim.animation.begins_with("hit"):
		is_attacking = false
	elif anim.animation.begins_with("cry"):
		is_hurting = false

func update_facing_direction(target_pos):
	if target_pos.x < global_position.x: anim.flip_h = true
	else: anim.flip_h = false

# --- SINYAL AREA ---
func _on_detect_area_body_entered(body):
	if body.is_in_group("Player"): player = body; player_chase = true
func _on_detect_area_body_exited(body):
	if body.is_in_group("Player"): player = null; player_chase = false
func _on_attack_area_body_entered(body):
	if body.is_in_group("Player"): player_in_attack_range = true
func _on_attack_area_body_exited(body):
	if body.is_in_group("Player"): player_in_attack_range = false
