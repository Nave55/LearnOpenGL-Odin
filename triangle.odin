package glfw_window

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"
// import "core:math/linalg/glsl"

WIDTH :: 800
HEIGHT :: 600
TITLE :: "Triangle"
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5
window: glfw.WindowHandle
shaderProgram: u32

WindowError :: enum {
	None,
	LoadError,
	LoadWindowError,
}

main :: proc() {
	err := initWindow() // create window handle
	assert(err == .None) //  assert that there was no error in creating window handle

	defer glfw.Terminate() // terminate glfw
	defer glfw.DestroyWindow(window) // destroy window handle
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback) // for window resize

	program(1) // orange fragment shader
	// program(2) // yellow fragment shader

	// exercise one and base triangle

	// VAO, VBO := createTriangle()
	// VAO, VBO := exerciseOne()
	// defer {
	// 	gl.DeleteVertexArrays(1, &VAO)
	// 	gl.DeleteBuffers(1, &VBO)
	// 	gl.DeleteProgram(shaderProgram)
	// }

	// base rect

	VAO, VBO, EBO := createRect()
	defer {
		gl.DeleteVertexArrays(1, &VAO)
		gl.DeleteBuffers(1, &VBO)
		gl.DeleteBuffers(1, &EBO)
		gl.DeleteProgram(shaderProgram)
	}

	// exercise two

	// VAOs, VBOs := exerciseTwo()
	// defer {
	// 	gl.DeleteVertexArrays(2, raw_data(VAOs[:]))
	// 	gl.DeleteBuffers(2, raw_data(VBOs[:]))
	// 	gl.DeleteProgram(shaderProgram)
	// }


	for !glfw.WindowShouldClose(window) {
		processInput() // check if pressed escape
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		// runProgram(VAO, VBO, "base") // base triangle
		runProgram(VAO, VBO, EBO) // base rect
		// runProgram(VAO, VBO, "one") // exercise one
		// runProgram(VAOs[:], VBOs[:]) // exercise two
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

// creates window
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

// close window if you hit escape
processInput :: proc() {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) do glfw.SetWindowShouldClose(window, true)
}

// call back if window resize
framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

// creates shader program
program :: proc(prog: u8) {
	vertexShader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertexShader, 1, &vertex_shader_source, nil)
	gl.CompileShader(vertexShader)
	checkCompileErrors(vertexShader, "VERTEX")

	fragmentShader: u32
	fragmentShader = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(
		fragmentShader,
		1,
		prog == 1 ? &fragment_shader_source : &fragment_shader_source2,
		nil,
	)
	gl.CompileShader(fragmentShader)
	checkCompileErrors(fragmentShader, "FRAGMENT")

	shaderProgram = gl.CreateProgram()
	gl.AttachShader(shaderProgram, vertexShader)
	gl.AttachShader(shaderProgram, fragmentShader)
	gl.LinkProgram(shaderProgram)
	checkCompileErrors(shaderProgram, "PROGRAM")

	gl.DeleteShader(vertexShader)
	gl.DeleteShader(fragmentShader)
}

// creates triangle
createTriangle :: proc() -> (VBO, VAO: u32) {
	vertices := [9]f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.BindVertexArray(VAO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	return
}

// creates rect
createRect :: proc() -> (VBO, VAO, EBO: u32) {
	vertices := [12]f32{0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0}

	indices := [6]u32{0, 1, 3, 1, 2, 3}

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.GenBuffers(1, &EBO)
	gl.BindVertexArray(VAO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), raw_data(indices[:]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE) // WireFrame mode

	return
}

//excercise part one
exerciseOne :: proc() -> (VBO, VAO: u32) {
	vertices := [18]f32 {
		-0.9,
		-0.5,
		0.0, // left 
		-0.0,
		-0.5,
		0.0, // right
		-0.45,
		0.5,
		0.0, // top 
		// second triangle
		0.0,
		-0.5,
		0.0, // left
		0.9,
		-0.5,
		0.0, // right
		0.45,
		0.5,
		0.0, // top
	}

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.BindVertexArray(VAO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	return
}

// exercise part two
exerciseTwo :: proc() -> (VBOs, VAOs: [2]u32) {
	firstTriangle := [9]f32 {
		-0.9,
		-0.5,
		0.0, // left 
		-0.0,
		-0.5,
		0.0, // right
		-0.45,
		0.5,
		0.0, // top 
	}

	secondTriangle := [9]f32 {
		0.0,
		-0.5,
		0.0, // left
		0.9,
		-0.5,
		0.0, // right
		0.45,
		0.5,
		0.0, // top 
	}

	gl.GenVertexArrays(2, raw_data(VAOs[:]))
	gl.GenBuffers(2, raw_data(VBOs[:]))

	gl.BindVertexArray(VAOs[0])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0])
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(firstTriangle),
		raw_data(firstTriangle[:]),
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	gl.BindVertexArray(VAOs[1])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[1])
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(secondTriangle),
		raw_data(secondTriangle[:]),
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	return
}

// runs program if base triangle or exercise part one
runBaseOne :: proc(VAO, VBO: u32, part: string) {
	if part == "base" {
		gl.UseProgram(shaderProgram)
		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)
	}

	if part == "one" {
		gl.UseProgram(shaderProgram)
		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 6)
	}
}

// runs exercise two 
runExerciseTwo :: proc(VBOs, VAOs: []u32) {
	gl.UseProgram(shaderProgram)
	// draw first triangle using the data from the first VAO
	gl.BindVertexArray(VAOs[0])
	gl.DrawArrays(gl.TRIANGLES, 0, 3)
	// then we draw the second triangle using the data from the second VAO
	gl.BindVertexArray(VAOs[1])
	gl.DrawArrays(gl.TRIANGLES, 0, 3)
}

// runs rect program
runRect :: proc(VAO, VBO, EBO: u32) {
	gl.UseProgram(shaderProgram)
	gl.BindVertexArray(VAO)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)))
}

// overload for all the run functions
runProgram :: proc {
	runBaseOne,
	runExerciseTwo,
	runRect,
}

// checks for compile errors
checkCompileErrors :: proc(obj: u32, type: string) {
	success: i32
	infoLog: [512]byte
	if type == "PROGRAM" {
		gl.GetProgramiv(obj, gl.LINK_STATUS, &success)
		if success == 0 {
			gl.GetProgramInfoLog(obj, 512, nil, raw_data(infoLog[:]))
			fmt.eprintln("ERROR::SHADER::PROGRAM::LINKING_FAILED\n", infoLog)
		}
	} else {
		gl.GetShaderiv(obj, gl.COMPILE_STATUS, &success)
		if success == 0 {
			gl.GetShaderInfoLog(obj, 512, nil, raw_data(infoLog[:]))
			fmt.eprintln("ERROR::SHADER::", type, "::COMPILATION_FAILED\n", infoLog)
		}
	}
}

// vertex shader
vertex_shader_source: cstring = `#version 330 core

    layout (location = 0) in vec3 aPos;

    void main()
    {
       gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    }`


// orange fragment shader
fragment_shader_source: cstring = `#version 330 core

    out vec4 FragColor;

    void main()
    {
       FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    }`


// yellow fragment shader
fragment_shader_source2: cstring = `#version 330 core

    out vec4 FragColor;

    void main()
    {
       FragColor = vec4(1.0f, 0.984f, 0.0f, 1.0f);
    }`
