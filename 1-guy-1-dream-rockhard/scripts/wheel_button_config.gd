extends Resource
class_name WheelButtonConfig

var title: String
var action: Callable
var color: Color = Color(1, 1, 1, 1)
var start_val: float = 0
var start_price: int = 0
var max_lvl: int = 999
func _init(p_title: String, p_action: Callable = func(): pass , p_color: Color = Color(1, 1, 1, 1), p_start_val: float = 0, p_start_price: int = 0, p_max_lvl: int = 999, ) -> void:
    self.title = p_title
    self.action = p_action
    self.color = p_color
    self.start_val = p_start_val
    self.start_price = p_start_price
    self.max_lvl = p_max_lvl