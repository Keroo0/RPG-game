class_name Entity extends CharacterBody2D

# --- STATS UNIVERSAL ---
# Semua makhluk punya HP. Tidak perlu nulis ini lagi di Player/Musuh.
@export var max_health: int = 100
@onready var current_health: int = max_health

# --- STATE ---
var is_dead: bool = false
var knockback_vector: Vector2 = Vector2.ZERO
@export var knockback_resistance: float = 0.0 # 0.0 = Terbang, 1.0 = Batu

# --- SIGNALS ---
# Anak-anaknya (Player/Vampir) akan mendengarkan sinyal ini untuk mainkan animasi
signal on_hit(attacker_pos)
signal on_health_changed(new_hp)
signal on_died

func _physics_process(delta):
	# Logika Knockback Universal
	# Jika ada gaya dorong, Entity akan meluncur mundur
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector
		# Gaya gesek: Knockback berkurang perlahan
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
		move_and_slide()

# --- FUNGSI UTAMA PENERIMA DAMAGE ---
func receive_damage(amount: int, knockback_force: float, attacker_pos: Vector2):
	if is_dead: return
	
	# 1. Kurangi Darah
	current_health -= amount
	# Batasi agar tidak minus
	if current_health < 0: current_health = 0
	
	print(name, " took ", amount, " damage. HP Left: ", current_health)
	
	# 2. Kabari UI dan Animasi
	on_health_changed.emit(current_health)
	on_hit.emit(attacker_pos)
	
	# 3. Hitung Knockback
	if knockback_force > 0:
		var direction = (global_position - attacker_pos).normalized()
		# Resistance mengurangi efek pentalan
		knockback_vector = direction * (knockback_force * (1.0 - knockback_resistance))
	
	# 4. Cek Kematian
	if current_health <= 0:
		die()

# Fungsi virtual (Bisa ditimpa/override oleh anak)
func die():
	is_dead = true
	on_died.emit()
	# Default behaviour: Hilang. 
	# Nanti Player/Vampir akan override ini untuk animasi mati yang keren.
