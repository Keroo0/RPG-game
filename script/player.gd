extends CharacterBody2D

const  kecepatan:int = 150
var arah:String= "diam"

func _physics_process(delta: float) -> void:
	gerak(delta)

func gerak(delta):
	if Input.is_action_pressed("ui_right"):
		velocity.x = kecepatan 
		velocity.y = 0
		arah = "kanan"
		arah_player("diam")
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -kecepatan 
		velocity.y = 0
		arah = "kiri"
		arah_player(true)
	elif Input.is_action_pressed("ui_up"):
		velocity.x = 0
		velocity.y = -kecepatan
		arah = "atas"
		arah_player(true)
	elif Input.is_action_pressed("ui_down"):
		velocity.x = 0
		velocity.y = kecepatan
		arah = "bawah"
		arah_player(true)
	else:
		arah_player(false)
		velocity.x = 0
		velocity.y = 0
	move_and_slide();
	
func arah_player(move):	
	var arah_sekarang = arah
	var animasi = $AnimatedSprite2D
	if arah_sekarang == "kanan":
		animasi.flip_h = false
		if move :
			animasi.play("jalan_kanan")
		else:
			animasi.play("diam")
	elif arah_sekarang == "kiri":
		animasi.flip_h = true
		if move :
			animasi.play("jalan_kanan")
		else:
			animasi.play("diam")
	elif arah_sekarang == "atas":
		animasi.flip_h = false
		if move :
			animasi.play("jalan_atas")
		else:
			animasi.play("diam")
	elif arah_sekarang == "bawah":
		animasi.flip_h = false
		if move :
			animasi.play("jalan_bawah")
		else:
			animasi.play("diam")
			
	
