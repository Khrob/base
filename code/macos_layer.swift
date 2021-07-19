
import AppKit
import MetalKit

struct Input
{
    var up_pressed:Bool     = false
    var down_pressed:Bool   = false
    var left_pressed:Bool   = false
    var right_pressed:Bool  = false

    var mouse_x:Float       = 0.0
    var mouse_y:Float       = 0.0
    var mouse_old_x:Float   = 0.0
    var mouse_old_y:Float   = 0.0

    var mouse_down:Bool     = false
}



var update_function:((Float, Input) -> ())?
var render_function:(()->())?
var startup_function:(()->())?


func load_texture (_ path:String) -> Int
{
    return -1
}



private class Window_Delegate : NSObject, NSWindowDelegate
{
    func windowWillClose(_ notification: Notification) { running = false }
}

private class App_Delegate: NSObject, NSApplicationDelegate 
{
    func applicationDidFinishLaunching(_ notification: Notification) {}

    func applicationWillTerminate(_ notification: Notification) 
    {
        running = false
    }
}

private class Window : NSWindow
{
    override var canBecomeMain: Bool { get { return true } }

    override func keyDown(with event:NSEvent) 
    {
        print("\(#function) \(event.keyCode)")

        // Hacky way to make sure quitting still works
        if event.modifierFlags.contains(.command) && event.keyCode == 12 
        {
            NSApplication.shared.terminate(nil)
        }

        switch event.keyCode {
            case 126: input.up_pressed    = true
            case 123: input.left_pressed  = true
            case 125: input.down_pressed  = true
            case 124: input.right_pressed = true
            default : break
        }
    }

    override func keyUp(with event:NSEvent) 
    {
        print("\(#function) \(event.keyCode)")

        switch event.keyCode {
            case 126: input.up_pressed    = false
            case 123: input.left_pressed  = false
            case 125: input.down_pressed  = false
            case 124: input.right_pressed = false
            default : break
        }
    }
}

private var running = true
private var t = 0.0
private var input = Input()

func open_window ()
{
    let app = NSApplication.shared
    let app_delegate = App_Delegate()
    app.delegate = app_delegate
    app.setActivationPolicy(.regular)
    app.finishLaunching()

    let frame = NSRect(x:0, y: 0, width: 1024, height: 768)
	let delegate = Window_Delegate()
	let window = Window(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)

    let metal_view = Window_View(frame:frame, device:MTLCreateSystemDefaultDevice())
    metal_view.colorPixelFormat = .bgra8Unorm
    metal_view.depthStencilPixelFormat = .depth32Float
    metal_view.preferredFramesPerSecond = 60
    metal_view.isPaused = false
    metal_view.enableSetNeedsDisplay = false
    
    let renderer = Renderer(device: metal_view.device!)
    metal_view.delegate = renderer
    
    window.delegate = delegate
	window.title = "base"
    window.contentView = metal_view
	window.center()
    window.orderFrontRegardless()
    window.contentView?.updateTrackingAreas()

    app.activate(ignoringOtherApps:true)

    startup_function?()

	while (running)
	{
        var event:NSEvent?
        repeat {
            event = app.nextEvent(matching: .any, until: nil, inMode: .default, dequeue: true)
            
            if event != nil { app.sendEvent(event!) }

        } while(event != nil)

        update_function?(Float(t), input)
	}
}

private class Renderer: NSObject, MTKViewDelegate
{
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var library:MTLLibrary!
    var vertex_shader:MTLFunction!
    var fragment_shader:MTLFunction!
    var pipelineState: MTLRenderPipelineState!
    var last_frame_time:Date = Date()
    var vertex_buffer: MTLBuffer!
    var vertexData:[Float]
    var position_data:[Float]
    var position_buffer: MTLBuffer!

    init (device: MTLDevice)
    {
        self.vertexData = [
             0.0,  1.0, 0.0,
            -0.9, -1.0, 0.0,
             0.9, -1.0, 0.0
        ]

        self.position_data = [0.1, 0.0]

        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()

        let shader = read_file(path:"shaders.metal")

        self.device.makeLibrary(source: shader!, options: nil) { library, error in
            if library == nil { fatalError("Couldn't create metal library: \(String(describing:error))") }
            self.library = library!
            self.init_callback()
        }
    }

    func init_callback ()
    {   
        vertex_shader   = library.makeFunction(name:"vertex_func")
        fragment_shader = library.makeFunction(name:"fragment_func")

        if vertex_shader == nil || fragment_shader == nil { fatalError("Couldn't load all the required shaders.") }

        let pipeline_state_descriptor = MTLRenderPipelineDescriptor()
        pipeline_state_descriptor.vertexFunction = vertex_shader
        pipeline_state_descriptor.fragmentFunction = fragment_shader
        pipeline_state_descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipeline_state_descriptor)

        if pipelineState == nil { fatalError("Couldn't create the pipeline state.") }
        else { print ("Created the pipeline state OK") }

        var data_size = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertex_buffer = device.makeBuffer(bytes: vertexData, length: data_size, options: [])
        if vertex_buffer == nil { fatalError("Couldn't create the vertex buffer") }

        data_size = position_data.count * MemoryLayout.size(ofValue: position_data[0])
        position_buffer = device.makeBuffer(bytes: position_data, length: data_size, options: [])
        if position_buffer == nil { fatalError("Couldn't create the position buffer") }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        print ("\(#function) \(size)")
        (view as! Window_View).updateTrackingAreas()
    }

    func draw(in view: MTKView)
    {
        //  superhacky
        var delta = -last_frame_time.timeIntervalSinceNow
        last_frame_time = Date()
        if delta > 0.1 { delta = 0 }
        t += delta / 2.0
        // /superhacky

        struct Color{ var red, green, blue, alpha: Double }
        let color = Color(red: sin(t), green: 0.75, blue: 1.0, alpha: 1.0)
        view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha)
        
        let render_pass_descriptor:MTLRenderPassDescriptor = view.currentRenderPassDescriptor!

        let command_buffer = commandQueue.makeCommandBuffer()

        let render_encoder:MTLRenderCommandEncoder = (command_buffer?.makeRenderCommandEncoder(descriptor: render_pass_descriptor))!

        render_encoder.setRenderPipelineState(pipelineState)
        render_encoder.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
        render_encoder.setVertexBuffer(position_buffer, offset: 0, index: 1)

        render_encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)

        render_encoder.drawIndexedPrimitives(
            type: .triangleStrip,
            indexCount: 3,
            indexType: .uint16,
            indexBuffer: vertex_buffer,
            indexBufferOffset: 0)

        render_function?()

        render_encoder.endEncoding()

        command_buffer!.present(view.currentDrawable!)
        command_buffer!.commit()
    }
}

class Window_View : MTKView
{
    var tracking_area:NSTrackingArea? = nil

    override func updateTrackingAreas()
    {
        print(#function)
        if tracking_area != nil { removeTrackingArea(tracking_area!) }
        tracking_area = NSTrackingArea(rect: self.bounds, options: [.activeAlways, .mouseMoved] , owner: self, userInfo: nil)
        addTrackingArea(tracking_area!)
    }
    
    override func mouseExited(with event: NSEvent)
    {
        // print(#function)
        super.mouseExited(with: event)
    }
    
    override func mouseEntered(with event: NSEvent)
    {
        // print(#function)
        super.mouseEntered(with: event)
    }
    
    override func mouseMoved(with event: NSEvent)
    {
        // print(#function)
        super.mouseMoved(with: event)
        mouse_event(event)
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        // print(#function)
        super.mouseDragged(with: event)
        mouse_event(event)
    }
    
    override func mouseDown(with event: NSEvent)
    {
        // print(#function)
        super.mouseDown(with: event)
        mouse_event(event)
        input.mouse_down = true
    }
    
    override func mouseUp(with event: NSEvent)
    {
        // print(#function)
        super.mouseUp(with: event)
        mouse_event(event)
        input.mouse_down = false
    }

    func mouse_event (_ event:NSEvent)
    {
        let window_size = event.window!.contentView!.bounds.size
        let point = CGPoint(x: event.locationInWindow.x / window_size.width, y: 1 - event.locationInWindow.y / window_size.height)

        input.mouse_old_x = input.mouse_x
        input.mouse_old_x = input.mouse_y

        input.mouse_x = Float(point.x)
        input.mouse_y = Float(point.y)
    }
}


func read_file (path:String) -> String?
{
    let file = fopen(path, "r")
    defer { fclose(file) }

    fseek(file, 0, SEEK_END)
    let file_size = ftell(file)
    fseek(file, 0, SEEK_SET)

    let pointer = UnsafeMutableRawPointer.allocate(byteCount: file_size, alignment: 1)
    defer { pointer.deallocate() }

    let read_bytes = fread(pointer, 1, file_size, file)
    if read_bytes != file_size { return nil }

    let s = String(cString: pointer.bindMemory(to: Int8.self, capacity: file_size)) 
    return s
}

