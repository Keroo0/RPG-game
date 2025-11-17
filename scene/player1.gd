extends CharacterBody2D

class_name Player

@export var speed:int = 100
var current_dir = "down"
@export var max_health:int = 500
@onready var current_health:int = max_health

# --- 1. TAMBAHKAN ATRIBUT INI ---
# Ini adalah damage yang akan dibaca oleh skrip musuh
@export var attack_damage: int = 20
# ---------------------------------

var life = true
var in_attack_range = false
var cooldown_attack = true
@onready var cooldown: Timer = $hitbox/cooldown
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
var attacking = false
@onready var deal_attack: Timer = $deal_attack
@onready var death: Timer = $death
signal healthChange(current_health)
@export var knockbackPower = 50

@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitBox/areaAttack

func _physics_process(delta: float) -> void:
	# Jika sedang menyerang, hentikan gerakan
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
	
	# Hanya izinkan gerakan jika TIDAK menyerang
	if not attacking:
		playerMovement(delta)
		
	attack()
	
	if current_health <= 0 and life == true:
		life = false
		anim.play("die")
		speed = 0
		print("tewas")
		death.start()

func playerMovement(delta):
	# (Kode playerMovement Anda tidak berubah, sudah bagus)
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		play_anim(1)
		velocity.x = 0
		velocity.y = -speed
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		play_anim(1)
		velocity.x = 0
		velocity.y = speed
	else:
		play_anim(0)
		velocity.x = 0
		velocity.y = 0
	move_and_slide()
	
func play_anim(movement):
	# (Kode play_anim Anda tidak berubah)
	# JANGAN mainkan animasi 'walk'/'idle' jika sedang menyerang
	if attacking:
		return
		
	var dir = current_dir
	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_side")
		elif movement == 0:
			anim.play("idle_side")
	if dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_side")
		elif movement == 0:
			anim.play("idle_side")
	if dir == "up":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_back")
		elif movement == 0:
			anim.play("idle_back")
	if dir == "down":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_front")
		elif movement == 0:
			anim.play("idle_front")
		
func player():
	pass


# FUNGSI INI ADALAH UNTUK SAAT PLAYER DISERANG
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and cooldown_attack == true:
		enemy_attack(body)
		in_attack_range = true	


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		in_attack_range = false

# FUNGSI INI DIPANGGIL SAAT PLAYER DISERANG
func enemy_attack(attacker:Node2D):
	
	# --- 2. UBAH LOGIKA DAMAGE INI ---
	# Ambil damage dari atribut si penyerang (attacker/musuh)
	var damage_received = attacker.attack_damage
	current_health -= damage_received # Gunakan damage dari musuh
	# ---------------------------------
	
	cooldown_attack = false
	cooldown.start()
	print(current_health)
	healthChange.emit(current_health)
	
func _on_cooldown_timeout() -> void:
	cooldown_attack = true	

# FUNGSI INI ADALAH UNTUK SAAT PLAYER MENYERANG
func attack():
	var dir = current_dir
	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true
		attack_hitbox_shape.disabled = false
		
		# (Sisa kode animasi Anda)
		if dir == "right":
			anim.flip_h = false
			anim.play("hit_side")
			deal_attack.start()
		if dir == "left":
			anim.flip_h = true
			anim.play("hit_side")
			deal_attack.start()
		if dir == "up":
			anim.flip_h = false
			anim.play("hit_back")
			deal_attack.start()
		if dir == "down":
			anim.flip_h = false
			anim.play("hit_front")
			deal_attack.start()
			
func _on_deal_attack_timeout() -> void:
	deal_attack.stop()
	attacking = false
	attack_hitbox_shape.disabled = true
	
func _on_death_timeout() -> void:
	print("gameover")
	get_tree().paused = true
	var game_over_scene = load("res://scene/game_over.tscn")
	var game_over_instance = game_over_scene.instantiate()
	get_tree().get_root().add_child(game_over_instance)
