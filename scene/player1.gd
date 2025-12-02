extends Entity 

# --- ATRIBUT GERAKAN ---
@export_group("Movement")
@export var speed: int = 100
@export var dash_speed: int = 300       
@export var dash_duration: float = 0.2  
@export var dash_cooldown: float = 1.5  

# --- ATRIBUT REGENERASI ---
@export_group("Regeneration")
@export var regen_amount: int = 10      
@export var combat_cooldown: float = 5.0 

# --- ATRIBUT POWER UP ---
@export_group("Power Up")
@export var powerup_duration: float = 30.0 # Durasi default (diabaikan jika di-set lewat kode)
@export var damage_multiplier: float = 2.5
@export var speed_multiplier: float = 1.8
@export var aura_scene: PackedScene 
@export var powerup_windup: float = 1.5

# --- SINYAL UI ---
signal dash_cooldown_update(time_left, time_max) 
signal powerup_updated(time_left, time_max, is_active)

# --- STATE VARIABLES ---
var current_dir = "down"
var attacking: bool = false
var is_dashing: bool = false

# State Power Up
var is_powered_up: bool = false
var base_damage: int = 0
var base_speed: int = 100
var current_aura_node: Node2D = null

# --- TIMERS MANUAL (Delta) ---
var combat_timer: float = 0.0           
var regen_timer: float = 0.0            
var dash_cd_timer: float = 0.0          
var powerup_timer: float = 0.0

# --- REFERENSI NODE ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var deal_attack_timer: Timer = $deal_attack
@onready var death_timer: Timer = $death
@onready var attack_hitbox: Area2D = $AttackHitBox 
@onready var hurtbox_cooldown: Timer = $hurt_box/cooldown
@onready var buff_timer: Timer = $BuffTimer # [KITA PAKAI INI LAGI]

#SFX
@onready var sfx_dash: AudioStreamPlayer2D = $SfxDash
@onready var sfx_hurt: AudioStreamPlayer2D = $SfxHurt
@onready var sfx_charge: AudioStreamPlayer2D = $SfxCharge
@onready var sfx_power_up: AudioStreamPlayer2D = $SfxPowerUp
@onready var sfx_attack: AudioStreamPlayer2D = $SfxAttack


func _ready():
	# 1. Sinkronisasi Data
	current_health = GameManager.current_health
	max_health = GameManager.max_health
	
	on_hit.connect(_play_hurt_anim)
	on_died.connect(_play_death_anim)
	on_health_changed.connect(_update_global_data)

	# 2. Setup Awal
	$AttackHitBox/areaAttack.disabled = true 
	
	# 3. Setup Power Up
	base_speed = speed
	var hitbox_node = $AttackHitBox
	if hitbox_node and "damage" in hitbox_node:
		base_damage = hitbox_node.damage
	
	# Spawn Aura (Hidden)
	if aura_scene:
		current_aura_node = aura_scene.instantiate()
		add_child(current_aura_node)
		current_aura_node.position = Vector2.ZERO
		current_aura_node.visible = false

	# KONEKSI TIMER BUFF
	if not buff_timer.timeout.is_connected(_on_buff_timer_timeout):
		buff_timer.timeout.connect(_on_buff_timer_timeout)

func _physics_process(delta: float) -> void:
	super._physics_process(delta) 
	
	if is_dead: return 
	
	# 1. Logic Sistem
	handle_regeneration(delta)
	
	# [LOGIKA BARU] MONITOR TIMER BUFF UNTUK UI
	# Kita intip sisa waktu di Timer Node dan lapor ke UI
	if not buff_timer.is_stopped():
		powerup_updated.emit(buff_timer.time_left, buff_timer.wait_time, true)
	
	# 2. Logic Dash UI
	if dash_cd_timer > 0:
		dash_cd_timer -= delta
		dash_cooldown_update.emit(dash_cd_timer, dash_cooldown)
	else:
		dash_cooldown_update.emit(0, dash_cooldown)

	# 3. Input
	if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0 and not attacking:
		start_dash()

	# 4. Gerak
	if is_dashing:
		dash_movement()
		attack_input() 
	elif attacking:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		playerMovement(delta)
		attack_input()

# --- SYSTEM POWER UP (PAKAI TIMER NODE) ---
func activate_power_up():
	# 1. EFEK VISUAL CHARGING (Kedip-kedip Putih Terang)
	# Kita pakai Tween untuk bikin efek 'Flash'
	sfx_charge.play()
	var tween = create_tween()
	# Ganti warna jadi sangat terang (Glow) lalu normal, ulangi 5x
	for i in range(5):
		tween.tween_property(anim, "modulate", Color(2, 2, 2, 1), 0.1) # Putih Silau
		tween.tween_property(anim, "modulate", Color(1, 1, 1, 1), 0.1) # Normal
	
	# 2. BEKUKAN PEMAIN (Opsional - Biar kayak anime lagi teriak)
	# Kalau gak mau beku, hapus baris 'speed = 0' ini
	var old_speed = speed
	speed = 0 
	
	# 3. TUNGGU WAKTU WINDUP
	await get_tree().create_timer(powerup_windup).timeout
	sfx_power_up.play()
	# --- MASUK MODE SUPER (SETELAH DELAY) ---
	powerup_timer = powerup_duration
	is_powered_up = true
	
	# Naikkan Stats
	speed = int(base_speed * speed_multiplier)
	var hitbox = $AttackHitBox
	if hitbox and "damage" in hitbox:
		hitbox.damage = int(base_damage * damage_multiplier)
	
		
	modulate = Color(0.3, 0.8, 1)
	# Nyalakan Visual
	if current_aura_node:
		current_aura_node.visible = true
		if current_aura_node is AnimatedSprite2D:
			current_aura_node.play("Aura")
		elif current_aura_node.has_node("AnimatedSprite2D"):
			current_aura_node.get_node("AnimatedSprite2D").play("Aura")

	
	# JALANKAN TIMER NODE
	buff_timer.wait_time = powerup_duration # Set 30 detik
	buff_timer.start()
	
	print("MODE SUPER AKTIF (Timer Node)!")

func _on_buff_timer_timeout():
	# Dipanggil otomatis saat Timer Node habis
	deactivate_power_up()

func deactivate_power_up():
	is_powered_up = false
	
	# Kembalikan Stats
	speed = base_speed
	var hitbox = $AttackHitBox
	if hitbox and "damage" in hitbox:
		hitbox.damage = base_damage
		
	# Matikan Visual
	if current_aura_node:
		current_aura_node.visible = false
		if current_aura_node is AnimatedSprite2D:
			current_aura_node.stop()
	
	modulate = Color(1, 1, 1) # Normal
	
	# Matikan UI
	powerup_updated.emit(0, powerup_duration, false)
	print("Mode Super Habis.")

# --- SYSTEM REGENERASI ---
func handle_regeneration(delta):
	if combat_timer > 0:
		combat_timer -= delta
	else:
		if GameManager.current_health < GameManager.max_health:
			regen_timer -= delta
			if regen_timer <= 0:
				heal_player()
				regen_timer = 1.0 

func heal_player():
	var new_hp = GameManager.current_health + regen_amount
	if new_hp > GameManager.max_health: new_hp = GameManager.max_health
	current_health = new_hp
	GameManager.current_health = new_hp
	GameManager.health_changed.emit(new_hp)

func enter_combat_mode():
	combat_timer = combat_cooldown
	regen_timer = 0.0 

# --- SYSTEM DASH ---
func start_dash():
	is_dashing = true
	dash_cd_timer = dash_cooldown 
	
	sfx_dash.play()
	var dash_vector = Vector2.ZERO
	if current_dir == "right": dash_vector = Vector2.RIGHT
	elif current_dir == "left": dash_vector = Vector2.LEFT
	elif current_dir == "up": dash_vector = Vector2.UP
	elif current_dir == "down": dash_vector = Vector2.DOWN
	
	velocity = dash_vector * dash_speed
	
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	if not attacking: velocity = Vector2.ZERO 

func dash_movement():
	move_and_slide()

# --- GERAKAN BIASA ---
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

# --- SERANGAN ---
func attack_input():
	if Input.is_action_just_pressed("attack") and not attacking:
		enter_combat_mode()
		attacking = true
		sfx_attack.pitch_scale = randf_range(0.9, 1.1)
		sfx_attack.play()
		$AttackHitBox/areaAttack.disabled = false 
		
		if current_dir == "right": anim.flip_h = false; anim.play("hit_side")
		elif current_dir == "left": anim.flip_h = true; anim.play("hit_side")
		elif current_dir == "up": anim.flip_h = false; anim.play("hit_back")
		elif current_dir == "down": anim.flip_h = false; anim.play("hit_front")
			
		deal_attack_timer.start()

func _on_deal_attack_timeout() -> void:
	deal_attack_timer.stop()
	attacking = false
	$AttackHitBox/areaAttack.disabled = true
	if is_dashing: is_dashing = false; velocity = Vector2.ZERO

# --- GLOBAL SYNC & VISUAL ---
func _update_global_data(new_hp):
	GameManager.current_health = new_hp
	GameManager.health_changed.emit(new_hp)

func _play_hurt_anim(_attacker_pos):
	enter_combat_mode()
	# anim.play("hurt") 
	sfx_hurt.play()
	print("Player Sakit!")

func _play_death_anim():
	anim.play("die")
	death_timer.start()

func _on_death_timeout() -> void:
	GameManager.player_died.emit()
	get_tree().paused = true
	var game_over_scene = load("res://scene/game_over.tscn")
	var game_over_instance = game_over_scene.instantiate()
	get_tree().get_root().add_child(game_over_instance)
