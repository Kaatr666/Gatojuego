extends Node

@onready var Animations = $CanvasLayer/AnimationPlayer
@onready var PlayButton = $CanvasLayer/MainMenuContainer/MainMenuSet/PlayButton
@onready var BG = $CanvasLayer/ParallaxBackground
@onready var SoundConfirm = $ConfimSound
@onready var SoundQuit = $QuitSound

var state = "Main"
var canMove = true

func _process(delta):
	BG.scroll_offset.x -= 2
	BG.scroll_offset.y += 2

func _ready():
	canMove = true
	state = "Main"
	PlayButton.grab_focus()

func _input(event):
	if event.is_action_pressed("ui_cancel") and state == "Play" and canMove:
		SoundConfirm.pitch_scale = 0.8
		SoundConfirm.play()
		PlayButton.grab_focus()
		Animations.play("Play-Menu")
		state = "Main"
		canMove = false

func _on_play_button_pressed():
	if canMove:
		state = "Play"
		SoundConfirm.pitch_scale = 1
		SoundConfirm.play()
		var RushButton = $CanvasLayer/PlayMenuContainer/VBoxContainer/RushButton
		RushButton.grab_focus()
		Animations.play("PlayEnter")
		canMove = false

func _on_quit_button_pressed():
	SoundQuit.play()

func _on_tutorial_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Levels/scene_level_tutorial.tscn")

func _on_rush_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Levels/scene_level_post.tscn")


func _on_animation_player_animation_finished(anim_name):
	canMove = true

func _on_quit_sound_finished():
	get_tree().quit()
