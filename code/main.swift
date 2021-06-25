

func update (elapsed:Float, input:Input)
{
	if input.up_pressed { print ("Up!") }
	if input.down_pressed { print ("Down!") }
	if input.left_pressed { print ("Left!") }
	if input.right_pressed { print ("Right!") }
}

func render ()
{
	// Nothing in here yet. 
}

// Set the base callbacks.
update_function = update
render_function = render

// And away we go.
open_window ()




