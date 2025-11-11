extends CharacterBody2D

class_name Player


@export var speed:int = 100
var current_dir = "down"
@export var max_health:int = 500
@onready var current_health:int = max_health
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
var is_in_knockback: bool = false
	



func _physics_process(delta: float) -> void:
	if is_in_knockback:
		move_and_slide()
		return # <-- Hentikan gerakan player
	playerMovement(delta)
	attack()
	
	# Tambahkan 'and life == true'
	if current_health <= 0 and life == true:
		life = false # <-- 'life' menjadi 'false' di sini
		anim.play("die")
		# Kita tidak perlu lagi 'current_health = 0' karena 'life' sudah jadi 'false'
		speed = 0
		print("tewas")
		death.start() # <-- Ini sekarang HANYA akan dipanggil SATU KALI


func playerMovement(delta):
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
	var dir = current_dir
	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_side")
		elif movement == 0:
			if attacking == false:
				anim.play("idle_side")
	if dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_side")
		elif movement == 0:
			if attacking == false:
				anim.play("idle_side")
	if dir == "up":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_back")
		elif movement == 0:
			if attacking == false:
				anim.play("idle_back")
	if dir == "down":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_front")
		elif movement == 0:
			if attacking == false:
				anim.play("idle_front")
		
func player():
	pass


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and cooldown_attack == true:
		enemy_attack(body)
		in_attack_range = true	
	


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		in_attack_range = false

		
func enemy_attack(attacker:Node2D):
	#if in_attack_range and cooldown_attack == true:
		current_health-= 20
		cooldown_attack = false
		cooldown.start()
		print(current_health)
		healthChange.emit(current_health)

func _on_cooldown_timeout() -> void:
	cooldown_attack = true	
func attack():
	var dir = current_dir
	if Input.is_action_just_pressed("attack"):
		Global.player_is_attacking = true
		attacking = true
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
	Global.player_is_attacking = false
	attacking = false


func _on_death_timeout() -> void:
	print("gameover")
	get_tree().paused = true
	# 2. Muat scene game over
	var game_over_scene = load("res://scene/game_over.tscn")
	var game_over_instance = game_over_scene.instantiate()
	# 3. Tampilkan scene game sover di atas layar
	get_tree().get_root().add_child(game_over_instance)
	
func _on_knockback_finished():
	is_in_knockback = false
	
