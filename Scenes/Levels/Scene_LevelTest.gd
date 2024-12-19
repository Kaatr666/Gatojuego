extends Node

var Boxes = preload("res://Scenes/Items/Box_test.tscn")
var Dusts = preload("res://Scenes/Projectiles/projectile_dust.tscn")

@onready var boxSpawn : Marker2D = $boxSpawn
@onready var dustSpawn : Marker2D = $ProjectileSpawn
@onready var spawnTimer : Timer = $Timer

var timer : float = 0

func _ready():
	spawnTimer.start()

func _process(delta):
	timer += delta
	if spawnTimer.is_stopped(): 
		var boxInst = Boxes.instantiate()
		boxInst.global_position = boxSpawn.global_position
		add_child(boxInst)
		
		var dustInst = Dusts.instantiate()
		dustInst.global_position = dustSpawn.global_position
		add_child(dustInst)
		
		spawnTimer.start()

func _on_area_2d_area_entered(area):
	get_tree().change_scene_to_file("res://Scenes/Levels/scene_level_tutorial.tscn")
