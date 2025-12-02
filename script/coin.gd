extends Area2D

var value: int = 10 # Default, nanti diubah oleh Musuh saat spawn

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Animasi simpel: Naik turun (Tween)
	var tween = create_tween().set_loops()
	tween.tween_property($AnimatedSprite2D, "position:y", -5.0, 1.0).as_relative()
	tween.tween_property($AnimatedSprite2D, "position:y", 5.0, 1.0).as_relative()

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("Player"):
		GameManager.add_coin(value)
		
		# (Opsional) Play Sound di sini jika ada AudioManager
		queue_free()
