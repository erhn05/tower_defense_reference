extends Node

onready var mob = preload("res://mob.tscn")
onready var tower = preload("res://tower.tscn")
onready var projectile = preload("res://projectile.tscn")

var mobs_remaining = 0
var level = 0
var lives = 100
var points = 0
var gold = 0

var can_place_tower = false
var invalid_tiles

func _ready():
	# start the timer
	$mob_spawn_timer.start(60)
	mobs_remaining = 5
	
	$user_interface/lives.text = "Lives: " + str(lives)
	
	# towers cannot be placed on these tiles
	invalid_tiles = $nav/tilemap_nav.get_used_cells()
	
	# update score
	$user_interface/points.text = str(points)

func _process(delta):
	# show the timer
	$user_interface/next_wave_time.text = str(int($mob_spawn_timer.time_left))

func _unhandled_input(event):
	if event is InputEventMouseMotion and can_place_tower:
		$tower_placement.clear()
		
		# get the tile location of the mouse cursor
		var tile = $tower_placement.world_to_map(event.position)
		
		if not tile in invalid_tiles:
			# color green / valid tile
			$tower_placement.set_cell(tile.x, tile.y, 0)
		else:
			# color red / invalid tile
			$tower_placement.set_cell(tile.x, tile.y, 1)
	elif event is InputEventMouseButton and can_place_tower and event.pressed:
		# get the tile location of the mouse cursor
		var tile = $tower_placement.world_to_map(event.position)
		
		if not tile in invalid_tiles:
			can_place_tower = false
			$tower_placement.clear()
			
			# the tile is now invalid for other towers
			invalid_tiles.append(tile)
			
			# place the tower
			var tower_instance = tower.instance()
			tower_instance.connect("shoot_projectile", self, "shoot_projectile")
			tower_instance.position = tile * Vector2(64, 64)
			$entities.add_child(tower_instance)

func shoot_projectile(origin, target):
	var projectile_instance = projectile.instance()
	projectile_instance.origin_pos = origin
	projectile_instance.target_pos = target
	$entities.add_child(projectile_instance)

func _on_mob_spawn_timer_timeout():
	if mobs_remaining >= 5:
		level += 1
		$user_interface/level.text = "Level: " + str(level)
	
	# make an instance of the mob
	var mob_instance = null
	mob_instance = mob.instance()
	mob_instance.connect("mob_defeated", self, "mob_defeated")
	mob_instance.connect("lose_a_life", self, "lose_a_life")
	
	# set the starting position and the destination
	mob_instance.position = $start_position.position
	mob_instance.destination = $end_position.position
	
	mob_instance.level = level
	
	# set the path it is going to follow
	var path = $nav.get_simple_path($start_position.position, $end_position.position)
	mob_instance.set_path(path)
	
	# add the mob to the entities container
	$entities.add_child(mob_instance)
	
	# disable "next wave" button
	$user_interface/start_next_wave.disabled = true
	
	mobs_remaining -= 1
	if mobs_remaining > 0:
		$mob_spawn_timer.start(1)
	else:
		# reset the timer for the next wave
		$mob_spawn_timer.start(60)
		# reset the mobs_remaining counter
		mobs_remaining = 5
		# enable "next wave" button
		$user_interface/start_next_wave.disabled = false

func mob_defeated():
	points += 1
	$user_interface/points.text = str(points)
	
	gold += 1 * level
	$user_interface/gold.text = "Gold: " + str(gold)

func lose_a_life():
	lives -= 1
	$user_interface/lives.text = "Lives: " + str(lives)

func _on_start_next_wave_pressed():
	_on_mob_spawn_timer_timeout()

func _on_tower_pressed():
	$tower_placement.clear()
	can_place_tower = !can_place_tower
