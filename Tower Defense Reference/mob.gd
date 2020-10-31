extends Area2D

var destination = Vector2()
var path : = PoolVector2Array() setget set_path
var speed = 100
var sprite_direction = "front"
var hp = 3
var level = 1

signal mob_defeated
signal lose_a_life

func _ready():
	randomize()
	var animation_speed = rand_range(0.9, 1.1)
	$animation.playback_speed = animation_speed
	$animation.play(sprite_direction)
	
	# hp increases every round/level
	hp = 3 * level

func _physics_process(delta):
	if path.size() > 0:
		# move along the path if the mob hasn't reached destination
		var distance = speed * delta
		move_along_path(distance)
	elif abs(position.x - destination.x) < 10 and abs(position.y - destination.y) < 10:
		# free the mob when it reaches destination
		queue_free()
		emit_signal("lose_a_life")

func move_along_path(distance):
	var start_pos = position
	
	# while there is still a path
	for i in range(path.size()):
		# move to the next position on the path
		var distance_to_next = start_pos.distance_to(path[0])
		set_animation(path[0] - start_pos)
		if distance <= distance_to_next and distance > 0:
			position = start_pos.linear_interpolate(path[0], distance / distance_to_next)
			break
		elif distance <= 0:
			position = path[0]
			break
		
		distance -= distance_to_next
		start_pos = path[0]
		path.remove(0)

func set_path(new_path):
	# the path is set in the main script
	path = new_path

func set_animation(direction):
	var angle = 0
	
	if direction.x != 0 or direction.y != 0:
		if direction.x == 0:
			if direction.y > 0:
				angle = 0
			elif direction.y > 0:
				angle = 180
		elif direction.y == 0:
			if direction.x > 0:
				angle = 270
			elif direction.x < 0:
				angle = 90
		else:
			angle = atan(direction.x / direction.y) * 360 / (2 * PI)
		
			if direction.x >= 0 and direction.y >= 0:
				angle = 360 - angle
			elif direction.x >= 0 and direction.y <= 0:
				angle = 180 + abs(angle)
			elif direction.x <= 0 and direction.y >= 0:
				angle = abs(angle)
			elif direction.x <= 0 and direction.y <= 0:
				angle = 180 - angle
	
	if angle == 0 or angle >= 315 or angle <= 45:
		if not sprite_direction == "front":
			sprite_direction = "front"
			$animation.play(sprite_direction)
	elif angle >= 35 and angle <= 135:
		if not sprite_direction == "left":
			sprite_direction = "left"
			$animation.play(sprite_direction)
	elif angle >= 135 and angle <= 225:
		if not sprite_direction == "back":
			sprite_direction = "back"
			$animation.play(sprite_direction)
	elif angle >= 225 and angle <= 315:
		if not sprite_direction == "right":
			sprite_direction = "right"
			$animation.play(sprite_direction)

func take_damage(damage):
	hp -= damage
	if hp <= 0:
		emit_signal("mob_defeated")
		queue_free()
