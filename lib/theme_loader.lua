local mq = require('mq')
local ImGui = require('ImGui')

local LoadTheme = {}

	function LoadTheme.shallowcopy(orig)
		local orig_type = type(orig)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in pairs(orig) do
				copy[orig_key] = orig_value
			end
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
	end

	function LoadTheme.PCallString(str)
		local func, err = load(str)
		if not func then
			print(err)
			return false, err
		end

		return pcall(func)
	end

	function LoadTheme.EvaluateLua(str)
		local runEnv = [[mq = require('mq')
			%s
			]]
		return LoadTheme.PCallString(string.format(runEnv, str))
	end


	---@param theme table
	---@return integer, integer
	function LoadTheme.StartTheme(theme)
		if not theme == type('table') then return 0,0 end

		local themeColorPop = 0
		local themeStylePop = 0

		if theme ~= nil then
			for n, t in pairs(theme) do
				if t.color then
					ImGui.PushStyleColor(ImGuiCol[t.element], t.color.r, t.color.g, t.color.b, t.color.a)
					themeColorPop = themeColorPop + 1
				elseif t.stylevar then
					ImGui.PushStyleVar(ImGuiStyleVar[t.stylevar], t.value)
					themeStylePop = themeStylePop + 1
				else
					if type(t) == 'table' then
						if t['Dynamic_Color'] then
							local ret, colors = LoadTheme.EvaluateLua(t['Dynamic_Color'])
							if ret then
								---@diagnostic disable-next-line: param-type-mismatch
								ImGui.PushStyleColor(ImGuiCol[n], colors)
								themeColorPop = themeColorPop + 1
							end
						elseif t['Dynamic_Var'] then
							local ret, var = LoadTheme.EvaluateLua(t['Dynamic_Var'])
							if ret then
								if type(var) == 'table' then
									---@diagnostic disable-next-line: param-type-mismatch, deprecated
									ImGui.PushStyleVar(ImGuiStyleVar[n], unpack(var))
								else
									---@diagnostic disable-next-line: param-type-mismatch
									ImGui.PushStyleVar(ImGuiStyleVar[n], var)
								end
								themeStylePop = themeStylePop + 1
							end
						elseif n == 'Color' then
							for cID, cData in pairs(t) do
								ImGui.PushStyleColor(cID, ImVec4(cData.Color[1], cData.Color[2], cData.Color[3], cData.Color[4]))
								themeColorPop = themeColorPop + 1
							end
						elseif n == 'Style' then
							for sID, sData in pairs (t) do
								if sData.Size ~= nil then
									ImGui.PushStyleVar(sID, sData.Size)
									themeStylePop = themeStylePop + 1
								elseif sData.X ~= nil then
									ImGui.PushStyleVar(sID, sData.X, sData.Y)
									themeStylePop = themeStylePop + 1
								end
							end
						elseif #t == 4 then
							local colors = LoadTheme.shallowcopy(t)
							for i = 1, 4 do
								if type(colors[i]) == 'string' then
									local ret, color = LoadTheme.EvaluateLua(colors[i])
									if ret then
										colors[i] = color
									end
								end
							end
							---@diagnostic disable-next-line: param-type-mismatch, deprecated
							ImGui.PushStyleColor(ImGuiCol[n], unpack(colors))
							themeColorPop = themeColorPop + 1
						else
							---@diagnostic disable-next-line: param-type-mismatch, deprecated						
							-- printf("Var %s \t unpack %s", n, unpack(t))
							ImGui.PushStyleVar(ImGuiStyleVar[n], unpack(t))
							themeStylePop = themeStylePop + 1
						end
					end
				end
			end
		end

		return themeColorPop, themeStylePop
	end

	---@param themeColorPop integer
	---@param themeStylePop integer
	function LoadTheme.EndTheme(themeColorPop, themeStylePop)
		if themeColorPop > 0 then
			ImGui.PopStyleColor(themeColorPop)
		end
		if themeStylePop > 0 then
			ImGui.PopStyleVar(themeStylePop)
		end
	end

return LoadTheme