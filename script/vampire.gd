extends CharacterBody2D
var speed:int = 100
var health:int = 800
var attack:int = 50
var lari = speed + 50
@onready var vampir: CharacterBody2D = $"."
var player_on_range = false
var can_hit = true
var last_dir = "front"|"back"|"side"

func movement():
	if player_on_range == true:
		
	
