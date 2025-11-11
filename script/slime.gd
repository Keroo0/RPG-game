extends CharacterBody2D


var speed = 10
var player_chase = false
var player = null
var arah_terakhir = "front"  # untuk simpan arah terakhir
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var  health = 40
var player_in_range = false
var can_damaged = true
@onready var receive_damage: Timer = $receive_damage
@onready var death: Timer = $death
var is_in_knockback: bool = false
@export var knockback_power: int = 300 # Kecepatan terpental

signal died


func _physics_process(delta: float) -> void:
	if is_in_knockback:
		move_and_slide()
		return # <--- Hentikan fungsi di sini
	deal_with_damage()
	if player_chase and player:
		var direction = (player.position - position).normalized()
		position = position.move_toward(player.position, speed * delta)
		_update_animation(direction)
	else:
		anim.play("idle_" + arah_terakhir)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		player_chase = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_chase = false
		anim.play("idle_" + arah_terakhir)

func _update_animation(direction: Vector2) -> void:
	# Tentukan arah utama
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			anim.play("walk_side")
			anim.flip_h = false
			arah_terakhir = "side"
		else:
			anim.play("walk_side")
			anim.flip_h = true
			arah_terakhir = "side"
	else:
		if direction.y < 0:
			anim.play("walk_back")
			arah_terakhir = "back"
		else:
			anim.play("walk_front")
			arah_terakhir = "front"
func enemy():
	pass
	


func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_range = true


func _on_hit_box_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
			player_in_range = false
			
func deal_with_damage():
	if player_in_range and Global.player_is_attacking == true:
		if can_damaged == true:
			health -= 20
			print("darah nya sisa = ", health)
			receive_damage.start()
			can_damaged = false    
			
		# --- LOGIKA KNOCKBACK DIMULAI ---
			is_in_knockback = true
			if player != null: # Pastikan kita tahu posisi player
				# Hitung arah menjauh dari player
				var knockback_direction = (global_position - player.global_position).normalized()
				velocity = knockback_direction * knockback_power
			
			# Buat timer singkat untuk menghentikan knockback
			get_tree().create_timer(0.2).timeout.connect(_on_knockback_finished)
			# --- LOGIKA KNOCKBACK SELESAI ---
			if health <= 0:
				player_in_range = false
				can_damaged = false
				anim.play("die")
				speed = 0
				died.emit()
				death.start()
		
func _on_receive_damage_timeout() -> void:
	can_damaged = true


func _on_death_timeout() -> void:
	queue_free()
func _on_knockback_finished():
	is_in_knockback = false
