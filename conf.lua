config = {}
function love.conf(argC)
	argC.identity = nil																															-- The name of the save directory (string)
	argC.version = "0.9.2"																														-- The LÖVE version this game was made for
	argC.console = true																															-- Windows only

	config.projectVersion = "0.1.0"
	argC.window.title = [[radiosity2D, v]]..config.projectVersion.."; by AntonioModer (twitter.com/AntonioModer); LOVE 2D-framework (love2d.org)"
	argC.window.icon = nil																														-- Filepath to an image to use as the window's icon (string)
	argC.window.width = 800
	argC.window.height = 600
	argC.window.borderless = false																												-- Remove all border visuals from the window
	argC.window.resizable = false																												-- Let the window be user-resizable
	argC.window.minwidth = 1																													-- Minimum window width if the window is resizable
	argC.window.minheight = 1																													-- Minimum window height if the window is resizable
	argC.window.fullscreen = false
	argC.window.fullscreentype = "normal"																										-- "desktop" or "normal"
	argC.window.vsync = false																													-- Enable vertical sync
	argC.window.fsaa = 0																														-- The number of samples to use with multi-sampled antialiasing
	argC.window.display = 1																														-- Index of the monitor to show the window in
    argC.window.highdpi = false           																										-- Enable high-dpi mode for the window on a Retina display (boolean); default = false
    argC.window.srgb = false              																										-- Enable sRGB gamma correction when drawing to the screen (boolean); default = false
    argC.window.x = 1100
    argC.window.y = 300

	argC.modules.audio = true
	argC.modules.event = true
	argC.modules.graphics = true
	argC.modules.image = true
	argC.modules.joystick = true
	argC.modules.keyboard = true
	argC.modules.math = true
	argC.modules.mouse = true
	argC.modules.physics = true
	argC.modules.sound = true
	argC.modules.system = true
	argC.modules.timer = true
	argC.modules.window = true
	
	config.debug = {}
	config.debug.on = false
end
