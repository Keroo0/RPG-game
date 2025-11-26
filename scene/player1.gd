extends CharacterBody2D

# --- ATRIBUT PLAYER ---
@export var speed: int = 100
@export var max_health: int = 500
@export var attack_damage: int = 50 # <-- Ini yang dibaca Slime saat kena pukul
@export var knockbackPower = 50

# --- STATE VARIABLES ---
@onready var current_health: int = max_health
var current_dir = "down"
var life: bool = true
var attacking: bool = false
var can_take_damage: bool = true 
var is_knocked_back: bool = false # Status baru

# --- REFERENSI NODE ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var deal_attack_timer: Timer = $deal_attack
@onready var death_timer: Timer = $death

# Node Serangan (Pedang)
# Perhatikan 'Box' dengan B besar, dan 'areaAttack'
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitBox/areaAttack

# Node Pertahanan (Cooldown Jeda Kebal)
@onready var hurtbox_cooldown: Timer = $hurt_box/cooldown 

# --- SINYAL ---
signal healthChange(current_health)

func _ready():
	# 1. Matikan pedang saat mulai
	attack_hitbox_shape.disabled = true
	
	# 2. Pastikan timer cooldown terhubung
	if not hurtbox_cooldown.timeout.is_connected(_on_hurtbox_cooldown_timeout):
		hurtbox_cooldown.timeout.connect(_on_hurtbox_cooldown_timeout)

func _physics_process(delta: float) -> void:
	if is_knocked_back:
		move_and_slide()
		return
	if not life: return
	
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		playerMovement(delta)
		
	attack_input()

# --- GERAKAN ---
func playerMovement(_delta):
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * speed
		
		if input_vector.x > 0: current_dir = "right"
		elif input_vector.x < 0: current_dir = "left"
		elif input_vector.y > 0: current_dir = "down"
		elif input_vector.y < 0: current_dir = "up"
		
		play_anim(1)
	else:
		velocity = Vector2.ZERO
		play_anim(0)
	
	move_and_slide()

func play_anim(movement):
	if attacking: return 
	
	if current_dir == "right":
		anim.flip_h = false
		if movement == 1: anim.play("walk_side")
		else: anim.play("idle_side")
	elif current_dir == "left":
		anim.flip_h = true
		if movement == 1: anim.play("walk_side")
		else: anim.play("idle_side")
	elif current_dir == "up":
		anim.flip_h = false
		if movement == 1: anim.play("walk_back")
		else: anim.play("idle_back")
	elif current_dir == "down":
		anim.flip_h = false
		if movement == 1: anim.play("walk_front")
		else: anim.play("idle_front")

# --- LOGIKA SERANGAN (PLAYER -> MUSUH) ---
func attack_input():
	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true
		
		# >>> KUNCI PENYERANGAN <<<
		# Nyalakan Area2D ini agar bisa dideteksi oleh Hurtbox Slime
		attack_hitbox_shape.disabled = false 
		
		if current_dir == "right":
			anim.flip_h = false; anim.play("hit_side")
		elif current_dir == "left":
			anim.flip_h = true; anim.play("hit_side")
		elif current_dir == "up":
			anim.flip_h = false; anim.play("hit_back")
		elif current_dir == "down":
			anim.flip_h = false; anim.play("hit_front")
			
		deal_attack_timer.start()

func _on_deal_attack_timeout() -> void:
	deal_attack_timer.stop()
	attacking = false
	# Matikan Area2D setelah serangan selesai
	attack_hitbox_shape.disabled = true

# --- LOGIKA MENERIMA DAMAGE (MUSUH -> PLAYER) ---
func receive_damage(dmg_amount: int, enemy_pos: Vector2 = Vector2.ZERO):
	if not life or not can_take_damage:
		return 
	current_health -= dmg_amount
	print("Player terkena pukulan! Sisa HP: ", current_health)
	healthChange.emit(current_health)
	if enemy_pos != Vector2.ZERO:
		is_knocked_back = true
		
		# Rumus Arah: (Posisi Saya - Posisi Musuh) = Arah Menjauh
		var knockback_dir = (global_position - enemy_pos).normalized()
		
		# Set kecepatan lemparan
		velocity = knockback_dir * knockbackPower
		
		# Buat Timer singkat (misal 0.2 detik) untuk berhenti terpental
		get_tree().create_timer(0.2).timeout.connect(_on_knockback_finished)
	can_take_damage = false
	hurtbox_cooldown.start() 
	
	if current_health <= 0:
		die()
# Fungsi kecil untuk mengembalikan kontrol
func _on_knockback_finished():
	is_knocked_back = false
	velocity = Vector2.ZERO # Stop mendadak agar tidak licin
	
func _on_hurtbox_cooldown_timeout():
	can_take_damage = true

# --- SISTEM KEMATIAN ---
func die():
	life = false
	anim.play("die")
	print("Player Tewas")
	death_timer.start()

func _on_death_timeout() -> void:
	print("Game Over")
	get_tree().paused = true
	var game_over_scene = load("res://scene/game_over.tscn") 
	var game_over_instance = game_over_scene.instantiate()
	get_tree().get_root().add_child(game_over_instance)
