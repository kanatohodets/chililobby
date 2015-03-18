ReadyCheckWindow = LCS.class{}

function ReadyCheckWindow:init(queue, responseTime, queueWindow)	
	self.queue = queue
	self.responseTime = responseTime
	self.queueWindow = queueWindow
	
	self.startTime = os.clock()
	self.readyCheckTime = math.floor(self.startTime + self.responseTime)
	
    self.sentResponse = false
	self.rejoinQueueOnDispose = false
	
	self:AddBackground()
	
    self.lblReadyCheck = Label:New {
        x = 80,
        y = 60,
        width = 100,
        height = 100,
        caption = "Time to respond: ",
        font = { size = 18 },
        Update = function(...)
            Label.Update(self.lblReadyCheck, ...)
            self.currentTime = os.clock()
            if not self.sentResponse then
                if self.readyCheckTime <= self.currentTime then
					self:SendResponse("timeout")
					self.lblReadyCheck.x = 60
					self.lblReadyCheck:SetCaption("Timeout, leaving queue...")
					WG.Delay(function() self.window:Dispose() end, 3)
                    return
				else
					local diff = math.floor(self.readyCheckTime - self.currentTime)
					self.lblReadyCheck:SetCaption("Are you ready? (" .. tostring(diff) .. "s)")
				end
            end
            self.lblReadyCheck:RequestUpdate()
        end,
    }
	
	self.btnYes = Button:New {
		caption = "YES",
		x = 10,
		y = 125,
		width = 100,
		height = 50,
		OnClick = { function()
			if self.sentResponse then
				return
			end
			self:SendResponse("ready")
			self.lblReadyCheck.x = 60
			self.lblReadyCheck:SetCaption("Waiting for other players...")
		end },
	}
	
	self.btnNo = Button:New {
		caption = "NO",
		right = 10,
		y = 125,
		width = 100,
		height = 50,
		OnClick = { function()
			if self.sentResponse then
				return
			end
			self:SendResponse("notready")
			self.lblReadyCheck.x = 60
			self.lblReadyCheck:SetCaption("Not ready, leaving queue...")
			WG.Delay(function() self.window:Dispose() end, 2)
		end },
	}
	
	local sw, sh = Spring.GetWindowGeometry()
	local w, h = 350, 200
    self.window = Window:New {
        caption = queue.title,
        x = math.floor((sw - w) / 2),
        y = math.floor(math.max(0, (sh) / 2 - h)),
        width = w,
        height = h,
        parent = screen0,
        draggable = false,
        resizable = false,
        children = {
            self.lblReadyCheck,
			self.btnYes,
			self.btnNo,
        },
		OnDispose = { function()
			if self.rejoinQueueOnDispose then
				self.queueWindow:Show()
			else
				self.queueWindow:Dispose()
			end
			self.sentTime = os.clock()
		end },
    }
	
	self.onReadyCheckResult = function(listener, queueId, result)
		if result == "pass" then
			self.lblReadyCheck.x = 60			
			self.lblReadyCheck:SetCaption("Success! Game starting...")
		else
			self.lblReadyCheck.x = 60
			self.lblReadyCheck:SetCaption("Failed! Reentering queue...")
			self.rejoinQueueOnDispose = true
			WG.Delay(function() self.window:Dispose() end, 1)
		end
		self.window:Invalidate()
	end
	
	lobby:AddListener("OnReadyCheckResult", self.onReadyCheckResult)
end

function ReadyCheckWindow:SendResponse(response, noResponseTime)
	noResponseTime = not not noResponseTime
	local responseTime = nil
	if not noResponseTime then
		responseTime = math.floor(self.currentTime - self.startTime)
	end
	self.sentResponse = true	
	lobby:ReadyCheckResponse(self.queue.queueId, response, responseTime)
	
	-- hide buttons
	self.btnYes:Hide()
	self.btnNo:Hide()
end

function ReadyCheckWindow:RemoveListeners()
	lobby:RemoveListener("OnReadyCheckResult", self.onReadyCheckResult)
end

function ReadyCheckWindow:AddBackground()
	self.background = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		parent = screen0,
		Draw = function()
            if not self.sentTime then
                local diff = os.clock() - self.startTime
				diff = math.min(0.1, diff) / 0.1

				gl.PushMatrix()
				gl.Color(0.5, 0.5, 0.5, 0.7 * diff)
				
				gl.BeginEnd(GL.QUADS,
					function()
						local w, h = Spring.GetScreenGeometry()
						
						gl.TexCoord(0, 1)
						gl.Vertex(0, 0)
						
						gl.TexCoord(0, 0)
						gl.Vertex(0, h)
							
						gl.TexCoord(1, 0)
						gl.Vertex(w, h)
						
						gl.TexCoord(1, 1)
						gl.Vertex(w, 0)
					end
				)
				gl.PopMatrix()
			else
				local diff = os.clock() - self.sentTime
				diff = math.min(0.1, diff) / 0.1
				if diff == 1 then
					self.background:Dispose()
				end

				gl.PushMatrix()
				gl.Color(0.5, 0.5, 0.5, 0.7 * (1 - diff))
				
				gl.BeginEnd(GL.QUADS,
					function()
						local w, h = Spring.GetScreenGeometry()
						
						gl.TexCoord(0, 1)
						gl.Vertex(0, 0)
						
						gl.TexCoord(0, 0)
						gl.Vertex(0, h)
							
						gl.TexCoord(1, 0)
						gl.Vertex(w, h)
						
						gl.TexCoord(1, 1)
						gl.Vertex(w, 0)
					end
				)
				gl.PopMatrix()
			end
		end,
	}	
	self.background:SetLayer(1)
end