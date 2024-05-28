return {
	background_color = { 1, 1, 1, 0.4 },
	font = {
		color = { 1, 1, 1, 1 },
		highlight_color = { 1, 0, 0, 1 },
		size = 16,
		family = "Arial",
		style = "Normal",
		weight = "normal",
        offset = { 5, 15 },
	},
	grid = {
		color = { 1, 1, 1, 1 },
		selected_color = { 1, 0, 0, 1 },
		size = { 80, 80 },
		offset = { 0, 0 },
	},
	keys = {
		search = "asdfghjkl",
		bindings = {
			z = { move_x = -5 },
			x = { move_y = 5 },
			n = { move_y = -5 },
			m = { move_x = 5 },
			Z = { resize_x = -5 },
			X = { resize_y = 5 },
			N = { resize_y = -5 },
			M = { resize_x = 5 },
            w = { move_selection_x = -5 }
            e = { move_selection_y = 5 }
            o = { move_selection_y = -5 }
            p = { move_selection_x = 5 }
			c = "cancel_selection",
			[8] = "remove",
			q = "quit",
		},
	},
}
