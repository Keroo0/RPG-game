extends CharacterBody2D

signal died

@export var speed: int = 10
@export var health: int = 40
@export var attack_damage: int = 10
@export var knockback_power: int = 300
@export var lunge_speed: int = 150 # Kecepatan lompatan

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var death: Timer = $death
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var hitbox_shape: CollisionShape2D = $hit_box/CollisionShape2D

var player = null
var player_chase: bool = false
var player_in_attack_range: bool = false # <-- State baru

var is_in_knockback: bool = false
var is_hurting: bool = false
var is_attacking: bool = false

var arah_terakhir = "front"

func _ready():
	# Hubungkan sinyal dari area deteksi (ganti nama di editor jika perlu)
	$detect_area.body_entered.connect(_on_detect_area_body_entered)
	$detect_area.body_exited.connect(_on_detect_area_body_exited)
	
	# Hubungkan sinyal dari area serangan (ganti nama di editor jika perlu)
 	$hit_box.body_entered.connect(_on_hit_box_body_entered)
	$hit_box.body_exited.connect(_on_hit_box_body_exited)
	
	# Hubungkan sinyal dari animasi (WAJIB agar tidak macet)
	anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(delta: float) -> void:
	# STATE 1: Jika sedang beraksi (terpental, terluka, menyerang), jangan lakukan AI
	if is_in_knockback:
		move_and_slide()
		return
	if is_hurting:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_attacking:
		move_and_slide() # Biarkan lompatan (lunge) berlanjut
		return

	# STATE 2: Jika Player ada di jangkauan serangan dan cooldown selesai -> SERANG
	if player_in_attack_range and attack_cooldown.is_stopped():
		attack()
	# STATE 3: Jika Player terdeteksi (tapi di luar jangkauan) -> KEJAR
	elif player_chase and player:
		chase_player()
	# STATE 4: Jika tidak ada siapa-siapa -> DIAM
	else:
		idle()

# --- FUNGSI-FUNGSI STATE ---

func idle():
	velocity = Vector2.ZERO
	move_and_slide()
	anim.play("idle_" + arah_terakhir)

func chase_player():
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)

func attack():
	is_attacking = true
	attack_cooldown.start() # Mulai cooldown 1 detik
	
	# Tentukan arah lompatan (lunge)
	if player != null:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * lunge_speed
	
	# Mainkan animasi 'hit' berdasarkan arah
	_update_animation(velocity.normalized()) # Update arah hadap
	if arah_terakhir == "front": anim.play("hit_front")
	elif arah_terakhir == "back": anim.play("hit_back")
	else: anim.play("hit_side")
	
	# NYALAKAN "Pedang" (Hitbox) Slime
	hitbox_shape.disabled = false

# --- FUNGSI DETEKSI AREA ---

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		player_chase = true

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_chase = false

# Ini dari 'hit_box' (Area Serangan)
func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_attack_range = true

func _on_hit_box_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_range = false

# --- FUNGSI DAMAGE & STATUS ---

# Ini dari 'Hurtbox' (Badan Slime)
func _on_Hurtbox_area_entered(area):
	if area.is_in_group("attack_hitbox"): # Jika diserang oleh "Pedang" Player
		var attacker = area.get_parent()
		take_damage(attacker.global_position, attacker.attack_damage)

func take_damage(attacker_position: Vector2, damage_amount: int):
	if is_in_knockback or is_hurting or health <= 0:
		return
		
	health -= damage_amount
	print("darah slime sisa = ", health)
	
	is_hurting = true
	if arah_terakhir == "front": anim.play("cry_front")
	elif arah_terakhir == "back": anim.play("cry_back")
	else: anim.play("cry_side")
	get_tree().create_timer(0.3).timeout.connect(_on_hurt_finished)
	
	is_in_knockback = true
	var knockback_direction = (global_position - attacker_position).normalized()
	velocity = knockback_direction * knockback_power
	get_tree().create_timer(0.2).timeout.connect(_on_knockback_finished)
	
	if health <= 0:
		is_hurting = false; is_in_knockback = false
		anim.play("die"); speed = 0; died.emit(); death.start()

# --- FUNGSI CALLBACK (PENTING AGAR TIDAK MACET) ---

func _on_animated_sprite_2d_animation_finished():
	# Jika animasi 'hit' (menyerang) selesai
	if anim.animation.begins_with("hit_"):
		is_attacking = false
		velocity = Vector2.ZERO # Berhenti setelah melompat
		hitbox_shape.disabled = true # MATIKAN "Pedang"
		
func _on_knockback_finished():
	is_in_knockback = false
	velocity = Vector2.ZERO

func _on_hurt_finished():
	is_hurting = false

func _on_death_timeout() -> void:
	queue_free()

func _update_animation(direction: Vector2) -> void:
	# (Fungsi ini tidak berubah)
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			anim.play("walk_side"); anim.flip_h = false; arah_terakhir = "side"
		else:
			anim.play("walk_side"); anim.flip_h = true; arah_terakhir = "side"
	else:
		if direction.y < 0:
			anim.play("walk_back"); arah_terakhir = "back"
		else:
			anim.play("walk_front"); arah_terakhir = "front"
func enemy():
	pass
