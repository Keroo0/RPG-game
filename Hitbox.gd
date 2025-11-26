class_name Hitbox extends Area2D

@export var damage: int = 10
@export var knockback_force: float = 300.0

func _ready():
	# Pastikan sinyal terhubung
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	# Debugging awal
	print("[Hitbox] Siap di: ", get_parent().name, " | Damage: ", damage)

func _on_area_entered(area):
	# 1. Cek siapa yang kena
	print("--- HITBOX DETECTED ---")
	print("Senjata: ", get_parent().name)
	print("Menabrak Area: ", area.name)
	
	var victim = area.get_parent()
	print("Induk Korban: ", victim.name)

	# 2. Cek apakah korban adalah DIRI SENDIRI (Jangan bunuh diri)
	if victim == owner:
		print(">> SKIP: Ini diri sendiri.")
		return

	# 3. METODE BARU: Cek apakah korban punya fungsi 'receive_damage'
	# Ini lebih aman daripada cek 'is Entity'
	if victim.has_method("receive_damage"):
		print(">> EXECUTE: Memukul ", victim.name, " sebesar ", damage)
		victim.receive_damage(damage, knockback_force, global_position)
	else:
		print(">> GAGAL: ", victim.name, " tidak punya fungsi receive_damage!")
