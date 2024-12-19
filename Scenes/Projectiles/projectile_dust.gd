extends RigidBody2D

var throwForce : float = 2000
#When the player hits the projetile
func _on_hurtbox_area_entered(area):
	var dustPos : Vector2 = global_position
	var playerPos : Vector2 = area.global_position
	if dustPos > playerPos:
		linear_velocity = Vector2(throwForce, -500)
		print(">")
	else:
		linear_velocity = Vector2(-throwForce, -500)
		print("<")
