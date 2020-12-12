CADCam = {}

CADCam.InspectorProperties = {
	{
		name       = "Navgation Style",
		tooltip    = "Switches between different navigation styles",
		uiType     = "enumProperty",
		options    = function() return CADCam.NavStyles.NavTypes end,
		func       = function(v) CADCam.Settings.navStyle = v end,
		value      = function() return CADCam.Settings.navStyle end,
		layout     = {"color",Color(0,0,0,0)},
	},
    {
		name       = "Orthographic",
		tooltip    = "Orthographic view",
		uiType     = "boolProperty",
		value      = function() return CADCam.Settings.orthographic end,
		func       = function(v) CADCam.Settings.orthographic = v BuilderCamera.cam.orthographic = v BuilderCamera.cam2.orthographic = v end,
		layout     = {"color",Color(0,0,0,0)},
  	},
	{
		name       = "Show Pivot",
		tooltip    = "Show pivot point",
		uiType     = "boolProperty",
		value      = function() return CADCam.Settings.showPivot end,
		func       = function(v) CADCam.Settings.showPivot = v end,
		layout     = {"color",Color(0,0,0,0)},
	  },
	  {
		name		= "Near Clip Plane",
		tooltip		= "Adjust camera near clip plane",
		uiType		= "sliderProperty",
		minValue	= 0.006*10,
		maxValue	= 0.10000000149012*10,
		value		= function() return CADCam.Settings.nearClip end,
		func		= function(v) CADCam.Settings.nearClip = v end,
		layout		= {"color",Color(0,0,0,0)},
	  },
}

CADCam.NavStyles = {
	["NavTypes"] = {"Disabled","Inventor","Blender"},
}

CADCam.Settings = {				--DNT = do not touch
	orthographic = false,		--DNT
	showPivot = true,			--DNT
	nearClip = BuilderCamera.cam.nearClipPlane*10, --DNT
	labelPivot = false,			--set to false if you do not want the pivot node labelled
	navStyle = "Inventor",		--change this value to set default cam style (values listed in CADCam.NavStyles above)
	pivotColor = Color(0,1,0,1) --sets pivot color (r,g,b,a)
}

CADCam.Keybinds = {
	setPivRayKey = KeyCode.Mouse3,	--keybind to set pivot to mouse position, doc - (https://docs.unity3d.com/ScriptReference/KeyCode.html)
	setPivSelKey = nil,				--keybind to set pivot to selection
	setPivOrgKey = KeyCode.Mouse4,	--keybind to set pivot to orgin
}

CADCam.Version = "V0.8"

function CADCam:Awake()
	print("CADCAM: awake")
end

function CADCam:Start()
	print("CADCAM: start")
	self:CreateUI()
	if HBBuilder.Builder.currentAssembly.transform then self.origin = HBBuilder.Builder.currentAssembly.transform.position end
	BuilderCamera.cam.orthographic = false
	BuilderCamera.cam2.orthographic = false
	self.lastMousePos = Input.mousePosition
	self.lastProj = Builder.persistantToolContainer.transform:GetChild(0).gameObject:GetComponentInChildren(Text).text
end

function CADCam:CreateUI()
    local backgroundColor = Color(BUI.colors.black.r,BUI.colors.black.g,BUI.colors.black.b,0.7);
    self.wizzard =
        BUI.Wizzard:Create(
            {
                name = "CAD Cam",
                hidable = true,
                hideOnStart = true,
                layout1 = {"min", Vector2(300, (3+#CADCam.InspectorProperties) * 30), "color", backgroundColor},
                layout2 = {}
            },
            Builder.persistantToolContainer
    )
	self.wizzard:SetProperties(self.InspectorProperties)
	
	local prop = self:CreatePivotProperty(
    	self.wizzard.contentParent,
    	"Set Pivot",
    	"Sets view pivot",
    	function() CADCam:SetPivotOrigin() end, 
		function() CADCam:SetPivotSelection() end
  	)
	self.wizzard:AddCustomProperty(prop)
	  
	prop = self:CreateViewProperty1(
    	self.wizzard.contentParent,
    	"Views",
    	"View planes",
		function() CADCam:FrontView() end,
		function() CADCam:LeftView() end,
		function() CADCam:TopView() end
  	)
	self.wizzard:AddCustomProperty(prop)
	  
	prop = self:CreateViewProperty2(
    	self.wizzard.contentParent,
    	"",
    	"View planes",
		function() CADCam:BackView() end,
		function() CADCam:RightView() end,
		function() CADCam:BottomView() end
  	)
  	self.wizzard:AddCustomProperty(prop)
end

function CADCam:CreatePivotProperty(parent,name,tooltip,func1,func2)
	local panel = BUI.Container(parent,"name","GridAlignProperty","min",Vector2(0,30),"tooltip",tooltip)
	BUI.Text(panel,"text",name,"offsetmin",Vector2(10,0),"textalign",TextAnchor.MiddleLeft,"fontsize",12)
	if func1 then BUI.Button(panel,"name","origin","text","origin","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-66,0) ,"size",Vector2(60,20),"onclick",function() func1(); end) end
	if func2 then BUI.Button(panel,"name","select","text","select","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-5,0) ,"size",Vector2(60,20),"onclick",function() func2(); end) end
end

function CADCam:CreateViewProperty1(parent,name,tooltip,func1,func2,func3)
	local panel = BUI.Container(parent,"name","GridAlignProperty","min",Vector2(0,30),"tooltip",tooltip)
	BUI.Text(panel,"text",name,"offsetmin",Vector2(10,0),"textalign",TextAnchor.MiddleLeft,"fontsize",12)
	if func1 then BUI.Button(panel,"name","F","text","F","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-87,0) ,"size",Vector2(40,20),"onclick",function() func1(); end) end
	if func2 then BUI.Button(panel,"name","L","text","L","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-46,0) ,"size",Vector2(40,20),"onclick",function() func2(); end) end
	if func3 then BUI.Button(panel,"name","T","text","T","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-5,0) ,"size",Vector2(40,20),"onclick",function() func3(); end) end
end

function CADCam:CreateViewProperty2(parent,name,tooltip,func1,func2,func3)
	local panel = BUI.Container(parent,"name","GridAlignProperty","min",Vector2(0,30),"tooltip",tooltip)
	BUI.Text(panel,"text",name,"offsetmin",Vector2(10,0),"textalign",TextAnchor.MiddleLeft,"fontsize",12)
	if func1 then BUI.Button(panel,"name","Ba","text","Ba","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-87,0) ,"size",Vector2(40,20),"onclick",function() func1(); end) end
	if func2 then BUI.Button(panel,"name","R","text","R","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-46,0) ,"size",Vector2(40,20),"onclick",function() func2(); end) end
	if func3 then BUI.Button(panel,"name","Bo","text","Bo","anchormin",Vector2(1,0.5),"anchormax",Vector2(1,0.5),"pivot",Vector2(1,0.5),"position",Vector2(-5,0) ,"size",Vector2(40,20),"onclick",function() func3(); end) end
end

function CADCam:FrontView()
	local dist = Vector3.Distance(self.origin, BuilderCamera.camBody.transform.position)
	BuilderCamera.camBody.transform.position = self.origin
	BuilderCamera.camBody.transform.position = Vector3(BuilderCamera.camBody.transform.position.x, BuilderCamera.camBody.transform.position.y, BuilderCamera.camBody.transform.position.z + dist)
	BuilderCamera.camBody.transform:LookAt(self.origin)
end

function CADCam:TopView()
	local dist = Vector3.Distance(self.origin, BuilderCamera.camBody.transform.position)
	BuilderCamera.camBody.transform.position = self.origin
	BuilderCamera.camBody.transform.position = Vector3(BuilderCamera.camBody.transform.position.x, BuilderCamera.camBody.transform.position.y + dist, BuilderCamera.camBody.transform.position.z)
	BuilderCamera.camBody.transform:LookAt(self.origin)
end

function CADCam:LeftView()
	local dist = Vector3.Distance(self.origin, BuilderCamera.camBody.transform.position)
	BuilderCamera.camBody.transform.position = self.origin
	BuilderCamera.camBody.transform.position = Vector3(BuilderCamera.camBody.transform.position.x - dist, BuilderCamera.camBody.transform.position.y, BuilderCamera.camBody.transform.position.z)
	BuilderCamera.camBody.transform:LookAt(self.origin)
end

function CADCam:BackView()
	local dist = Vector3.Distance(self.origin, BuilderCamera.camBody.transform.position)
	BuilderCamera.camBody.transform.position = self.origin
	BuilderCamera.camBody.transform.position = Vector3(BuilderCamera.camBody.transform.position.x, BuilderCamera.camBody.transform.position.y, BuilderCamera.camBody.transform.position.z - dist)
	BuilderCamera.camBody.transform:LookAt(self.origin)
end

function CADCam:BottomView()
	local dist = Vector3.Distance(self.origin, BuilderCamera.camBody.transform.position)
	BuilderCamera.camBody.transform.position = self.origin
	BuilderCamera.camBody.transform.position = Vector3(BuilderCamera.camBody.transform.position.x, BuilderCamera.camBody.transform.position.y - dist, BuilderCamera.camBody.transform.position.z)
	BuilderCamera.camBody.transform:LookAt(self.origin)
end

function CADCam:RightView()
	local dist = Vector3.Distance(self.origin, BuilderCamera.camBody.transform.position)
	BuilderCamera.camBody.transform.position = self.origin
	BuilderCamera.camBody.transform.position = Vector3(BuilderCamera.camBody.transform.position.x + dist, BuilderCamera.camBody.transform.position.y, BuilderCamera.camBody.transform.position.z)
	BuilderCamera.camBody.transform:LookAt(self.origin)
end

function CADCam:Update()
	if HBBuilder.Builder and HBBuilder.Builder.currentAssembly and BuilderCamera and not HBBuilder.Tuner.isOpen and not HBU.InMenu then
		BuilderCamera.cam.nearClipPlane = self.Settings.nearClip/10
		BuilderCamera.cam2.nearClipPlane = self.Settings.nearClip/10

		if BuilderCamera.cam.orthographic then BuilderCamera.cam.farClipPlane = 10000 BuilderCamera.cam2.farClipPlane = 10000
		else BuilderCamera.cam.farClipPlane = 100000 BuilderCamera.cam2.farClipPlane = 100000 end

		if not self.origin or self.lastProj ~= Builder.persistantToolContainer.transform:GetChild(0).gameObject:GetComponentInChildren(Text).text then self:SetPivotOrigin() end

		if self.Keybinds.setPivOrgKey and Input.GetKeyDown(self.Keybinds.setPivOrgKey) then self:SetPivotOrigin()
		elseif self.Keybinds.setPivRayKey and Input.GetKeyDown(self.Keybinds.setPivRayKey) then self:SetPivotRaycast() 
		elseif self.Keybinds.setPivSelKey and Input.GetKeyDown(self.Keybinds.setPivSelKey) then self:SetPivotSelection() end

		if self.Settings.navStyle ~= "Disabled" then
			self.mult = HBBuilder.Builder.grid * 5
			if self.Settings.showPivot and self.origin then self:DrawPivot() end
			if self.Settings.navStyle == "Inventor" then
				self:Inventor()
			elseif self.Settings.navStyle == "Blender" then
				self:Blender()
			end
			self.lastMousePos = Input.mousePosition
		end
		self.lastProj = Builder.persistantToolContainer.transform:GetChild(0).gameObject:GetComponentInChildren(Text).text
	end
end

function CADCam:DrawPivot()
	if self.origin then
		HBBuilder.GGizmo.DrawCircle(self.origin,0.1*self.mult,self.Settings.pivotColor)
		if self.Settings.labelPivot then HBBuilder.GGizmo.DrawText("pivot",self.origin,"   pivot",self.Settings.pivotColor,0.5,22) end
	end
end

function CADCam:SetPivotOrigin()
	if HBBuilder.Builder.currentAssembly and HBBuilder.Builder.currentAssembly.transform then
		self.origin = HBBuilder.Builder.currentAssembly.transform.position 
	end 
end

function CADCam:SetPivotSelection()
	if SelectTool.lastSelectClickObject and SelectTool.lastSelectClickObject.transform then
		if HBBuilder.BuilderUtils.GetGameObjectCoG(SelectTool.lastSelectClickObject) ~= Vector4.zero then
			self.origin = HBBuilder.BuilderUtils.GetGameObjectCoG(SelectTool.lastSelectClickObject)
		else 
			self.origin = SelectTool.lastSelectClickObject.transform.position 
		end 
	end 
end

function CADCam:SetPivotRaycast()
	local ray = HBBuilder.BuilderUtils.MouseRay()
	--GameObject root, Ray ray, int physicsRaycastLayer, out BuilderRaycastHit hit, bool ignoreColliders = false, bool ignoreFrames = false, bool ignoreHulls = false, bool ignoreBounds = true, bool ignoreInactive = true, bool ignoreVerts = false, bool ignoreLines = false, bool ignoreQuads = false, bool ignoreTris = false, float lineRadius = 0.03f, float vertRadius = 0.03f, bool snapBounds = true, float snapBoundsScale = 0.1f
	local ok,hit = HBBuilder.BuilderUtils.BuilderRaycast(HBBuilder.Builder.currentAssembly.gameObject,ray,1<<19,Slua.out,false,true,true,true,true,true,true,true,true,0.03,0.03,true,0.1)
	if ok and hit.overCollider and hit.vertIndex1 and hit.vertIndex2 and hit.vertIndex3 then
		self.origin = hit.point
	end
end

function CADCam:Inventor()
	if Input.GetMouseButton(2) then
		--orbit
		if Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift) then 
			local up = BuilderCamera.camBody.transform.up
			local right = BuilderCamera.camBody.transform.right
			BuilderCamera.camBody.transform:RotateAround(self.origin, up, (Input.mousePosition.x - self.lastMousePos.x)/5)
			BuilderCamera.camBody.transform:RotateAround(self.origin, right, (self.lastMousePos.y - Input.mousePosition.y)/5)
		--pan
		else
			BuilderCamera.camBody.transform.position = BuilderCamera.camBody.transform.position + (BuilderCamera.camBody.transform.right * (self.lastMousePos.x - Input.mousePosition.x))/200 * self.mult
			BuilderCamera.camBody.transform.position = BuilderCamera.camBody.transform.position + (BuilderCamera.camBody.transform.up * (self.lastMousePos.y - Input.mousePosition.y))/200 * self.mult
		end
	end
	--zoom
	if Input.mouseScrollDelta.y ~= 0 then
		if not BuilderCamera.cam.orthographic then
			local ray = Camera.main:ScreenPointToRay(Input.mousePosition)
			BuilderCamera.camBody.transform:Translate(ray.direction * Input.mouseScrollDelta.y/2*self.mult, Space.World)
		else
			BuilderCamera.cam.orthographicSize = Mathf.Clamp(BuilderCamera.cam.orthographicSize + Input.mouseScrollDelta.y/-3, 0.1, 100000)
			BuilderCamera.cam2.orthographicSize = Mathf.Clamp(BuilderCamera.cam2.orthographicSize + Input.mouseScrollDelta.y/-3, 0.1, 100000)
		end
	end
end

function CADCam:Blender()
	if Input.GetMouseButton(2) then
		--pan
		if Input.GetKey(KeyCode.LeftShift) or Input.GetKey(KeyCode.RightShift) then 
			BuilderCamera.camBody.transform.position = BuilderCamera.camBody.transform.position + (BuilderCamera.camBody.transform.right * (self.lastMousePos.x - Input.mousePosition.x))/200 * self.mult
			BuilderCamera.camBody.transform.position = BuilderCamera.camBody.transform.position + (BuilderCamera.camBody.transform.up * (self.lastMousePos.y - Input.mousePosition.y))/200 * self.mult
		--orbit
		else
			local up = Vector3.up
			local right = BuilderCamera.camBody.transform.right right.y = 0
			BuilderCamera.camBody.transform:RotateAround(self.origin, up, (Input.mousePosition.x - self.lastMousePos.x)/5)
			BuilderCamera.camBody.transform:RotateAround(self.origin, right, (self.lastMousePos.y - Input.mousePosition.y)/5)
		end
	end
	--zoom
	if Input.mouseScrollDelta.y ~= 0 then
		if not BuilderCamera.cam.orthographic then
			local ray = Camera.main:ScreenPointToRay(Input.mousePosition)
			BuilderCamera.camBody.transform:Translate(ray.direction * Input.mouseScrollDelta.y/2*self.mult, Space.World)
		else
			BuilderCamera.cam.orthographicSize = Mathf.Clamp(BuilderCamera.cam.orthographicSize + Input.mouseScrollDelta.y/-3, 0.1, 100000)
			BuilderCamera.cam2.orthographicSize = Mathf.Clamp(BuilderCamera.cam2.orthographicSize + Input.mouseScrollDelta.y/-3, 0.1, 100000)
		end
	end
end

function CADCam:OnDestroy()
	print("CADCAM: OnDestroy")
	local cam = GameObject.Find("MainCamera Far"):GetComponent("Camera")
	local cam2 = GameObject.Find("MainCamera Near"):GetComponent("Camera")
	if cam.orthographic then
		cam.orthographicSize = 5
		cam.orthographic = false
		cam.farClipPlane = 100000
		cam.nearClipPlane = 0.10000000149012
		cam2.orthographicSize = 5
		cam2.orthographic = false
		--cam2.farClipPlane = 0.30039998888969
		cam2.nearClipPlane = 0.10000000149012
	end
	GameObject.Destroy(self.obj)
end

return CADCam