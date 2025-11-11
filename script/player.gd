extends CharacterBody2D

const KECEPATAN: int = 100
@onready var animasi: AnimatedSprite2D = $AnimatedSprite2D

var arah_terakhir := Vector2(0, 1) # hadap bawah
var sedang_menyerang := false

func _ready() -> void:
	# Pastikan animasi serangan tidak loop (wajib agar animation_finished bisa terpanggil)
	for nama in ["hit_depan", "hit_belakang", "hit_samping"]:
		if animasi.sprite_frames.has_animation(nama):
			animasi.sprite_frames.set_animation_loop(nama, false)

	# Pastikan sinyal terhubung (hindari masalah nama fungsi/case-sensitive)
	if not animasi.is_connected("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished")):
		animasi.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(delta: float) -> void:
	if sedang_menyerang:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vektor := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vektor.normalized() * KECEPATAN
	move_and_slide()
	perbarui_animasi_gerak(input_vektor)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and not sedang_menyerang:
		gebuk()

func perbarui_animasi_gerak(input_vektor: Vector2) -> void:
	if input_vektor != Vector2.ZERO:
		arah_terakhir = input_vektor
		if not sedang_menyerang:
			animasi.play()
	else:
		if not sedang_menyerang:
			animasi.stop()

	# Pilih animasi gerak
	if arah_terakhir.y > 0.5:
		animasi.animation = "jalan_bawah"
	elif arah_terakhir.y < -0.5:
		animasi.animation = "jalan_atas"
	elif abs(arah_terakhir.x) > 0.5:
		animasi.animation = "jalan_kanan"

	# Flip untuk kiri/kanan
	animasi.flip_h = arah_terakhir.x < 0

func gebuk() -> void:
	sedang_menyerang = true
	# Mulai dari frame 0 supaya tegas satu ayunan
	animasi.frame = 0

	if arah_terakhir.y > 0.5:
		animasi.play("hit_depan")
	elif arah_terakhir.y < -0.5:
		animasi.play("hit_belakang")
	else:
		animasi.play("hit_samping")

func _on_animated_sprite_2d_animation_finished() -> void:
	# Hanya reset bila yang selesai adalah animasi serangan
	if animasi.animation.begins_with("hit_"):
		sedang_menyerang = false
