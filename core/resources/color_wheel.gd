class_name ColorWheel
extends Resource

@export var colors: Dictionary[int, Color] = {
	0: Color(1, 1, 1),
}

func getColor(index: int) -> Color:
	var sorted_colors = colors.keys()
	sorted_colors.sort()

	for i in range(0, sorted_colors.size()):
		var color_value = sorted_colors[i]
		if i < sorted_colors.size() - 1:
			if index >= color_value and index < sorted_colors[i + 1]:
				return colors[color_value]
		else:
			if index >= color_value:
				return colors[color_value]
	
	return Color(1, 1, 1)