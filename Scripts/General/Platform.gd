extends PathFollow2D
class_name Platform

export var speed: float = 1
export var vertical_speed: float = 0
export var vertical_teleport_point: float = 512
export var smooth_turn: bool = false
export var smooth_turn_distance: float = 48
export var smooth_point: float
export var can_fall: bool = false
export var move_on_touch: bool = false
export var custom_script: Script

var current_speed: float = 0
var max_offset: float
var tween: SceneTreeTween
#var tween_rotating: SceneTreeTween
var tween_state: int

var velocity: Vector2

var dir: int = 1
var active: bool = false

var falling: bool = false
var y_speed: float = 0
var fall_position: Vector2
var fall_bool: bool = false

var inited_script

func _ready() -> void:
	_ready_mixin()
	
func _ready_mixin() -> void:
	process_priority = -100
	if not move_on_touch:
		active = true
		current_speed = speed
	if smooth_turn:
		var old_offset = offset
		unit_offset = 1.0
		max_offset = offset
		offset = old_offset
		
		if !smooth_point:
			smooth_point = max_offset / 2
	
	if custom_script:
		inited_script = custom_script.new()
		if inited_script.has_method('_ready_mixin'):
			inited_script._ready_mixin(self)
		

func _physics_process(delta) -> void:
	if active:
		movement(delta)
	
	if inited_script and inited_script.has_method('_process_mixin'):
		inited_script._process_mixin(self, delta)

func movement(delta) -> void:
	if !is_nan(current_speed) and !smooth_turn:
		offset += current_speed * Global.get_delta(delta)
	
	if smooth_turn:
		smooth_turn_movement(delta)
	
	if vertical_speed != 0:
		v_offset += vertical_speed * Global.get_delta(delta)
		if (position.y > vertical_teleport_point if vertical_speed > 0 else position.y < vertical_teleport_point):
			v_offset = 0
# warning-ignore:return_value_discarded
	
	if falling:
		y_speed += 0.2 * Global.get_delta(delta)
		if !fall_bool:
			fall_bool = true
			fall_position = position
		fall_position += Vector2(0, y_speed).rotated(rotation) * Global.get_delta(delta)
		position.y = fall_position.y

func smooth_turn_movement(delta) -> void:
	if !tween:
		tween = new_tw()
		tween.tween_property(self, 'offset', offset + smooth_turn_distance, 1.8 / speed).set_ease(Tween.EASE_IN)
		if offset > smooth_point - smooth_turn_distance:
			tween_state = 2
	
	if tween_state == 1:
		offset += current_speed * Global.get_delta(delta)
		if offset > smooth_point - smooth_turn_distance:
			tween = new_tw()
# warning-ignore:return_value_discarded
			tween.tween_property(self, 'offset', smooth_point, 1.8 / speed).set_ease(Tween.EASE_OUT)
# warning-ignore:return_value_discarded
			tween.tween_property(self, 'offset', smooth_point + smooth_turn_distance, 1.8 / speed).set_ease(Tween.EASE_IN)
			tween_state += 1
			
			if rotate:
				rotate = false
				var tween_rotating = new_tw(false)
				tween_rotating.tween_property(self, 'rotation', rotation + deg2rad(90), 1.8 / speed).set_ease(Tween.EASE_IN)
				tween_rotating.tween_property(self, 'rotation', rotation + deg2rad(180), 1.8 / speed).set_ease(Tween.EASE_OUT)
				tween_rotating.tween_callback(self, '_turn_on_rotate')
			
	elif tween_state == 3:
		offset += current_speed * Global.get_delta(delta)
		if offset > max_offset - smooth_turn_distance:
			tween = new_tw()
# warning-ignore:return_value_discarded
			tween.tween_property(self, 'offset', max_offset, 1.8 / speed).set_ease(Tween.EASE_OUT)
# warning-ignore:return_value_discarded
			tween.tween_property(self, 'offset', max_offset + smooth_turn_distance, 1.8 / speed).set_ease(Tween.EASE_IN)
			tween_state += 1
			
			if rotate:
				rotate = false
				var tween_rotating = new_tw(false)
				tween_rotating.tween_property(self, 'rotation', rotation + deg2rad(90), 1.8 / speed).set_ease(Tween.EASE_IN)
				tween_rotating.tween_property(self, 'rotation', rotation + deg2rad(180), 1.8 / speed).set_ease(Tween.EASE_OUT)
				tween_rotating.tween_callback(self, '_turn_on_rotate')
	
				

func new_tw(connect_signal: bool = true) -> SceneTreeTween:
	var tw = create_tween()
	if connect_signal: tw.connect('finished', self, '_on_tween_finish')
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_process_mode(0)
	return tw

func _on_tween_finish() -> void:
	tween_state += 1
	if tween_state == 5:
		tween_state = 1

func _turn_on_rotate() -> void:
	rotate = true
