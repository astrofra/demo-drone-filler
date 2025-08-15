hg = require("harfang")
require("utils")
require("linear_filter")

math.randomseed(os.time())

function RefreshLoadingWindow(window, display_res_x, display_res_y, progress_value, bg_color)
	bg_color = bg_color or hg.Color.Blue
	hg.SetViewClear(0, hg.CF_Color | hg.CF_Depth, bg_color * hg.Color(progress_value, progress_value, progress_value, 1.0), 1, 0)
	hg.SetViewRect(0, 0, 0, display_res_x, display_res_y)

	hg.Touch(0)  -- force the view to be processed as it would be ignored since nothing is drawn to it (a clear does not count)

	hg.Frame()
	hg.UpdateWindow(window)
end

function main()
	-- Initialize input, audio, and window systems
	hg.InputInit()
	hg.OpenALInit()
	hg.WindowSystemInit()
	hg.HideCursor()

	local res_x, res_y = 1920, 1080 -- default working monitor size
	local monitor_rect = hg.IntRect(0, 0, res_x, res_y)

	-- get the actual monitor size from the window system
	local mon_list = hg.GetMonitors()
	if mon_list:size() >= 1 then
		local _idx
		for _idx = 0, mon_list:size() - 1 do
			local _mon_rect = hg.GetMonitorRect(mon_list:at(_idx))
			res_x = _mon_rect.ex - _mon_rect.sx
			res_y = _mon_rect.ey - _mon_rect.sy
			print("Found monitor size: " .. res_x .. " x " .. res_y)
			break
		end
	end

	-- Set window resolution
	local nominal_res_x, nominal_res_y = 1920, 1080

	local nominal_aspect = nominal_res_x / nominal_res_y
	local actual_aspect = res_x / res_y
	local fov_aspect_ratio_factor = math.max(nominal_aspect / actual_aspect, 1.0)

	local mode_list = {hg.WV_Windowed, hg.WV_Fullscreen, hg.WV_Undecorated, hg.WV_FullscreenMonitor1, hg.WV_FullscreenMonitor2, hg.WV_FullscreenMonitor3}

	-- main screen
	local win = hg.NewWindow("Drone Filler", res_x, res_y, 32, mode_list[3]) --, hg.WV_Fullscreen)
	hg.RenderInit(win) --, hg.RT_OpenGL)
	hg.RenderReset(res_x, res_y, hg.RF_MSAA4X | hg.RF_MaxAnisotropy | hg.RF_VSync)
	local bg_color = hg.Color.Green

	-- Create and configure the pipeline for rendering
	local pipeline = hg.CreateForwardPipeline(4096, false)
	local res = hg.PipelineResources()
	local render_data = hg.SceneForwardPipelineRenderData()

	if IsLinux() then
		hg.AddAssetsFolder("../assets_compiled")
	else
		if file_exists("assets_compiled/project.prj") then
			hg.AddAssetsFolder("assets_compiled")
		elseif file_exists("../assets_compiled/project.prj") then
			hg.AddAssetsFolder("../assets_compiled")
		else
			print("/!\\ Cannot locate the compiled assets!")
		end
	end

	-- hg.AddAssetsFolder("assets_compiled")

	local pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
	local pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Half, hg.BR_Half)
	pipeline_aaa_config.sample_count = 1
    pipeline_aaa_config.exposure = 2.5
    pipeline_aaa_config.gamma = 1.8
    pipeline_aaa_config.z_thickness = 0.5
    pipeline_aaa_config.motion_blur = 0.01
	pipeline_aaa_config.bloom_bias = 0.009999999776482582
	pipeline_aaa_config.bloom_intensity = 0.699999988079071
	pipeline_aaa_config.bloom_threshold = 0.009999999776482582
	pipeline_aaa_config.dof_focus_point = 5.0
	pipeline_aaa_config.dof_focus_length = 50.0

	-- Create an empty main_scene
	local main_scene = hg.Scene()
	-- main_scene.canvas.clear_color = false
	-- main_scene.canvas.color = bg_color -- hg.Color.Red --
	hg.LoadSceneFromAssets("main.scn", main_scene, res, hg.GetForwardPipelineInfo())

	-- Main render loop
	local frame = 0
	local df_filter = LinearFilter:new(120)

	local keyboard = hg.Keyboard('raw')

	-- main loop
	-- Run until the user closes the window or presses the Escape key
	while not keyboard:Pressed(hg.K_Escape) and hg.IsWindowOpen(win) do
		-- df_filter:SetNewValue(hg.time_to_us_f(hg.TickClock()))
		-- local dt = hg.time_from_us_f(df_filter:GetMedianValue())
		-- local dts = hg.time_to_sec_f(dt)
		-- local current_clock = hg.GetClock() -- fixed_clock -- hg.GetClock()
		dt = hg.TickClock()

		keyboard:Update()

		-- Update main_scene
		main_scene:Update(dt)

		-- and submit for rendering
		local views = hg.SceneForwardPipelinePassViewId()
		local view_id = 0
		local passId

		-- bg clear
		hg.SetViewClear(view_id, hg.CF_Color | hg.CF_Depth, bg_color, 0.0, 0)
		hg.SetViewRect(view_id, 0, 0, res_x, res_y)

		-- hg.Touch(view_id)
		view_id = view_id + 1

		-- main scene render
		view_id, passId = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
		view_id = view_id + 1

		frame = hg.Frame()
		hg.UpdateWindow(win)
	end

	-- Cleanup and shutdown operations
	hg.RenderShutdown()
	hg.DestroyWindow(win)
	hg.ShowCursor()
end

main()
