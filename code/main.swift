
struct Resources 
{
	var background : Int = -1
	var character  : Int = -1
}

var resources = Resources()

startup_function = 
{
	print ("I've been called")

	// Add resources here (images/models/etc)
	resources.background = load_texture ("test.png")
	if resources.background == -1 { print ("Couldn't load thing...") }
}


func update (elapsed:Float, input:Input)
{
	if input.up_pressed    { print ("Up!")    }
	if input.down_pressed  { print ("Down!")  }
	if input.left_pressed  { print ("Left!")  }
	if input.right_pressed { print ("Right!") }

	if input.mouse_down { print (input.mouse_x, input.mouse_y) }
}

update_function = update


render_function = 
{
	// Nothing in here yet. 
}


// And away we go.
open_window ()

