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

main :: proc() {
	initWindow()
	defer glfw.Terminate()
	defer glfw.DestroyWindow(window)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	for !glfw.WindowShouldClose(window) do gameLoop()
}

initWindow :: proc() {
	if !bool(glfw.Init()) {
		fmt.eprintln("GLFW has failed to load.")
		return 
	}
	
	window = glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)

	if window == nil {
		fmt.eprintln("GLFW has failed to load the window.")
		return
	}

	glfw.MakeContextCurrent(window)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
}

processInput :: proc() {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) do glfw.SetWindowShouldClose(window, true)
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

drawTriangle :: proc() {

	vertex_shader_source: cstring = `#version 330 core

    layout (location = 0) in vec3 aPos;

    void main()
    {
       gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    }`

	fragment_shader_source: cstring = `#version 330 core

    out vec4 FragColor;

    void main()
    {
       FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    }`

    vertexShader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertexShader, 1, &vertex_shader_source, nil)
    gl.CompileShader(vertexShader)
    checkCompileErrors(vertexShader, "VERTEX")

    fragmentShader := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fragmentShader, 1, &fragment_shader_source, nil)
    gl.CompileShader(fragmentShader)
    checkCompileErrors(fragmentShader, "FRAGMENT")

    shaderProgram := gl.CreateProgram()
    gl.AttachShader(shaderProgram, vertexShader)
    gl.AttachShader(shaderProgram, fragmentShader)
    gl.LinkProgram(shaderProgram)
    checkCompileErrors(shaderProgram, "PROGRAM")

    gl.DeleteShader(vertexShader)
    gl.DeleteShader(fragmentShader)

    vertices := [9]f32{
		-0.5, -0.5, 0.0,
		0.5, -0.5, 0.0,
		0.0, 0.5, 0.0,
    }

    VBO, VAO: u32
    gl.GenVertexArrays(1, &VAO)
    gl.GenBuffers(1, &VBO)
    gl.BindVertexArray(VAO)

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
    gl.EnableVertexAttribArray(0)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    gl.UseProgram(shaderProgram)  // Ensure the shader program is in use
    gl.BindVertexArray(VAO)
    gl.DrawArrays(gl.TRIANGLES, 0, 3)

	defer {
		gl.DeleteVertexArrays(1, &VAO)
		gl.DeleteBuffers(1, &VBO)
		gl.DeleteProgram(shaderProgram)
	}
}

checkCompileErrors :: proc(obj: u32, type: string) {
    success: i32
    infoLog: [1024]byte
    if type == "PROGRAM" {
        gl.GetProgramiv(obj, gl.LINK_STATUS, &success)
        if success == 0 {
            gl.GetProgramInfoLog(obj, 1024, nil, raw_data(infoLog[:]))
            fmt.eprintln("ERROR::SHADER::PROGRAM::LINKING_FAILED\n", infoLog)
        }
    } else {
        gl.GetShaderiv(obj, gl.COMPILE_STATUS, &success)
        if success == 0 {
            gl.GetShaderInfoLog(obj, 1024, nil, raw_data(infoLog[:]))
            fmt.eprintln("ERROR::SHADER::", type, "::COMPILATION_FAILED\n", infoLog)
        }
    }
}

gameLoop :: proc() {
	processInput()
	gl.ClearColor(0.2, 0.3, 0.3, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	drawTriangle()
	glfw.SwapBuffers(window)
	glfw.PollEvents()
}