extends CharacterBody2D

@onready var animationTree : AnimationTree = $PlayerAnimationTree
@onready var bodySprite : Sprite2D = $BodySprite
@onready var PawSprite : Sprite2D = $BodySprite/PawSprite
@onready var hitbox : CollisionShape2D = $Hitbox/HitboxCollision
@onready var holdPos : Marker2D = $holdingHand
@onready var throwPos : Marker2D = $ThrowingHand
@onready var PowerIconRect : TextureRect = $PlayerUI/AspectRatioContainer/HUD_PowerFrame/HUD_PowerIcon
@onready var ShieldCount : Label = $PlayerUI/AspectRatioContainer/HSplitContainer/HUD_ShieldCount
@onready var coyotrTimer : Timer = $coyoteTimer
@onready var powerupTimer : Timer = $powerupTimer
var closeItem : RigidBody2D
var closeHazard : RigidBody2D

@export var cinematicPlaying : bool
var RunSpeed:float = 750
var HoldSpeed:float = 650
var SPEED : float #Movement speed
var JUMP_VELOCITY : float = -850 #Jump force
var Jump_XSpeed : float = 0 #Speed stored when jumping
var Punch_XSpeed : float = 0 # Speed stored when punching
var is_grounded : bool = true
var direction : float = 0
var can_Hold : bool = false
var is_Holding : bool = false
var is_Hurt : bool = false
var is_Jumping : bool = false
var lastFrameFallState : bool = false

var maxShields : int = 3
var currentShields : int = 0
var currentPower : String = "None"
var damage : int = 1

var animHold : int = -1
var animJumpState : int = -1
var blockWalkAnimations : bool = false
var animPunching : bool = false

var animations = ["parameters/conditions/animIdle", "parameters/conditions/animJumping",
"parameters/conditions/animRun", "parameters/conditions/animPunch",
"parameters/conditions/animHurt", "parameters/conditions/animDie"]
var powerIconsPath = [null, "res://Sprites/Placeholders/HUD/Placeholder_DoubleDmg.png",
"res://Sprites/Placeholders/HUD/Placeholder_DoubleJump.png",
"res://Sprites/Placeholders/HUD/Placeholder_Invulnerability.png"]

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	PowerIconRect.texture = null
	SPEED = RunSpeed
	anim_parameters(0)

func _physics_process(delta):
	throwPos.global_position = hitbox.global_position + Vector2(bodySprite.scale.x * 10, -50)
	PawSprite.visible = not hitbox.disabled
	hitbox.global_position = PawSprite.global_position
	is_grounded = is_on_floor()
	#gravity
	if not is_grounded:
		velocity.y += gravity * delta
	if not cinematicPlaying: _GameplayMove(delta)
	move_and_slide()

func _GameplayMove(delta):
	if is_Holding: _move_holded_item()
	if animPunching: velocity.x = Punch_XSpeed * 2
	if is_grounded and not animPunching and not is_Hurt:
		is_Jumping = false
		animJumpState = 1
		anim_parameters(1)
	
	if lastFrameFallState and not is_grounded and not is_Jumping and not animPunching and not is_Hurt:
		coyotrTimer.start()
		is_Jumping = true
		blockWalkAnimations = true
		animJumpState = 0
		anim_parameters(1)
		lastFrameFallState = false
	
	if not is_Holding: animHold = -1
	else: animHold = 1
	#inputs
	if Input.is_action_just_pressed("play_jump") and (is_grounded or not coyotrTimer.is_stopped()) and not animPunching and not is_Hurt:
		jump()
	
	if not is_Hurt: player_movement()
	else : playerHurtMovement()
	player_actions()
	lastFrameFallState = is_grounded

func _CinematicMove():
	pass

func jump():
	is_Jumping = true
	blockWalkAnimations = true
	velocity.y = JUMP_VELOCITY
	Jump_XSpeed = velocity.x
	animJumpState = -1
	anim_parameters(1)

func player_movement():
	direction = Input.get_axis("play_left", "play_right")
	if direction and not animPunching:
		bodySprite.scale.x = direction
		if is_grounded:
			if not blockWalkAnimations: anim_parameters(2)
			velocity.x = direction * SPEED
		else:
			if (Jump_XSpeed <= 0 && direction > 0): Jump_XSpeed = 0
			elif (Jump_XSpeed >= 0 && direction < 0): Jump_XSpeed = 0
			velocity.x = direction * SPEED / 2 + (Jump_XSpeed / 2)
	else:
		if is_grounded:
			if not blockWalkAnimations and not animPunching: anim_parameters(0)
			velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			if (Jump_XSpeed <= 0 && direction > 0): Jump_XSpeed = 0
			elif (Jump_XSpeed >= 0 && direction < 0): Jump_XSpeed = 0
			velocity.x = move_toward(velocity.x, 0, SPEED) / 2 + (Jump_XSpeed / 2)

func playerHurtMovement():
	if is_grounded and coyotrTimer.is_stopped():
		is_Hurt = false
		anim_parameters(0)

func _input(event):
	if event.is_action_pressed("play_punch") and not is_Holding and not animPunching:
		Punch_XSpeed = velocity.x
		animPunching = true
		anim_parameters(3)
	if event.is_action_pressed("play_scrap") and is_Holding and closeItem != null:
		currentShields += 1
		if currentShields >= maxShields: currentShields = maxShields
		ShieldCount.text = str(currentShields)
		#print(currentShields)
		_destroyHolded()
	if event.is_action_pressed("play_use") and is_Holding and closeItem != null:
		_useHolded()

func _destroyHolded():
	closeItem.queue_free()
	closeItem = null
	is_Holding = false
	SPEED = RunSpeed

func _useHolded():
	currentPower = closeItem.itemType
	match currentPower:
		"Damage": PowerIconRect.texture = load(powerIconsPath[1])
		"Jump": PowerIconRect.texture = load(powerIconsPath[2])
		"Invulnerability": PowerIconRect.texture = load(powerIconsPath[3])
	closeItem.queue_free()
	closeItem = null
	is_Holding = false
	SPEED = RunSpeed

func _playerHurt(hurtSource):
	coyotrTimer.start()
	hurtSource.queue_free()
	is_Hurt = true
	anim_parameters(4)
	velocity = Vector2(velocity.x, -1000)
	currentShields -= 1
	if currentShields <= 0:
		currentShields = 0
		_playerDeath()
	ShieldCount.text = str(currentShields)

func _playerDeath():
	print("You died")
	pass

func player_actions():
	if Input.is_action_just_pressed("play_hold") and is_grounded and can_Hold:
		if closeItem != null and closeItem is RigidBody2D:
			is_Holding = true
			SPEED = HoldSpeed
	if Input.is_action_pressed("play_hold") and is_grounded and is_Holding:
		SPEED = HoldSpeed
	if Input.is_action_just_released("play_hold"):
		SPEED = RunSpeed
		if is_Holding:
			closeItem.global_position = throwPos.global_position
			closeItem.linear_velocity = Vector2(2000 * bodySprite.scale.x, -500)
		is_Holding = false
		closeItem = null
	
	match is_Holding:
		true: animHold = 1
		false: animHold = -1
	animationTree["parameters/Idle/blend_position"].x = animHold
	animationTree["parameters/Jump/blend_position"].x = animHold
	animationTree["parameters/Run/blend_position"].x = animHold

func _move_holded_item():
	var obj = closeItem.global_position
	var hand = holdPos.global_position
	closeItem.set_linear_velocity((hand-obj)*25)

func anim_parameters(param:int): #0. Idle|1. Jump|2. Run|3. Punch|4. Hurt|5. Die
	for i in range(5):
		if i != param: animationTree[animations[i]] = false
		else: animationTree[animations[i]] = true
	
	animationTree["parameters/Jump/blend_position"].y = animJumpState #Where -1 is the start, 0 middle, and 1 finish

func _on_player_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Player_JumpStart":
			animJumpState = 0
			anim_parameters(1)
		"Player_JumpStop":
			animJumpState = -1
			blockWalkAnimations = false
			anim_parameters(0)
		"Player_HoldJumpStart":
			animJumpState = 0
			anim_parameters(1)
		"Player_HoldJumpStop":
			animJumpState = -1
			blockWalkAnimations = false
			anim_parameters(0)
		"Player_punch":
			animPunching = false
			if is_grounded: 
				anim_parameters(0)
			else:
				animJumpState = 0
				anim_parameters(1)

func _on_interact_box_body_entered(body):
	#print("bodyEntered")
	can_Hold = true
	closeItem = body

func _on_interact_box_body_exited(area):
	if not is_Holding:
		#print("bodyExited")
		can_Hold = false
		closeItem = null
#When the player gets hit
func _on_hurtbox_area_entered(area):
	if not is_Hurt: _playerHurt(area.owner)
