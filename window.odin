package glfw_window

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"
// import "core:math/linalg/glsl"

WIDTH  	:: 800
HEIGHT 	:: 600
TITLE 	:: "My Window!"
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5
window: glfw.WindowHandle

WindowError :: enum {
	None,
	LoadError,
	LoadWindowError,
}

main :: proc() {
	err := initWindow() 
	if err != .None do return

	defer glfw.Terminate()
	defer glfw.DestroyWindow(window)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	for !glfw.WindowShouldClose(window) {
		processInput()
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

initWindow :: proc() -> WindowError {
	if !bool(glfw.Init()) {
		fmt.eprintln("GLFW has failed to load.")
		return .LoadError
	}
	
	window = glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)

	if window == nil {
		fmt.eprintln("GLFW has failed to load the window.")
		return .LoadWindowError
	}

	glfw.MakeContextCurrent(window)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	return .None
}

processInput :: proc() {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) do glfw.SetWindowShouldClose(window, true)
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
