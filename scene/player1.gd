extends Entity # <--- PERUBAHAN 1: Warisi dari Entity (Bapaknya)

# --- ATRIBUT PLAYER (KHUSUS PLAYER) ---
@export var speed: int = 100
# CATATAN: max_health, health, dan knockback_resistance sudah ada di Entity!
# Jangan ditulis lagi di sini.

# --- STATE VARIABLES ---
var current_dir = "down"
var attacking: bool = false
# CATATAN: is_dead, knockback_vector sudah ada di Entity!

# --- REFERENSI NODE ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var deal_attack_timer: Timer = $deal_attack
@onready var death_timer: Timer = $death
@onready var attack_hitbox: Area2D = $AttackHitBox # Pastikan ini Area2D
@onready var hurtbox_cooldown: Timer = $hurt_box/cooldown

func _ready():
	# 1. Sinkronisasi Darah dengan Global (Bank Data)
	# Karena Entity yang pegang health, kita isi health Entity pakai data Global
	current_health = GameManager.current_health
	max_health = GameManager.max_health
	
	# 2. Sambungkan Sinyal dari BAPAK (Entity) ke fungsi lokal
	# Saat Entity bilang "aduh sakit", Player mainkan animasi
	on_hit.connect(_play_hurt_anim)
	on_died.connect(_play_death_anim)
	on_health_changed.connect(_update_global_data)

	# 3. Setup awal
	$AttackHitBox/areaAttack.disabled = true # Matikan hitbox di awal

func _physics_process(delta: float) -> void:
	# Panggil Logic Bapak dulu (untuk urus Knockback otomatis)
	super._physics_process(delta) 
	
	if is_dead: return # Cek variabel bapak (is_dead)
	
	# Logic Gerakan Lama Kamu (Saya pertahankan)
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		playerMovement(delta)
		
	attack_input()

# --- GERAKAN (KODE LAMA - DIPERTAHANKAN) ---
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

# --- SERANGAN (DIPERBARUI DIKIT) ---
func attack_input():
	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true
		
		# Nyalakan Hitbox Manual (Karena kamu belum pakai AnimationPlayer)
		$AttackHitBox/areaAttack.disabled = false 
		
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
	$AttackHitBox/areaAttack.disabled = true

# --- UPDATE PENTING: SIGNAL & GLOBAL ---
func _update_global_data(new_hp):
	# Lapor ke Global Manager biar UI update
	GameManager.current_health = new_hp
	GameManager.health_changed.emit(new_hp)

# --- VISUAL EFEK (Override) ---
# Kita tidak butuh func receive_damage() lagi karena Entity sudah punya.
# Kita cuma butuh "Efek Visual"-nya saja.

func _play_hurt_anim(attacker_pos):
	# Animasi sakit
	# anim.play("hurt") # Kalau ada animasi hurt
	# Flash merah atau getar layar bisa ditaruh di sini
	print("Player: Aww sakit! (Visual Only)")

func _play_death_anim():
	anim.play("die")
	print("Player: Mati, mainkan animasi...")
	death_timer.start()

func _on_death_timeout() -> void:
	print("Game Over Logic")
	GameManager.player_died.emit()
	# Panggil scene Game Over di sini
	get_tree().paused = true
	var game_over_scene = load("res://scene/game_over.tscn")
	var game_over_instance = game_over_scene.instantiate()
	get_tree().get_root().add_child(game_over_instance)
