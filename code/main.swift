

func update (elapsed:Float, input:Input)
{
	if input.up_pressed    { print ("Up!")    }
	if input.down_pressed  { print ("Down!")  }
	if input.left_pressed  { print ("Left!")  }
	if input.right_pressed { print ("Right!") }

	if input.mouse_down { print (input.mouse_x, input.mouse_y) }
}

func render ()
{
	// Nothing in here yet. 
}


// And away we go.
open_window ()

