class_name GoboWheel
extends Resource

@export var gobos: Dictionary[int, Texture2D] = {}

func getGobo(index: int) -> Texture2D:
	var sorted_gobos = gobos.keys()
	sorted_gobos.sort()

	for i in range(0, sorted_gobos.size()):
		var gobo_value = sorted_gobos[i]
		if i < sorted_gobos.size() - 1:
			if index >= gobo_value and index < sorted_gobos[i + 1]:
				return gobos[gobo_value]
		else:
			if index >= gobo_value:
				return gobos[gobo_value]

	return null