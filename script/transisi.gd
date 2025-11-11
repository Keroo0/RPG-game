extends CanvasLayer

var transisi_on : bool = false
@onready var tirai: ColorRect = $Tirai

func fade_out(scene_path:String) -> void:
	if transisi_on :
		return
	transisi_on = true

	var tween = create_tween()
	tween.tween_property(tirai, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# 2. Tunggu animasi selesai
	await tween.finished
	
	# 3. Pindahkan scene
	get_tree().change_scene_to_file(scene_path)
	
	# 4. (Opsional) Beri jeda sedikit agar scene baru sempat termuat
	await get_tree().create_timer(0.1).timeout
	
	# 5. Kembalikan layar jadi transparan (fade in)
	fade_in()
	
	
# Called when the node enters the scene tree for the first time.
func fade_in() -> void:
	# 1. Animasi dari hitam pekat (alpha 1) ke transparan (alpha 0)
	var tween = create_tween()
	tween.tween_property(tirai, "modulate", Color(1, 1, 1, 0), 0.5)
	
	# 2. Tunggu animasi selesai
	await tween.finished
	transisi_on = false
