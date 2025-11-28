extends CharacterBody2D
class_name BaseEnemy

@export var max_hp: float = 100.0 # 最大生命值/冷静值
@export var current_hp: float # 当前生命值/冷静值
@export var move_speed: float = 50.0 # 移动速度 (像素/秒)

var path: Path2D # 敌人需要遵循的路径
var path_progress: float = 0.0 # 敌人在路径上的当前进度

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_hp = max_hp

# 由外部调用（例如 Spawner），为该敌人设置其需要遵循的路径
func set_path(new_path: Path2D):
	path = new_path
	# 可选：将敌人的初始位置设置为路径的起点
	if path and path.curve and path.curve.get_point_count() > 0:
		global_position = path.curve.get_point_position(0)

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if path and path.curve and path.curve.get_point_count() > 0:
		path_progress += move_speed * delta
		var target_position = path.curve.sample_baked(path_progress)
		
		# 计算移动方向
		var direction = (target_position - global_position).normalized()
		
		# 移动敌人
		velocity = direction * move_speed
		move_and_slide()
		
		# TODO: 检查是否到达路径终点
		# path.curve.get_baked_length() 可以获取路径总长度
		# 如果 path_progress >= path.curve.get_baked_length()，则敌人到达终点
