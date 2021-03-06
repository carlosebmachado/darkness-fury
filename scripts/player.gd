extends KinematicBody2D

const PRE_SPEAR = preload("res://prefabs/spear_hand.tscn")
const SPEED = 200

var finish_dialog_boss = false
var has_spear = false
var loaded = true
var active_skill_bar = false
var start_dead = false
var action_answer # alvo verde - 1 / alvo vermelho - 0
var life_state = 1

#var checkpoint_boss = false

enum {ATTACK, SKILL}
var atk_status = ATTACK

enum {PLAYING, DEAD, BOSS, RESTART, WIN}
var status = PLAYING

func _ready():
	# warning-ignore:return_value_discarded
	$area_hit.connect("hitted", self, "on_area_hitted") 
	# warning-ignore:return_value_discarded
	$area_hit.connect("destroid", self, "on_area_destroid") 
	GAME.player_live = true

# warning-ignore:unused_argument
func _physics_process(delta):
	if status == PLAYING: 
		playing()
	elif status == DEAD:
		dead()
	elif status == BOSS:
		boss()
	elif status == WIN:
		win()

func win():
	get_tree().call_group("skill_bar", "destroy")
	$anim_sprite.play("idle")
	$particles_floor.emitting = false
	if $walking.playing:
		$walking.stop()
		
	if Input.is_action_pressed("ui_leave"):
		get_tree().call_group("Menu", "_on_btn_sair_pressed")

func boss():
	get_tree().call_group("skill_bar", "destroy")
	get_tree().call_group("arena", "init_boss")
	$anim_sprite.play("idle")
	$particles_floor.emitting = false
	if $walking.playing:
		$walking.stop()

func set_status_playing():
	get_tree().call_group("boss", "boss_dialogue_change")
	GAME.boss_dialogue = false
	finish_dialog_boss = true
	status = PLAYING

func playing():
	var x_dir = 0
	var y_dir = 0
	
	if Input.is_action_pressed("ui_right"):
		x_dir += 1
	if Input.is_action_pressed("ui_left"):
		x_dir -= 1
	if Input.is_action_pressed("ui_up"):
		y_dir -= 1
	if Input.is_action_pressed("ui_down"):
		y_dir += 1
	
	if not Input.is_action_pressed("ui_down") and not Input.is_action_pressed("ui_up") and not Input.is_action_pressed("ui_right") and not Input.is_action_pressed("ui_left"):
		$anim_sprite.play("idle")
		$particles_floor.emitting = false
		if $walking.playing:
			$walking.stop()
	else:
		$anim_sprite.play("walk")
		$particles_floor.emitting = true
		if not $walking.playing:
			$walking.play(0)
	
	if Input.is_action_just_pressed("ui_attack") and atk_status == ATTACK:
		init_shoot_spear()
		atk_status = SKILL
	elif Input.is_action_just_pressed("ui_attack") and atk_status == SKILL: 
		skill()
		atk_status = ATTACK
	
	if status != BOSS and not finish_dialog_boss:# and !checkpoint_boss:
#		print(get_tree().get_nodes_in_group("enemy").size())
#		print(GAME.enemys_spawn)
#		print(GAME.KILLS_STOP_SPAWN)
		if get_tree().get_nodes_in_group("enemy").size() <= 0 and GAME.enemys_spawn >= GAME.KILLS_STOP_SPAWN:
			status = BOSS
			$area_hit.health = 30
			life_state = 1
			get_tree().call_group("life_HUD", "start_sprites")
#			checkpoint_boss = true

	if GAME.win:
		status = WIN
	
	if has_spear:
		$spear_hand.show()
	else:
		$spear_hand.hide()
	
	look_at(get_global_mouse_position()) # warning-ignore:return_value_discarded
	move_and_slide(Vector2(x_dir, y_dir) * SPEED)
	
func dead():
	if !start_dead:
		GAME.player_live = false
		$particles_floor.emitting = false
		get_tree().call_group("skill_bar", "destroy")
		GAME.restart()
		$particles_floor.queue_free()
		$particles_hit.queue_free()
		$area_hit.queue_free()
		$shape.queue_free()
		$spear_hand.queue_free()
		$walking.queue_free()
#		$anim_sprite.is_playing()
#		if $anim_sprite.is_playing("walk"):
#			$anim_sprite.stop("walk")
#		if $anim_sprite.is_playing("idle"):
#			$anim_sprite.stop("idle")
		$anim_sprite.play("dead")
		$particles_dead.emitting = true
		start_dead = true
	
	if Input.is_action_pressed("ui_accept"):
#		if checkpoint_boss:
#			pass
#		else:
		restart()

func restart():
	status = RESTART
	get_tree().call_group("Menu", "_on_jogar_pressed")
	queue_free()

func skill():
	if active_skill_bar:		
		get_tree().call_group("skill_bar", "action")

func finish_skill():
	action_answer = null
	active_skill_bar = false
	get_tree().call_group("skill_bar", "desactive")

func init_shoot_spear():
	if has_spear:
		active_skill_bar = true
		get_tree().call_group("skill_bar", "active")

func shoot_spear():
	if has_spear and loaded and active_skill_bar and action_answer != null:
		get_tree().call_group("spear", "spear_false")
		
		var position_mouse = global_position.distance_to(get_global_mouse_position())
		var angle = atan2(get_global_mouse_position().y - global_position.y, get_global_mouse_position().x - global_position.x)
		var correct = 0
		
		if action_answer == 1: # alvo verde
			correct = 0.2792664417184 - 0.037934649586 * log(position_mouse)
		else:
			correct = 0.27 - 0.037 * log(position_mouse - 15)
			angle = atan2(get_global_mouse_position().y - global_position.y - 25, get_global_mouse_position().x - global_position.x - 25)
			
		var spear_attack = PRE_SPEAR.instance()	
		spear_attack.global_position = $spear_hand.global_position / 2
		spear_attack.rotation = global_rotation
		spear_attack.dir = Vector2(cos(angle - correct), sin(angle - correct))
		spear_attack.target_position = get_global_mouse_position()
		spear_attack.type = "player_attack"
		get_parent().add_child(spear_attack)
		
		finish_skill()
		has_spear = false
		loaded = false
		$reload.start()
		GAME.unload()

func take_spear():
	get_tree().call_group("spear", "spear_true")
	if not has_spear:
#		$anim_sprite.play("take_weapon")
		$take.play()
		has_spear = true
	GAME.reload(loaded, has_spear)

func _on_reload_timeout():
	$reload.stop()
	loaded = true
	GAME.reload(loaded, has_spear)
	
func on_area_hitted():
	$hurt.play(.29)
	life_state += 1
	get_tree().call_group("life_HUD", "change_state", life_state)
	$particles_hit.emitting = true

func on_area_destroid():
	$death.play()
	status = DEAD
	
func skill_action(action):
	self.action_answer = action
	shoot_spear()

func player_self():
	pass