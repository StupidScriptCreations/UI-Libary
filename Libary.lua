local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}

local Library = {
    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,

    SearchText = "",
    Searching = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},

    ToggleKeybind = Enum.KeyCode.RightControl,
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Toggled = false,
    Unloaded = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    NotifySide = "Right",
    ShowCustomCursor = false, -- Changed from true to false
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    NotifyOnError = false,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(125, 85, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),

        Red = Color3.fromRGB(255, 50, 50),
        Dark = Color3.new(0, 0, 0),
        White = Color3.new(1, 1, 1),
    },

    Registry = {},
    DPIRegistry = {},
}

local ObsidianImageManager = {
    Assets = {
        TransparencyTexture = {
            RobloxId = 139785960036434,
            Path = "Obsidian/assets/TransparencyTexture.png",

            Id = nil,
        },

        SaturationMap = {
            RobloxId = 4155801252,
            Path = "Obsidian/assets/SaturationMap.png",

            Id = nil,
        },
    },
}
do
    local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function ObsidianImageManager.GetAsset(AssetName: string)
        if not ObsidianImageManager.Assets[AssetName] then
            return nil
        end

        local AssetData = ObsidianImageManager.Assets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function ObsidianImageManager.DownloadAsset(AssetPath: string)
        if not getcustomasset or not writefile or not isfile then
            return
        end

        RecursiveCreatePath(AssetPath, true)

        if isfile(AssetPath) then
            return
        end

        local URLPath = AssetPath:gsub("Obsidian/", "")
        writefile(AssetPath, game:HttpGet(BaseURL .. URLPath))
    end

    for _, Data in ObsidianImageManager.Assets do
        ObsidianImageManager.DownloadAsset(Data.Path)
    end
end

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.MinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.MinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.MinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    --// UI \\-
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        CornerRadius = 4,
        NotifySide = "Right",
        ShowCustomCursor = false, -- Changed from true to false
        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,
        MobileButtonsSide = "Left",
        UnlockMouseWhileOpen = true,
        Compact = false,
        EnableSidebarResize = false,
        SidebarMinWidth = 180,
        SidebarCompactWidth = 54,
        SidebarCollapseThreshold = 0.5,
        SidebarHighlightCallback = nil,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        Multi = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    --// Addons \\-
    KeyPicker = {
        Text = "KeyPicker",
        Default = "None",
        DefaultModifiers = {},
        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

--// Basic Functions \\--
local function ApplyDPIScale(Dimension, ExtraOffset)
    if typeof(Dimension) == "UDim" then
        return UDim.new(Dimension.Scale, Dimension.Offset * Library.DPIScale)
    end

    if ExtraOffset then
        return UDim2.new(
            Dimension.X.Scale,
            (Dimension.X.Offset * Library.DPIScale) + (ExtraOffset[1] * Library.DPIScale),
            Dimension.Y.Scale,
            (Dimension.Y.Offset * Library.DPIScale) + (ExtraOffset[2] * Library.DPIScale)
        )
    end

    return UDim2.new(
        Dimension.X.Scale,
        Dimension.X.Offset * Library.DPIScale,
        Dimension.Y.Scale,
        Dimension.Y.Offset * Library.DPIScale
    )
end
local function ApplyTextScale(TextSize)
    return TextSize * Library.DPIScale
end

local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in pairs(Table) do
        Size += 1
    end

    return Size
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end
local function GetLighterColor(Color)
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:UpdateKeybindFrame()
    if not Library.KeybindFrame then
        return
    end

    local XSize = 0
    for _, KeybindToggle in pairs(Library.KeybindToggles) do
        if not KeybindToggle.Holder.Visible then
            continue
        end

        local FullSize = KeybindToggle.Label.Size.X.Offset + KeybindToggle.Label.Position.X.Offset
        if FullSize > XSize then
            XSize = FullSize
        end
    end

    Library.KeybindFrame.Size = UDim2.fromOffset(XSize + 18 * Library.DPIScale, 0)
end
function Library:UpdateDependencyBoxes()
    for _, Depbox in pairs(Library.DependencyBoxes) do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in pairs(Box.Elements) do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            --// Check if any of the Buttons Name matches with Search
            local Visible = false

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        --// Check if Search matches Element's Name and if Element is Visible
        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search)
    end

    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in pairs(Box.Elements) do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    --// Reset Elements Visibility in Last Tab Searched
    if Library.LastSearchTab then
        for _, Groupbox in pairs(Library.LastSearchTab.Groupboxes) do
            for _, ElementInfo in pairs(Groupbox.Elements) do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            Groupbox:Resize()
            Groupbox.Holder.Visible = true
        end

        for _, Tabbox in pairs(Library.LastSearchTab.Tabboxes) do
            for _, Tab in pairs(Tabbox.Tabs) do
                for _, ElementInfo in pairs(Tab.Elements) do
                    ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible
                        or true

                    if ElementInfo.SubButton then
                        ElementInfo.Base.Visible = ElementInfo.Visible
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end

                for _, Depbox in pairs(Tab.DependencyBoxes) do
                    if not Depbox.Visible then
                        continue
                    end

                    RestoreDepbox(Depbox)
                end

                Tab.ButtonHolder.Visible = true
            end

            Tabbox.ActiveTab:Resize()
            Tabbox.Holder.Visible = true
        end

        for _, DepGroupbox in pairs(Library.LastSearchTab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            DepGroupbox:Resize()
            DepGroupbox.Holder.Visible = true
        end
    end

    --// Cancel Search if Search Text is empty
    local Search = SearchText:lower()
    if Trim(Search) == "" or Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    --// Loop through Groupboxes to get Elements Info
    for _, Groupbox in pairs(Library.ActiveTab.Groupboxes) do
        local VisibleElements = 0

        for _, ElementInfo in pairs(Groupbox.Elements) do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end
                if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end
                ElementInfo.Holder.Visible = Visible
                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in pairs(Groupbox.DependencyBoxes) do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search)
        end

        --// Update Groupbox Size and Visibility if found any element
        if VisibleElements > 0 then
            Groupbox:Resize()
        end
        Groupbox.Holder.Visible = VisibleElements > 0
    end

    for _, Tabbox in pairs(Library.ActiveTab.Tabboxes) do
        local VisibleTabs = 0
        local VisibleElements = {}

        for _, Tab in pairs(Tabbox.Tabs) do
            VisibleElements[Tab] = 0

            for _, ElementInfo in pairs(Tab.Elements) do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements[Tab] += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements[Tab] += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in pairs(Tab.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements[Tab] += CheckDepbox(Depbox, Search)
            end
        end

        for Tab, Visible in pairs(VisibleElements) do
            Tab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1

                if Tabbox.ActiveTab == Tab then
                    Tab:Resize()
                elseif VisibleElements[Tabbox.ActiveTab] == 0 then
                    Tab:Show()
                end
            end
        end

        --// Update Tabbox Visibility if any visible
        Tabbox.Holder.Visible = VisibleTabs > 0
    end

    for _, DepGroupbox in pairs(Library.ActiveTab.DependencyGroupboxes) do
        if not DepGroupbox.Visible then
            continue
        end

        local VisibleElements = 0

        for _, ElementInfo in pairs(DepGroupbox.Elements) do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end
                if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end
                ElementInfo.Holder.Visible = Visible
                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search)
        end

        --// Update Groupbox Size and Visibility if found any element
        if VisibleElements > 0 then
            DepGroupbox:Resize()
        end
        DepGroupbox.Holder.Visible = VisibleElements > 0
    end

    --// Set Last Tab to Current One
    Library.LastSearchTab = Library.ActiveTab
end

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in pairs(Library.Registry) do
        for Property, ColorIdx in pairs(Properties) do
            if typeof(ColorIdx) == "string" then
                Instance[Property] = Library.Scheme[ColorIdx]
            elseif typeof(ColorIdx) == "function" then
                Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:UpdateDPI(Instance, Properties)
    if not Library.DPIRegistry[Instance] then
        return
    end

    for Property, Value in pairs(Properties) do
        Library.DPIRegistry[Instance][Property] = Value and Value or nil
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize *= Library.DPIScale

    for Instance, Properties in pairs(Library.DPIRegistry) do
        for Property, Value in pairs(Properties) do
            if Property == "DPIExclude" or Property == "DPIOffset" then
                continue
            elseif Property == "TextSize" then
                Instance[Property] = ApplyTextScale(Value)
            else
                Instance[Property] = ApplyDPIScale(Value, Properties["DPIOffset"][Property])
            end
        end
    end

    for _, Tab in pairs(Library.Tabs) do
        if Tab.IsKeyTab then
            continue
        end

        Tab:Resize(true)
        for _, Groupbox in pairs(Tab.Groupboxes) do
            Groupbox:Resize()
        end
        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                SubTab:Resize()
            end
        end
    end

    for _, Option in pairs(Options) do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        elseif Option.Type == "KeyPicker" then
            Option:Update()
        end
    end

    Library:UpdateKeybindFrame()
    for _, Notification in pairs(Library.Notifications) do
        Notification:Resize()
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection)
    table.insert(Library.Signals, Connection)
    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string"
        and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons, Icons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)

function Library:GetIcon(IconName: string)
    if not FetchIcons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end
    return Icon
end

function Library:GetCustomIcon(IconName: string)
    if not IsValidCustomIcon(IconName) then
        return Library:GetIcon(IconName)
    else
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in pairs(Template) do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}
    local DPIProperties = Library.DPIRegistry[Instance] or {}

    local DPIExclude = DPIProperties["DPIExclude"] or Table["DPIExclude"] or {}
    local DPIOffset = DPIProperties["DPIOffset"] or Table["DPIOffset"] or {}

    for k, v in pairs(Table) do
        if k == "DPIExclude" or k == "DPIOffset" then
            continue
        elseif ThemeProperties[k] then
            ThemeProperties[k] = nil
        elseif k ~= "Text" and (Library.Scheme[v] or typeof(v) == "function") then
            -- me when Red in dropdowns break things (temp fix - or perm idk if deivid will do something about this)
            ThemeProperties[k] = v
            Instance[k] = Library.Scheme[v] or v()
            continue
        end

        if not DPIExclude[k] then
            if k == "Position" or k == "Size" or k:match("Padding") then
                DPIProperties[k] = v
                v = ApplyDPIScale(v, DPIOffset[k])
            elseif k == "TextSize" then
                DPIProperties[k] = v
                v = ApplyTextScale(v)
            end
        end

        Instance[k] = v
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
    if GetTableSize(DPIProperties) > 0 then
        DPIProperties["DPIExclude"] = DPIExclude
        DPIProperties["DPIOffset"] = DPIOffset
        Library.DPIRegistry[Instance] = DPIProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

--// Main Instances \\-
local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local ScreenGui = New("ScreenGui", {
    Name = "Obsidian",
    DisplayOrder = 999,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui
ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
    Library.DPIRegistry[Instance] = nil
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

--// Notification
local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        Parent = ScreenGui,
    })
    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        Parent = NotificationArea,
    })
end

--// Lib Functions \\--
function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or 1,
        Parent = Frame,
    })

    return Line
end

function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    local Holder = New("Frame", {
        BackgroundColor3 = "Dark",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder
end

function Library:AddDraggableButton(Text: string, Func)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
        },
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Button,
    })
    Library:MakeOutline(Button, Library.CornerRadius, 9)

    Table.Button = Button
    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    function Table:SetText(NewText: string)
        local X, Y = Library:GetTextBounds(NewText, Library.Scheme.Font, 16)

        Button.Text = NewText
        Button.Size = UDim2.fromOffset(X * Library.DPIScale * 2, Y * Library.DPIScale * 2)
        Library:UpdateDPI(Button, {
            Size = UDim2.fromOffset(X * 2, Y * 2),
        })
    end
    Table:SetText(Text)

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local Background = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    Background.AutomaticSize = Enum.AutomaticSize.Y
    Background.Position = UDim2.fromOffset(6, 6)
    Background.Size = UDim2.fromOffset(0, 0)
    Library:UpdateDPI(Background, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = Background,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })
    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 7),
        Parent = Container,
    })

    Library:MakeDraggable(Background, Label, true)
    return Background, Container
end

--// Watermark \\--
do
    local WatermarkBackground = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    WatermarkBackground.AutomaticSize = Enum.AutomaticSize.Y
    WatermarkBackground.Position = UDim2.fromOffset(6, 6)
    WatermarkBackground.Size = UDim2.fromOffset(0, 0)
    WatermarkBackground.Visible = false

    Library:UpdateDPI(WatermarkBackground, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = WatermarkBackground,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })

    local WatermarkLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.fromOffset(0, -8 * Library.DPIScale + 7),
        Text = "",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = WatermarkLabel,
    })

    Library:MakeDraggable(WatermarkBackground, WatermarkLabel, true)

    local function ResizeWatermark()
        local X, Y = Library:GetTextBounds(WatermarkLabel.Text, Library.Scheme.Font, 15)
        WatermarkBackground.Size = UDim2.fromOffset((12 + X + 12 + 4) * Library.DPIScale, Y * Library.DPIScale * 2 + 4)
        Library:UpdateDPI(WatermarkBackground, {
            Size = UDim2.fromOffset(12 + X + 12 + 4, Y * 2 + 4),
        })
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        WatermarkBackground.Visible = Visible
        if Visible then
            ResizeWatermark()
        end
    end

    function Library:SetWatermark(Text: string)
        WatermarkLabel.Text = Text
        ResizeWatermark()
    end
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?
)
    local Menu
    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    end

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Menu,
    })

    local function CloseMenu()
        if CurrentMenu == Menu then
            CurrentMenu = nil
        end

        Menu.Visible = false
        if ActiveCallback then
            Library:SafeCallback(ActiveCallback, false)
        end
    end

    local function OpenMenu()
        if CurrentMenu and CurrentMenu ~= Menu then
            CurrentMenu.Visible = false
        end

        CurrentMenu = Menu
        Menu.Visible = true

        local OffsetX, OffsetY
        if typeof(Offset) == "function" then
            OffsetX, OffsetY = Offset()
        else
            OffsetX, OffsetY = Offset[1], Offset[2]
        end

        local MousePos = UserInputService:GetMouseLocation()
        local ScreenSize = workspace.CurrentCamera.ViewportSize

        local MenuSize = Menu.AbsoluteSize
        local X = math.clamp(MousePos.X + OffsetX, 0, ScreenSize.X - MenuSize.X)
        local Y = math.clamp(MousePos.Y + OffsetY, 0, ScreenSize.Y - MenuSize.Y)

        Menu.Position = UDim2.fromOffset(X, Y)

        if ActiveCallback then
            Library:SafeCallback(ActiveCallback, true)
        end
    end

    Holder.MouseButton1Down:Connect(function()
        OpenMenu()
    end)

    UserInputService.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not Menu.Visible then
                return
            end

            local MousePos = UserInputService:GetMouseLocation()
            local AbsPos, AbsSize = Menu.AbsolutePosition, Menu.AbsoluteSize

            if
                MousePos.X < AbsPos.X
                or MousePos.X > AbsPos.X + AbsSize.X
                or MousePos.Y < AbsPos.Y
                or MousePos.Y > AbsPos.Y + AbsSize.Y
            then
                CloseMenu()
            end
        end
    end)

    return Menu, CloseMenu, OpenMenu
end

--// Window \\--
function Library:CreateWindow(Config: { [string]: any })
    Config = Library:Validate(Config, Templates.Window)

    local Window = {}
    Window.Tabs = {}
    Window.Groupboxes = {}
    Window.Tabboxes = {}
    Window.DependencyGroupboxes = {}

    --// Main \\--
    local Background = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    Background.Position = Config.Position
    Background.Size = Config.Size
    Library:UpdateDPI(Background, {
        Position = Config.Position,
        Size = Config.Size,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = Background,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })

    --// Topbar \\--
    local Topbar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(1, 0, 0, 34),
        Parent = Holder,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Topbar,
    })

    local TopbarCover = Library:MakeCover(Topbar, "Bottom")
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = TopbarCover,
    })

    local TitleIcon
    if Config.Icon then
        TitleIcon = New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = Config.IconSize,
            Image = Config.Icon,
            Parent = Topbar,
        })
    end

    local Title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(TitleIcon and 48 or 12, 0),
        Size = UDim2.new(1, -(TitleIcon and 48 or 12), 1, 0),
        Text = Config.Title,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Topbar,
    })

    local CloseButton = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Text = "×",
        TextSize = 20,
        Parent = Topbar,
    })

    --// Content \\--
    local Content = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 1, -34),
        Parent = Holder,
    })

    --// Sidebar \\--
    local Sidebar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0, 180, 1, 0),
        Parent = Content,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Sidebar,
    })

    local SidebarCover = Library:MakeCover(Sidebar, "Right")
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = SidebarCover,
    })

    local SidebarPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 6),
        Parent = Sidebar,
    })

    local SidebarContainer = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        Parent = Sidebar,
    })

    local SidebarList = New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SidebarContainer,
    })

    --// Tab Holder \\--
    local TabHolder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.new(0, 180, 0, 0),
        Size = UDim2.new(1, -180, 1, 0),
        Parent = Content,
    })

    local TabPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 6),
        Parent = TabHolder,
    })

    local TabContainer = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        Parent = TabHolder,
    })

    local TabList = New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabContainer,
    })

    --// Footer \\--
    local Footer = New("Frame", {
        BackgroundColor3 = "MainColor",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 24),
        Parent = Holder,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Footer,
    })

    local FooterCover = Library:MakeCover(Footer, "Top")
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = FooterCover,
    })

    local FooterLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = Config.Footer,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Footer,
    })

    --// Functions \\--
    function Window:Toggle(Force: boolean?)
        Library.Toggled = Force ~= nil and Force or not Library.Toggled
        Background.Visible = Library.Toggled

        if Library.Toggled then
            if Config.UnlockMouseWhileOpen then
                UserInputService.MouseIconEnabled = true
            end
        else
            if Config.UnlockMouseWhileOpen then
                UserInputService.MouseIconEnabled = true
            end
        end
    end

    function Window:Show()
        Window:Toggle(true)
    end

    function Window:Hide()
        Window:Toggle(false)
    end

    function Window:Center()
        local ScreenSize = workspace.CurrentCamera.ViewportSize
        Background.Position = UDim2.fromOffset(
            (ScreenSize.X - Background.AbsoluteSize.X) / 2,
            (ScreenSize.Y - Background.AbsoluteSize.Y) / 2
        )
    end

    function Window:Resize()
        local SidebarSize = Sidebar.AbsoluteSize
        local TabHolderSize = TabHolder.AbsoluteSize

        local TabHeight = 0
        for _, Tab in pairs(Window.Tabs) do
            if Tab.IsKeyTab then
                continue
            end

            TabHeight += Tab.Holder.AbsoluteSize.Y + 6
        end

        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabHeight)
        SidebarContainer.CanvasSize = UDim2.new(0, 0, 0, #Window.Tabs * 30 + (#Window.Tabs - 1) * 6)
    end

    function Window:SelectTab(Tab: any)
        if Library.ActiveTab == Tab then
            return
        end

        if Library.ActiveTab then
            Library.ActiveTab.Button.BackgroundColor3 = Library.Scheme.MainColor
            Library.ActiveTab.Holder.Visible = false
        end

        Library.ActiveTab = Tab
        Library.ActiveTab.Button.BackgroundColor3 = Library.Scheme.AccentColor
        Library.ActiveTab.Holder.Visible = true

        Window:Resize()
    end

    function Window:CreateTab(Config: { [string]: any })
        local Tab = {}
        Tab.Groupboxes = {}
        Tab.Tabboxes = {}
        Tab.DependencyGroupboxes = {}

        local TabButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.new(1, 0, 0, 30),
            Text = Config.Text or "Tab",
            TextSize = 14,
            Parent = SidebarContainer,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius - 1),
            Parent = TabButton,
        })

        local TabHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            Parent = TabContainer,
        })

        Tab.Button = TabButton
        Tab.Holder = TabHolder
        Tab.IsKeyTab = Config.IsKeyTab or false

        function Tab:CreateGroupbox(Config: { [string]: any })
            Config = Library:Validate(Config, {
                Text = "Groupbox",
                Side = "Left",
            })

            local Groupbox = {}
            Groupbox.Elements = {}
            Groupbox.DependencyBoxes = {}

            local GroupboxHolder = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.new(0.5, -3, 1, 0),
                Parent = TabHolder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                Parent = GroupboxHolder,
            })

            if Config.Side == "Right" then
                GroupboxHolder.Position = UDim2.new(0.5, 3, 0, 0)
            end

            local GroupboxPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 6),
                Parent = GroupboxHolder,
            })

            local GroupboxTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Text = Config.Text,
                TextSize = 14,
                Parent = GroupboxHolder,
            })

            local GroupboxContent = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 20),
                Size = UDim2.new(1, 0, 1, -20),
                Parent = GroupboxHolder,
            })

            local GroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = GroupboxContent,
            })

            function Groupbox:AddLabel(Config: { [string]: any })
                Config = Library:Validate(Config, {
                    Text = "Label",
                    Visible = true,
                })

                local Label = {}
                Label.Type = "Label"

                local LabelHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = GroupboxContent,
                })

                local LabelText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    Parent = LabelHolder,
                })

                Label.Holder = LabelHolder
                Label.Text = Config.Text
                Label.Visible = Config.Visible

                table.insert(Labels, Label)
                table.insert(Groupbox.Elements, Label)

                function Label:SetText(Text: string)
                    Label.Text = Text
                    LabelText.Text = Text
                end

                function Label:SetVisible(Visible: boolean)
                    Label.Visible = Visible
                    LabelHolder.Visible = Visible
                end

                return Label
            end

            function Groupbox:AddButton(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Button)

                local Button = {}
                Button.Type = "Button"

                local ButtonHolder = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 28),
                    Text = "",
                    Parent = GroupboxContent,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ButtonHolder,
                })

                local ButtonText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    Parent = ButtonHolder,
                })

                Button.Holder = ButtonHolder
                Button.Text = Config.Text
                Button.Visible = Config.Visible

                table.insert(Buttons, Button)
                table.insert(Groupbox.Elements, Button)

                ButtonHolder.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Config.Callback, Button)
                end)

                function Button:SetText(Text: string)
                    Button.Text = Text
                    ButtonText.Text = Text
                end

                function Button:SetVisible(Visible: boolean)
                    Button.Visible = Visible
                    ButtonHolder.Visible = Visible
                end

                return Button
            end

            function Groupbox:AddToggle(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Toggle)

                local Toggle = {}
                Toggle.Type = "Toggle"
                Toggle.Value = Config.Default

                local ToggleHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = GroupboxContent,
                })

                local ToggleButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ToggleHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ToggleButton,
                })

                local ToggleText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(28, 0),
                    Size = UDim2.new(1, -28, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleButton,
                })

                local ToggleOuter = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(8, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = ToggleButton,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = ToggleOuter,
                })

                local ToggleInner = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "AccentColor",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Visible = Toggle.Value,
                    Parent = ToggleOuter,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ToggleInner,
                })

                Toggle.Holder = ToggleHolder
                Toggle.Text = Config.Text
                Toggle.Visible = Config.Visible

                table.insert(Toggles, Toggle)
                table.insert(Groupbox.Elements, Toggle)

                function Toggle:SetValue(Value: boolean, Callback: boolean?)
                    if Toggle.Value == Value then
                        return
                    end

                    Toggle.Value = Value
                    ToggleInner.Visible = Value

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, Toggle)
                    end
                    Library:SafeCallback(Config.Changed, Value, Toggle)
                end

                function Toggle:GetValue()
                    return Toggle.Value
                end

                function Toggle:SetText(Text: string)
                    Toggle.Text = Text
                    ToggleText.Text = Text
                end

                function Toggle:SetVisible(Visible: boolean)
                    Toggle.Visible = Visible
                    ToggleHolder.Visible = Visible
                end

                ToggleButton.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value, true)
                end)

                return Toggle
            end

            function Groupbox:AddSlider(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Slider)

                local Slider = {}
                Slider.Type = "Slider"
                Slider.Value = Config.Default

                local SliderHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = GroupboxContent,
                })

                local SliderText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = Config.Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix,
                    TextSize = 14,
                    Parent = SliderHolder,
                })

                local SliderBar = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 50),
                    Size = UDim2.new(1, 0, 0, 4),
                    Parent = SliderHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 2),
                    Parent = SliderBar,
                })

                local SliderFill = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    Size = UDim2.fromScale((Slider.Value - Config.Min) / (Config.Max - Config.Min), 1),
                    Parent = SliderBar,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 2),
                    Parent = SliderFill,
                })

                local SliderButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = SliderHolder,
                })

                Slider.Holder = SliderHolder
                Slider.Text = Config.Text
                Slider.Visible = Config.Visible

                table.insert(Options, Slider)
                table.insert(Groupbox.Elements, Slider)

                function Slider:SetValue(Value: number, Callback: boolean?)
                    Value = math.clamp(Value, Config.Min, Config.Max)
                    if Slider.Value == Value then
                        return
                    end

                    Slider.Value = Value
                    SliderFill.Size = UDim2.fromScale((Value - Config.Min) / (Config.Max - Config.Min), 1)
                    SliderText.Text = Config.Text .. ": " .. Config.Suffix .. Round(Value, Config.Rounding) .. Config.Suffix

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, Slider)
                    end
                    Library:SafeCallback(Config.Changed, Value, Slider)
                end

                function Slider:GetValue()
                    return Slider.Value
                end

                function Slider:SetText(Text: string)
                    Slider.Text = Text
                    SliderText.Text = Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix
                end

                function Slider:SetVisible(Visible: boolean)
                    Slider.Visible = Visible
                    SliderHolder.Visible = Visible
                end

                local Dragging = false
                SliderButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        Dragging = true
                    end
                end)

                UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = SliderBar.AbsolutePosition
                        local BarSize = SliderBar.AbsoluteSize

                        local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                        local Value = Config.Min + (Config.Max - Config.Min) * Percent

                        Slider:SetValue(Round(Value, Config.Rounding), true)
                    end
                end)

                return Slider
            end

            function Groupbox:AddTextbox(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Input)

                local Textbox = {}
                Textbox.Type = "Textbox"
                Textbox.Value = Config.Default

                local TextboxHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = GroupboxContent,
                })

                local TextboxText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = Config.Text,
                    TextSize = 14,
                    Parent = TextboxHolder,
                })

                local TextboxBox = New("TextBox", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, 24),
                    Text = Config.Default,
                    PlaceholderText = Config.Placeholder,
                    Parent = TextboxHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = TextboxBox,
                })

                Textbox.Holder = TextboxHolder
                Textbox.Text = Config.Text
                Textbox.Visible = Config.Visible

                table.insert(Options, Textbox)
                table.insert(Groupbox.Elements, Textbox)

                function Textbox:SetValue(Value: string, Callback: boolean?)
                    if Textbox.Value == Value then
                        return
                    end

                    Textbox.Value = Value
                    TextboxBox.Text = Value

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, Textbox)
                    end
                    Library:SafeCallback(Config.Changed, Value, Textbox)
                end

                function Textbox:GetValue()
                    return Textbox.Value
                end

                function Textbox:SetText(Text: string)
                    Textbox.Text = Text
                    TextboxText.Text = Text
                end

                function Textbox:SetVisible(Visible: boolean)
                    Textbox.Visible = Visible
                    TextboxHolder.Visible = Visible
                end

                TextboxBox.FocusLost:Connect(function(EnterPressed)
                    if Config.Numeric then
                        local Value = tonumber(TextboxBox.Text)
                        if Value then
                            Textbox:SetValue(tostring(Value), true)
                        else
                            TextboxBox.Text = Textbox.Value
                        end
                    else
                        Textbox:SetValue(TextboxBox.Text, true)
                    end
                end)

                return Textbox
            end

            function Groupbox:AddDropdown(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Dropdown)

                local Dropdown = {}
                Dropdown.Type = "Dropdown"
                Dropdown.Value = Config.Multi and {} or Config.Values[1]
                Dropdown.Open = false

                local DropdownHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = GroupboxContent,
                })

                local DropdownButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    Parent = DropdownHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = DropdownButton,
                })

                local DropdownText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -24, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = DropdownButton,
                })

                local DropdownArrow = New("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    Image = Library:GetIcon("chevron-down").Url,
                    Parent = DropdownButton,
                })

                local DropdownList = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromOffset(0, 30),
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ZIndex = 10,
                    Parent = DropdownHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = DropdownList,
                })

                local DropdownPadding = New("UIPadding", {
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    PaddingTop = UDim.new(0, 4),
                    Parent = DropdownList,
                })

                local DropdownContainer = New("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 0,
                    Parent = DropdownList,
                })

                local DropdownListLayout = New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = DropdownContainer,
                })

                Dropdown.Holder = DropdownHolder
                Dropdown.Text = Config.Text
                Dropdown.Visible = Config.Visible

                table.insert(Options, Dropdown)
                table.insert(Groupbox.Elements, Dropdown)

                function Dropdown:RecalculateListSize()
                    local ListSize = 0
                    for _, Option in pairs(DropdownContainer:GetChildren()) do
                        if Option:IsA("TextButton") then
                            ListSize += Option.AbsoluteSize.Y + 2
                        end
                    end

                    DropdownList.Size = UDim2.new(1, 0, 0, math.min(ListSize, Config.MaxVisibleDropdownItems * 24))
                    DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, ListSize)
                end

                function Dropdown:SetValue(Value: any, Callback: boolean?)
                    if Config.Multi then
                        if type(Value) ~= "table" then
                            return
                        end

                        local NewValue = {}
                        for _, V in pairs(Value) do
                            if table.find(Config.Values, V) then
                                table.insert(NewValue, V)
                            end
                        end

                        if #NewValue == #Dropdown.Value then
                            local Same = true
                            for _, V in pairs(NewValue) do
                                if not table.find(Dropdown.Value, V) then
                                    Same = false
                                    break
                                end
                            end

                            if Same then
                                return
                            end
                        end

                        Dropdown.Value = NewValue
                        DropdownText.Text = #NewValue > 0 and table.concat(NewValue, ", ") or Config.Text

                        if Callback then
                            Library:SafeCallback(Config.Callback, NewValue, Dropdown)
                        end
                        Library:SafeCallback(Config.Changed, NewValue, Dropdown)
                    else
                        if not table.find(Config.Values, Value) then
                            return
                        end

                        if Dropdown.Value == Value then
                            return
                        end

                        Dropdown.Value = Value
                        DropdownText.Text = Value

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Dropdown)
                        end
                        Library:SafeCallback(Config.Changed, Value, Dropdown)
                    end
                end

                function Dropdown:GetValue()
                    return Dropdown.Value
                end

                function Dropdown:SetText(Text: string)
                    Dropdown.Text = Text
                    if not Config.Multi or #Dropdown.Value == 0 then
                        DropdownText.Text = Text
                    end
                end

                function Dropdown:SetVisible(Visible: boolean)
                    Dropdown.Visible = Visible
                    DropdownHolder.Visible = Visible
                end

                function Dropdown:Open()
                    if Dropdown.Open then
                        return
                    end

                    Dropdown.Open = true
                    DropdownList.Visible = true
                    DropdownArrow.Rotation = 180
                end

                function Dropdown:Close()
                    if not Dropdown.Open then
                        return
                    end

                    Dropdown.Open = false
                    DropdownList.Visible = false
                    DropdownArrow.Rotation = 0
                end

                function Dropdown:Toggle()
                    if Dropdown.Open then
                        Dropdown:Close()
                    else
                        Dropdown:Open()
                    end
                end

                for _, Value in pairs(Config.Values) do
                    local OptionButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = Value,
                        TextSize = 14,
                        Parent = DropdownContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = OptionButton,
                    })

                    if Config.Multi then
                        local OptionTick = New("ImageLabel", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -8, 0.5, 0),
                            Size = UDim2.fromOffset(12, 12),
                            Image = Library:GetIcon("check").Url,
                            Visible = false,
                            Parent = OptionButton,
                        })

                        if table.find(Dropdown.Value, Value) then
                            OptionTick.Visible = true
                        end

                        OptionButton.MouseButton1Click:Connect(function()
                            local NewValue = {}
                            for _, V in pairs(Dropdown.Value) do
                                table.insert(NewValue, V)
                            end

                            if table.find(NewValue, Value) then
                                table.remove(NewValue, table.find(NewValue, Value))
                                OptionTick.Visible = false
                            else
                                table.insert(NewValue, Value)
                                OptionTick.Visible = true
                            end

                            Dropdown:SetValue(NewValue, true)
                        end)
                    else
                        OptionButton.MouseButton1Click:Connect(function()
                            Dropdown:SetValue(Value, true)
                            Dropdown:Close()
                        end)
                    end
                end

                Dropdown:RecalculateListSize()

                DropdownButton.MouseButton1Click:Connect(function()
                    Dropdown:Toggle()
                end)

                UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Open then
                        local MousePos = UserInputService:GetMouseLocation()
                        local AbsPos, AbsSize = DropdownList.AbsolutePosition, DropdownList.AbsoluteSize

                        if
                            MousePos.X < AbsPos.X
                            or MousePos.X > AbsPos.X + AbsSize.X
                            or MousePos.Y < AbsPos.Y
                            or MousePos.Y > AbsPos.Y + AbsSize.Y
                        then
                            Dropdown:Close()
                        end
                    end
                end)

                return Dropdown
            end

            function Groupbox:AddKeyPicker(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.KeyPicker)

                local KeyPicker = {}
                KeyPicker.Type = "KeyPicker"
                KeyPicker.Value = Config.Default
                KeyPicker.Modifiers = Config.DefaultModifiers
                KeyPicker.Picking = false

                local KeyPickerHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = GroupboxContent,
                })

                local KeyPickerButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    Parent = KeyPickerHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = KeyPickerButton,
                })

                local KeyPickerText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -24, 1, 0),
                    Text = Config.Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value)),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = KeyPickerButton,
                })

                local KeyPickerReset = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    Text = "×",
                    TextSize = 20,
                    Parent = KeyPickerButton,
                })

                KeyPicker.Holder = KeyPickerHolder
                KeyPicker.Text = Config.Text
                KeyPicker.Visible = Config.Visible

                table.insert(Options, KeyPicker)
                table.insert(Groupbox.Elements, KeyPicker)

                function KeyPicker:SetValue(Value: Enum.KeyCode, Callback: boolean?)
                    if KeyPicker.Value == Value then
                        return
                    end

                    KeyPicker.Value = Value
                    KeyPickerText.Text = Config.Text .. ": " .. (Value == "None" and "None" or Library:GetKeyString(Value))

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, KeyPicker)
                    end
                    Library:SafeCallback(Config.Changed, Value, KeyPicker)
                end

                function KeyPicker:GetValue()
                    return KeyPicker.Value
                end

                function KeyPicker:SetText(Text: string)
                    KeyPicker.Text = Text
                    KeyPickerText.Text = Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value))
                end

                function KeyPicker:SetVisible(Visible: boolean)
                    KeyPicker.Visible = Visible
                    KeyPickerHolder.Visible = Visible
                end

                KeyPickerButton.MouseButton1Click:Connect(function()
                    KeyPicker.Picking = true
                    KeyPickerText.Text = Config.Text .. ": ..."
                end)

                KeyPickerReset.MouseButton1Click:Connect(function()
                    KeyPicker:SetValue("None", true)
                end)

                UserInputService.InputBegan:Connect(function(Input)
                    if KeyPicker.Picking then
                        KeyPicker.Picking = false

                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            KeyPicker:SetValue(Input.KeyCode, true)
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            KeyPicker:SetValue(Enum.KeyCode.MouseButton1, true)
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker:SetValue(Enum.KeyCode.MouseButton2, true)
                        end
                    end
                end)

                return KeyPicker
            end

            function Groupbox:AddColorPicker(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.ColorPicker)

                local ColorPicker = {}
                ColorPicker.Type = "ColorPicker"
                ColorPicker.Value = Config.Default
                ColorPicker.Open = false

                local ColorPickerHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = GroupboxContent,
                })

                local ColorPickerButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    Parent = ColorPickerHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerButton,
                })

                local ColorPickerText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ColorPickerButton,
                })

                local ColorPickerPreview = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = ColorPicker.Value,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(24, 24),
                    Parent = ColorPickerButton,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerPreview,
                })

                local ColorPickerList = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromOffset(0, 30),
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ZIndex = 10,
                    Parent = ColorPickerHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerList,
                })

                local ColorPickerPadding = New("UIPadding", {
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    PaddingTop = UDim.new(0, 4),
                    Parent = ColorPickerList,
                })

                local ColorPickerContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Parent = ColorPickerList,
                })

                local ColorPickerHue = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerHue,
                })

                local ColorPickerHueImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = "rbxassetid://4155801252",
                    Parent = ColorPickerHue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerHueImage,
                })

                local ColorPickerHueButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ColorPickerHue,
                })

                local ColorPickerHueSelector = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "White",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Parent = ColorPickerHue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorPickerHueSelector,
                })

                local ColorPickerSaturation = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 24),
                    Size = UDim2.new(1, 0, 0, 100),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerSaturation,
                })

                local ColorPickerSaturationImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = "rbxassetid://4155801252",
                    Parent = ColorPickerSaturation,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerSaturationImage,
                })

                local ColorPickerSaturationButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ColorPickerSaturation,
                })

                local ColorPickerSaturationSelector = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "White",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Parent = ColorPickerSaturation,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorPickerSaturationSelector,
                })

                local ColorPickerValue = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 128),
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerValue,
                })

                local ColorPickerValueImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = "rbxassetid://4155801252",
                    Parent = ColorPickerValue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerValueImage,
                })

                local ColorPickerValueButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ColorPickerValue,
                })

                local ColorPickerValueSelector = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "White",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Parent = ColorPickerValue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorPickerValueSelector,
                })

                local ColorPickerHex = New("TextBox", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 152),
                    Size = UDim2.new(1, 0, 0, 24),
                    Text = "#" .. ColorPicker.Value:ToHex(),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerHex,
                })

                ColorPickerList.Size = UDim2.new(1, 0, 0, 176)

                ColorPicker.Holder = ColorPickerHolder
                ColorPicker.Text = Config.Text
                ColorPicker.Visible = Config.Visible

                table.insert(Options, ColorPicker)
                table.insert(Groupbox.Elements, ColorPicker)

                function ColorPicker:SetValue(Value: Color3, Callback: boolean?)
                    if ColorPicker.Value == Value then
                        return
                    end

                    ColorPicker.Value = Value
                    ColorPickerPreview.BackgroundColor3 = Value
                    ColorPickerHex.Text = "#" .. Value:ToHex()

                    local H, S, V = Value:ToHSV()
                    ColorPickerHueSelector.Position = UDim2.fromScale(H, 0.5)
                    ColorPickerSaturationSelector.Position = UDim2.fromScale(S, 1 - V)
                    ColorPickerValueSelector.Position = UDim2.fromScale(0.5, 1 - V)

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, ColorPicker)
                    end
                    Library:SafeCallback(Config.Changed, Value, ColorPicker)
                end

                function ColorPicker:GetValue()
                    return ColorPicker.Value
                end

                function ColorPicker:SetText(Text: string)
                    ColorPicker.Text = Text
                    ColorPickerText.Text = Text
                end

                function ColorPicker:SetVisible(Visible: boolean)
                    ColorPicker.Visible = Visible
                    ColorPickerHolder.Visible = Visible
                end

                function ColorPicker:Open()
                    if ColorPicker.Open then
                        return
                    end

                    ColorPicker.Open = true
                    ColorPickerList.Visible = true
                end

                function ColorPicker:Close()
                    if not ColorPicker.Open then
                        return
                    end

                    ColorPicker.Open = false
                    ColorPickerList.Visible = false
                end

                function ColorPicker:Toggle()
                    if ColorPicker.Open then
                        ColorPicker:Close()
                    else
                        ColorPicker:Open()
                    end
                end

                local function UpdateFromHue()
                    local H = (ColorPickerHueSelector.AbsolutePosition.X - ColorPickerHue.AbsolutePosition.X) / ColorPickerHue.AbsoluteSize.X
                    local S, V = ColorPicker.Value:ToHSV()
                    ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                end

                local function UpdateFromSaturation()
                    local S = (ColorPickerSaturationSelector.AbsolutePosition.X - ColorPickerSaturation.AbsolutePosition.X) / ColorPickerSaturation.AbsoluteSize.X
                    local V = 1 - (ColorPickerSaturationSelector.AbsolutePosition.Y - ColorPickerSaturation.AbsolutePosition.Y) / ColorPickerSaturation.AbsoluteSize.Y
                    local H = ColorPicker.Value:ToHSV()
                    ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                end

                local function UpdateFromValue()
                    local V = 1 - (ColorPickerValueSelector.AbsolutePosition.Y - ColorPickerValue.AbsolutePosition.Y) / ColorPickerValue.AbsoluteSize.Y
                    local H, S = ColorPicker.Value:ToHSV()
                    ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                end

                local function UpdateFromHex()
                    local Hex = ColorPickerHex.Text:match("#(%x%x%x%x%x%x)")
                    if Hex then
                        local R = tonumber(Hex:sub(1, 2), 16) / 255
                        local G = tonumber(Hex:sub(3, 4), 16) / 255
                        local B = tonumber(Hex:sub(5, 6), 16) / 255
                        ColorPicker:SetValue(Color3.new(R, G, B), true)
                    else
                        ColorPickerHex.Text = "#" .. ColorPicker.Value:ToHex()
                    end
                end

                local HueDragging = false
                ColorPickerHueButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        HueDragging = true
                        UpdateFromHue()
                    end
                end)

                local SaturationDragging = false
                ColorPickerSaturationButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        SaturationDragging = true
                        UpdateFromSaturation()
                    end
                end)

                local ValueDragging = false
                ColorPickerValueButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        ValueDragging = true
                        UpdateFromValue()
                    end
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if HueDragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = ColorPickerHue.AbsolutePosition
                        local BarSize = ColorPickerHue.AbsoluteSize

                        local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                        ColorPickerHueSelector.Position = UDim2.fromScale(Percent, 0.5)
                        UpdateFromHue()
                    elseif SaturationDragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = ColorPickerSaturation.AbsolutePosition
                        local BarSize = ColorPickerSaturation.AbsoluteSize

                        local PercentX = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                        local PercentY = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                        ColorPickerSaturationSelector.Position = UDim2.fromScale(PercentX, PercentY)
                        UpdateFromSaturation()
                    elseif ValueDragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = ColorPickerValue.AbsolutePosition
                        local BarSize = ColorPickerValue.AbsoluteSize

                        local Percent = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                        ColorPickerValueSelector.Position = UDim2.fromScale(0.5, Percent)
                        UpdateFromValue()
                    end
                end)

                UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        HueDragging = false
                        SaturationDragging = false
                        ValueDragging = false
                    end
                end)

                ColorPickerHex.FocusLost:Connect(function()
                    UpdateFromHex()
                end)

                ColorPickerButton.MouseButton1Click:Connect(function()
                    ColorPicker:Toggle()
                end)

                UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and ColorPicker.Open then
                        local MousePos = UserInputService:GetMouseLocation()
                        local AbsPos, AbsSize = ColorPickerList.AbsolutePosition, ColorPickerList.AbsoluteSize

                        if
                            MousePos.X < AbsPos.X
                            or MousePos.X > AbsPos.X + AbsSize.X
                            or MousePos.Y < AbsPos.Y
                            or MousePos.Y > AbsPos.Y + AbsSize.Y
                        then
                            ColorPicker:Close()
                        end
                    end
                end)

                return ColorPicker
            end

            function Groupbox:AddDivider()
                local Divider = {}
                Divider.Type = "Divider"

                local DividerHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 8),
                    Parent = GroupboxContent,
                })

                local DividerLine = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = "OutlineColor",
                    Position = UDim2.fromOffset(0, 4),
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = DividerHolder,
                })

                Divider.Holder = DividerHolder
                Divider.Visible = true

                table.insert(Groupbox.Elements, Divider)

                function Divider:SetVisible(Visible: boolean)
                    Divider.Visible = Visible
                    DividerHolder.Visible = Visible
                end

                return Divider
            end

            function Groupbox:Resize()
                local ContentSize = 0
                for _, Element in pairs(Groupbox.Elements) do
                    if Element.Visible then
                        ContentSize += Element.Holder.AbsoluteSize.Y + 4
                    end
                end

                GroupboxHolder.Size = UDim2.new(0.5, -3, 0, ContentSize)
            end

            function Groupbox:Update(Force: boolean?)
                for _, Element in pairs(Groupbox.Elements) do
                    if Element.Type == "Toggle" and Element.Value then
                        for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                            if Depbox.Toggle == Element then
                                Depbox.Holder.Visible = true
                            end
                        end
                    elseif Element.Type == "Toggle" and not Element.Value then
                        for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                            if Depbox.Toggle == Element then
                                Depbox.Holder.Visible = false
                            end
                        end
                    end
                end

                Groupbox:Resize()
            end

            function Groupbox:AddDependencyBox(Toggle: any)
                local Depbox = {}
                Depbox.Type = "DependencyBox"
                Depbox.Toggle = Toggle
                Depbox.Elements = {}
                Depbox.DependencyBoxes = {}

                local DepboxHolder = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    Parent = GroupboxContent,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = DepboxHolder,
                })

                local DepboxPadding = New("UIPadding", {
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 6),
                    Parent = DepboxHolder,
                })

                local DepboxList = New("UIListLayout", {
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = DepboxHolder,
                })

                Depbox.Holder = DepboxHolder
                Depbox.Visible = false

                table.insert(Groupbox.DependencyBoxes, Depbox)

                function Depbox:AddLabel(Config: { [string]: any })
                    Config = Library:Validate(Config, {
                        Text = "Label",
                        Visible = true,
                    })

                    local Label = {}
                    Label.Type = "Label"

                    local LabelHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = DepboxHolder,
                    })

                    local LabelText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        Parent = LabelHolder,
                    })

                    Label.Holder = LabelHolder
                    Label.Text = Config.Text
                    Label.Visible = Config.Visible

                    table.insert(Labels, Label)
                    table.insert(Depbox.Elements, Label)

                    function Label:SetText(Text: string)
                        Label.Text = Text
                        LabelText.Text = Text
                    end

                    function Label:SetVisible(Visible: boolean)
                        Label.Visible = Visible
                        LabelHolder.Visible = Visible
                    end

                    return Label
                end

                function Depbox:AddButton(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Button)

                    local Button = {}
                    Button.Type = "Button"

                    local ButtonHolder = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 28),
                        Text = "",
                        Parent = DepboxHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ButtonHolder,
                    })

                    local ButtonText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        Parent = ButtonHolder,
                    })

                    Button.Holder = ButtonHolder
                    Button.Text = Config.Text
                    Button.Visible = Config.Visible

                    table.insert(Buttons, Button)
                    table.insert(Depbox.Elements, Button)

                    ButtonHolder.MouseButton1Click:Connect(function()
                        Library:SafeCallback(Config.Callback, Button)
                    end)

                    function Button:SetText(Text: string)
                        Button.Text = Text
                        ButtonText.Text = Text
                    end

                    function Button:SetVisible(Visible: boolean)
                        Button.Visible = Visible
                        ButtonHolder.Visible = Visible
                    end

                    return Button
                end

                function Depbox:AddToggle(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Toggle)

                    local Toggle = {}
                    Toggle.Type = "Toggle"
                    Toggle.Value = Config.Default

                    local ToggleHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 28),
                        Parent = DepboxHolder,
                    })

                    local ToggleButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ToggleHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ToggleButton,
                    })

                    local ToggleText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(28, 0),
                        Size = UDim2.new(1, -28, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = ToggleButton,
                    })

                    local ToggleOuter = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(8, 0.5),
                        Size = UDim2.fromOffset(16, 16),
                        Parent = ToggleButton,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 8),
                        Parent = ToggleOuter,
                    })

                    local ToggleInner = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "AccentColor",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Visible = Toggle.Value,
                        Parent = ToggleOuter,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ToggleInner,
                    })

                    Toggle.Holder = ToggleHolder
                    Toggle.Text = Config.Text
                    Toggle.Visible = Config.Visible

                    table.insert(Toggles, Toggle)
                    table.insert(Depbox.Elements, Toggle)

                    function Toggle:SetValue(Value: boolean, Callback: boolean?)
                        if Toggle.Value == Value then
                            return
                        end

                        Toggle.Value = Value
                        ToggleInner.Visible = Value

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Toggle)
                        end
                        Library:SafeCallback(Config.Changed, Value, Toggle)
                    end

                    function Toggle:GetValue()
                        return Toggle.Value
                    end

                    function Toggle:SetText(Text: string)
                        Toggle.Text = Text
                        ToggleText.Text = Text
                    end

                    function Toggle:SetVisible(Visible: boolean)
                        Toggle.Visible = Visible
                        ToggleHolder.Visible = Visible
                    end

                    ToggleButton.MouseButton1Click:Connect(function()
                        Toggle:SetValue(not Toggle.Value, true)
                    end)

                    return Toggle
                end

                function Depbox:AddSlider(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Slider)

                    local Slider = {}
                    Slider.Type = "Slider"
                    Slider.Value = Config.Default

                    local SliderHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 50),
                        Parent = DepboxHolder,
                    })

                    local SliderText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = Config.Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix,
                        TextSize = 14,
                        Parent = SliderHolder,
                    })

                    local SliderBar = New("Frame", {
                        AnchorPoint = Vector2.new(0, 1),
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 50),
                        Size = UDim2.new(1, 0, 0, 4),
                        Parent = SliderHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 2),
                        Parent = SliderBar,
                    })

                    local SliderFill = New("Frame", {
                        BackgroundColor3 = "AccentColor",
                        Size = UDim2.fromScale((Slider.Value - Config.Min) / (Config.Max - Config.Min), 1),
                        Parent = SliderBar,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 2),
                        Parent = SliderFill,
                    })

                    local SliderButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = SliderHolder,
                    })

                    Slider.Holder = SliderHolder
                    Slider.Text = Config.Text
                    Slider.Visible = Config.Visible

                    table.insert(Options, Slider)
                    table.insert(Depbox.Elements, Slider)

                    function Slider:SetValue(Value: number, Callback: boolean?)
                        Value = math.clamp(Value, Config.Min, Config.Max)
                        if Slider.Value == Value then
                            return
                        end

                        Slider.Value = Value
                        SliderFill.Size = UDim2.fromScale((Value - Config.Min) / (Config.Max - Config.Min), 1)
                        SliderText.Text = Config.Text .. ": " .. Config.Suffix .. Round(Value, Config.Rounding) .. Config.Suffix

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Slider)
                        end
                        Library:SafeCallback(Config.Changed, Value, Slider)
                    end

                    function Slider:GetValue()
                        return Slider.Value
                    end

                    function Slider:SetText(Text: string)
                        Slider.Text = Text
                        SliderText.Text = Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix
                    end

                    function Slider:SetVisible(Visible: boolean)
                        Slider.Visible = Visible
                        SliderHolder.Visible = Visible
                    end

                    local Dragging = false
                    SliderButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            Dragging = true
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = false
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(Input)
                        if Dragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = SliderBar.AbsolutePosition
                            local BarSize = SliderBar.AbsoluteSize

                            local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                            local Value = Config.Min + (Config.Max - Config.Min) * Percent

                            Slider:SetValue(Round(Value, Config.Rounding), true)
                        end
                    end)

                    return Slider
                end

                function Depbox:AddTextbox(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Input)

                    local Textbox = {}
                    Textbox.Type = "Textbox"
                    Textbox.Value = Config.Default

                    local TextboxHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 50),
                        Parent = DepboxHolder,
                    })

                    local TextboxText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = Config.Text,
                        TextSize = 14,
                        Parent = TextboxHolder,
                    })

                    local TextboxBox = New("TextBox", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 20),
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = Config.Default,
                        PlaceholderText = Config.Placeholder,
                        Parent = TextboxHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = TextboxBox,
                    })

                    Textbox.Holder = TextboxHolder
                    Textbox.Text = Config.Text
                    Textbox.Visible = Config.Visible

                    table.insert(Options, Textbox)
                    table.insert(Depbox.Elements, Textbox)

                    function Textbox:SetValue(Value: string, Callback: boolean?)
                        if Textbox.Value == Value then
                            return
                        end

                        Textbox.Value = Value
                        TextboxBox.Text = Value

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Textbox)
                        end
                        Library:SafeCallback(Config.Changed, Value, Textbox)
                    end

                    function Textbox:GetValue()
                        return Textbox.Value
                    end

                    function Textbox:SetText(Text: string)
                        Textbox.Text = Text
                        TextboxText.Text = Text
                    end

                    function Textbox:SetVisible(Visible: boolean)
                        Textbox.Visible = Visible
                        TextboxHolder.Visible = Visible
                    end

                    TextboxBox.FocusLost:Connect(function(EnterPressed)
                        if Config.Numeric then
                            local Value = tonumber(TextboxBox.Text)
                            if Value then
                                Textbox:SetValue(tostring(Value), true)
                            else
                                TextboxBox.Text = Textbox.Value
                            end
                        else
                            Textbox:SetValue(TextboxBox.Text, true)
                        end
                    end)

                    return Textbox
                end

                function Depbox:AddDropdown(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Dropdown)

                    local Dropdown = {}
                    Dropdown.Type = "Dropdown"
                    Dropdown.Value = Config.Multi and {} or Config.Values[1]
                    Dropdown.Open = false

                    local DropdownHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = DepboxHolder,
                    })

                    local DropdownButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = "",
                        Parent = DropdownHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = DropdownButton,
                    })

                    local DropdownText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -24, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = DropdownButton,
                    })

                    local DropdownArrow = New("ImageLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(12, 12),
                        Image = Library:GetIcon("chevron-down").Url,
                        Parent = DropdownButton,
                    })

                    local DropdownList = New("Frame", {
                        BackgroundColor3 = "MainColor",
                        Position = UDim2.fromOffset(0, 30),
                        Size = UDim2.new(1, 0, 0, 0),
                        Visible = false,
                        ZIndex = 10,
                        Parent = DropdownHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = DropdownList,
                    })

                    local DropdownPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = DropdownList,
                    })

                    local DropdownContainer = New("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        ScrollBarThickness = 0,
                        Parent = DropdownList,
                    })

                    local DropdownListLayout = New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = DropdownContainer,
                    })

                    Dropdown.Holder = DropdownHolder
                    Dropdown.Text = Config.Text
                    Dropdown.Visible = Config.Visible

                    table.insert(Options, Dropdown)
                    table.insert(Depbox.Elements, Dropdown)

                    function Dropdown:RecalculateListSize()
                        local ListSize = 0
                        for _, Option in pairs(DropdownContainer:GetChildren()) do
                            if Option:IsA("TextButton") then
                                ListSize += Option.AbsoluteSize.Y + 2
                            end
                        end

                        DropdownList.Size = UDim2.new(1, 0, 0, math.min(ListSize, Config.MaxVisibleDropdownItems * 24))
                        DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, ListSize)
                    end

                    function Dropdown:SetValue(Value: any, Callback: boolean?)
                        if Config.Multi then
                            if type(Value) ~= "table" then
                                return
                            end

                            local NewValue = {}
                            for _, V in pairs(Value) do
                                if table.find(Config.Values, V) then
                                    table.insert(NewValue, V)
                                end
                            end

                            if #NewValue == #Dropdown.Value then
                                local Same = true
                                for _, V in pairs(NewValue) do
                                    if not table.find(Dropdown.Value, V) then
                                        Same = false
                                        break
                                    end
                                end

                                if Same then
                                    return
                                end
                            end

                            Dropdown.Value = NewValue
                            DropdownText.Text = #NewValue > 0 and table.concat(NewValue, ", ") or Config.Text

                            if Callback then
                                Library:SafeCallback(Config.Callback, NewValue, Dropdown)
                            end
                            Library:SafeCallback(Config.Changed, NewValue, Dropdown)
                        else
                            if not table.find(Config.Values, Value) then
                                return
                            end

                            if Dropdown.Value == Value then
                                return
                            end

                            Dropdown.Value = Value
                            DropdownText.Text = Value

                            if Callback then
                                Library:SafeCallback(Config.Callback, Value, Dropdown)
                            end
                            Library:SafeCallback(Config.Changed, Value, Dropdown)
                        end
                    end

                    function Dropdown:GetValue()
                        return Dropdown.Value
                    end

                    function Dropdown:SetText(Text: string)
                        Dropdown.Text = Text
                        if not Config.Multi or #Dropdown.Value == 0 then
                            DropdownText.Text = Text
                        end
                    end

                    function Dropdown:SetVisible(Visible: boolean)
                        Dropdown.Visible = Visible
                        DropdownHolder.Visible = Visible
                    end

                    function Dropdown:Open()
                        if Dropdown.Open then
                            return
                        end

                        Dropdown.Open = true
                        DropdownList.Visible = true
                        DropdownArrow.Rotation = 180
                    end

                    function Dropdown:Close()
                        if not Dropdown.Open then
                            return
                        end

                        Dropdown.Open = false
                        DropdownList.Visible = false
                        DropdownArrow.Rotation = 0
                    end

                    function Dropdown:Toggle()
                        if Dropdown.Open then
                            Dropdown:Close()
                        else
                            Dropdown:Open()
                        end
                    end

                    for _, Value in pairs(Config.Values) do
                        local OptionButton = New("TextButton", {
                            BackgroundColor3 = "BackgroundColor",
                            Size = UDim2.new(1, 0, 0, 24),
                            Text = Value,
                            TextSize = 14,
                            Parent = DropdownContainer,
                        })
                        New("UICorner", {
                            CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                            Parent = OptionButton,
                        })

                        if Config.Multi then
                            local OptionTick = New("ImageLabel", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(1, -8, 0.5, 0),
                                Size = UDim2.fromOffset(12, 12),
                                Image = Library:GetIcon("check").Url,
                                Visible = false,
                                Parent = OptionButton,
                            })

                            if table.find(Dropdown.Value, Value) then
                                OptionTick.Visible = true
                            end

                            OptionButton.MouseButton1Click:Connect(function()
                                local NewValue = {}
                                for _, V in pairs(Dropdown.Value) do
                                    table.insert(NewValue, V)
                                end

                                if table.find(NewValue, Value) then
                                    table.remove(NewValue, table.find(NewValue, Value))
                                    OptionTick.Visible = false
                                else
                                    table.insert(NewValue, Value)
                                    OptionTick.Visible = true
                                end

                                Dropdown:SetValue(NewValue, true)
                            end)
                        else
                            OptionButton.MouseButton1Click:Connect(function()
                                Dropdown:SetValue(Value, true)
                                Dropdown:Close()
                            end)
                        end
                    end

                    Dropdown:RecalculateListSize()

                    DropdownButton.MouseButton1Click:Connect(function()
                        Dropdown:Toggle()
                    end)

                    UserInputService.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Open then
                            local MousePos = UserInputService:GetMouseLocation()
                            local AbsPos, AbsSize = DropdownList.AbsolutePosition, DropdownList.AbsoluteSize

                            if
                                MousePos.X < AbsPos.X
                                or MousePos.X > AbsPos.X + AbsSize.X
                                or MousePos.Y < AbsPos.Y
                                or MousePos.Y > AbsPos.Y + AbsSize.Y
                            then
                                Dropdown:Close()
                            end
                        end
                    end)

                    return Dropdown
                end

                function Depbox:AddKeyPicker(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.KeyPicker)

                    local KeyPicker = {}
                    KeyPicker.Type = "KeyPicker"
                    KeyPicker.Value = Config.Default
                    KeyPicker.Modifiers = Config.DefaultModifiers
                    KeyPicker.Picking = false

                    local KeyPickerHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = DepboxHolder,
                    })

                    local KeyPickerButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = "",
                        Parent = KeyPickerHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = KeyPickerButton,
                    })

                    local KeyPickerText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -24, 1, 0),
                        Text = Config.Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value)),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = KeyPickerButton,
                    })

                    local KeyPickerReset = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(16, 16),
                        Text = "×",
                        TextSize = 20,
                        Parent = KeyPickerButton,
                    })

                    KeyPicker.Holder = KeyPickerHolder
                    KeyPicker.Text = Config.Text
                    KeyPicker.Visible = Config.Visible

                    table.insert(Options, KeyPicker)
                    table.insert(Depbox.Elements, KeyPicker)

                    function KeyPicker:SetValue(Value: Enum.KeyCode, Callback: boolean?)
                        if KeyPicker.Value == Value then
                            return
                        end

                        KeyPicker.Value = Value
                        KeyPickerText.Text = Config.Text .. ": " .. (Value == "None" and "None" or Library:GetKeyString(Value))

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, KeyPicker)
                        end
                        Library:SafeCallback(Config.Changed, Value, KeyPicker)
                    end

                    function KeyPicker:GetValue()
                        return KeyPicker.Value
                    end

                    function KeyPicker:SetText(Text: string)
                        KeyPicker.Text = Text
                        KeyPickerText.Text = Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value))
                    end

                    function KeyPicker:SetVisible(Visible: boolean)
                        KeyPicker.Visible = Visible
                        KeyPickerHolder.Visible = Visible
                    end

                    KeyPickerButton.MouseButton1Click:Connect(function()
                        KeyPicker.Picking = true
                        KeyPickerText.Text = Config.Text .. ": ..."
                    end)

                    KeyPickerReset.MouseButton1Click:Connect(function()
                        KeyPicker:SetValue("None", true)
                    end)

                    UserInputService.InputBegan:Connect(function(Input)
                        if KeyPicker.Picking then
                            KeyPicker.Picking = false

                            if Input.UserInputType == Enum.UserInputType.Keyboard then
                                KeyPicker:SetValue(Input.KeyCode, true)
                            elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                KeyPicker:SetValue(Enum.KeyCode.MouseButton1, true)
                            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                                KeyPicker:SetValue(Enum.KeyCode.MouseButton2, true)
                            end
                        end
                    end)

                    return KeyPicker
                end

                function Depbox:AddColorPicker(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.ColorPicker)

                    local ColorPicker = {}
                    ColorPicker.Type = "ColorPicker"
                    ColorPicker.Value = Config.Default
                    ColorPicker.Open = false

                    local ColorPickerHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = DepboxHolder,
                    })

                    local ColorPickerButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = "",
                        Parent = ColorPickerHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerButton,
                    })

                    local ColorPickerText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -40, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = ColorPickerButton,
                    })

                    local ColorPickerPreview = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = ColorPicker.Value,
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(24, 24),
                        Parent = ColorPickerButton,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerPreview,
                    })

                    local ColorPickerList = New("Frame", {
                        BackgroundColor3 = "MainColor",
                        Position = UDim2.fromOffset(0, 30),
                        Size = UDim2.new(1, 0, 0, 0),
                        Visible = false,
                        ZIndex = 10,
                        Parent = ColorPickerHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerList,
                    })

                    local ColorPickerPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = ColorPickerList,
                    })

                    local ColorPickerContainer = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Parent = ColorPickerList,
                    })

                    local ColorPickerHue = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 0),
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerHue,
                    })

                    local ColorPickerHueImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://4155801252",
                        Parent = ColorPickerHue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerHueImage,
                    })

                    local ColorPickerHueButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ColorPickerHue,
                    })

                    local ColorPickerHueSelector = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "White",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Parent = ColorPickerHue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ColorPickerHueSelector,
                    })

                    local ColorPickerSaturation = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 24),
                        Size = UDim2.new(1, 0, 0, 100),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerSaturation,
                    })

                    local ColorPickerSaturationImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://4155801252",
                        Parent = ColorPickerSaturation,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerSaturationImage,
                    })

                    local ColorPickerSaturationButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ColorPickerSaturation,
                    })

                    local ColorPickerSaturationSelector = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "White",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Parent = ColorPickerSaturation,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ColorPickerSaturationSelector,
                    })

                    local ColorPickerValue = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 128),
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerValue,
                    })

                    local ColorPickerValueImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://4155801252",
                        Parent = ColorPickerValue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerValueImage,
                    })

                    local ColorPickerValueButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ColorPickerValue,
                    })

                    local ColorPickerValueSelector = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "White",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Parent = ColorPickerValue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ColorPickerValueSelector,
                    })

                    local ColorPickerHex = New("TextBox", {
                        AnchorPoint = Vector2.new(0, 1),
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 152),
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = "#" .. ColorPicker.Value:ToHex(),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerHex,
                    })

                    ColorPickerList.Size = UDim2.new(1, 0, 0, 176)

                    ColorPicker.Holder = ColorPickerHolder
                    ColorPicker.Text = Config.Text
                    ColorPicker.Visible = Config.Visible

                    table.insert(Options, ColorPicker)
                    table.insert(Depbox.Elements, ColorPicker)

                    function ColorPicker:SetValue(Value: Color3, Callback: boolean?)
                        if ColorPicker.Value == Value then
                            return
                        end

                        ColorPicker.Value = Value
                        ColorPickerPreview.BackgroundColor3 = Value
                        ColorPickerHex.Text = "#" .. Value:ToHex()

                        local H, S, V = Value:ToHSV()
                        ColorPickerHueSelector.Position = UDim2.fromScale(H, 0.5)
                        ColorPickerSaturationSelector.Position = UDim2.fromScale(S, 1 - V)
                        ColorPickerValueSelector.Position = UDim2.fromScale(0.5, 1 - V)

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, ColorPicker)
                        end
                        Library:SafeCallback(Config.Changed, Value, ColorPicker)
                    end

                    function ColorPicker:GetValue()
                        return ColorPicker.Value
                    end

                    function ColorPicker:SetText(Text: string)
                        ColorPicker.Text = Text
                        ColorPickerText.Text = Text
                    end

                    function ColorPicker:SetVisible(Visible: boolean)
                        ColorPicker.Visible = Visible
                        ColorPickerHolder.Visible = Visible
                    end

                    function ColorPicker:Open()
                        if ColorPicker.Open then
                            return
                        end

                        ColorPicker.Open = true
                        ColorPickerList.Visible = true
                    end

                    function ColorPicker:Close()
                        if not ColorPicker.Open then
                            return
                        end

                        ColorPicker.Open = false
                        ColorPickerList.Visible = false
                    end

                    function ColorPicker:Toggle()
                        if ColorPicker.Open then
                            ColorPicker:Close()
                        else
                            ColorPicker:Open()
                        end
                    end

                    local function UpdateFromHue()
                        local H = (ColorPickerHueSelector.AbsolutePosition.X - ColorPickerHue.AbsolutePosition.X) / ColorPickerHue.AbsoluteSize.X
                        local S, V = ColorPicker.Value:ToHSV()
                        ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                    end

                    local function UpdateFromSaturation()
                        local S = (ColorPickerSaturationSelector.AbsolutePosition.X - ColorPickerSaturation.AbsolutePosition.X) / ColorPickerSaturation.AbsoluteSize.X
                        local V = 1 - (ColorPickerSaturationSelector.AbsolutePosition.Y - ColorPickerSaturation.AbsolutePosition.Y) / ColorPickerSaturation.AbsoluteSize.Y
                        local H = ColorPicker.Value:ToHSV()
                        ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                    end

                    local function UpdateFromValue()
                        local V = 1 - (ColorPickerValueSelector.AbsolutePosition.Y - ColorPickerValue.AbsolutePosition.Y) / ColorPickerValue.AbsoluteSize.Y
                        local H, S = ColorPicker.Value:ToHSV()
                        ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                    end

                    local function UpdateFromHex()
                        local Hex = ColorPickerHex.Text:match("#(%x%x%x%x%x%x)")
                        if Hex then
                            local R = tonumber(Hex:sub(1, 2), 16) / 255
                            local G = tonumber(Hex:sub(3, 4), 16) / 255
                            local B = tonumber(Hex:sub(5, 6), 16) / 255
                            ColorPicker:SetValue(Color3.new(R, G, B), true)
                        else
                            ColorPickerHex.Text = "#" .. ColorPicker.Value:ToHex()
                        end
                    end

                    local HueDragging = false
                    ColorPickerHueButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            HueDragging = true
                            UpdateFromHue()
                        end
                    end)

                    local SaturationDragging = false
                    ColorPickerSaturationButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            SaturationDragging = true
                            UpdateFromSaturation()
                        end
                    end)

                    local ValueDragging = false
                    ColorPickerValueButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            ValueDragging = true
                            UpdateFromValue()
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(Input)
                        if HueDragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = ColorPickerHue.AbsolutePosition
                            local BarSize = ColorPickerHue.AbsoluteSize

                            local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                            ColorPickerHueSelector.Position = UDim2.fromScale(Percent, 0.5)
                            UpdateFromHue()
                        elseif SaturationDragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = ColorPickerSaturation.AbsolutePosition
                            local BarSize = ColorPickerSaturation.AbsoluteSize

                            local PercentX = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                            local PercentY = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                            ColorPickerSaturationSelector.Position = UDim2.fromScale(PercentX, PercentY)
                            UpdateFromSaturation()
                        elseif ValueDragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = ColorPickerValue.AbsolutePosition
                            local BarSize = ColorPickerValue.AbsoluteSize

                            local Percent = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                            ColorPickerValueSelector.Position = UDim2.fromScale(0.5, Percent)
                            UpdateFromValue()
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            HueDragging = false
                            SaturationDragging = false
                            ValueDragging = false
                        end
                    end)

                    ColorPickerHex.FocusLost:Connect(function()
                        UpdateFromHex()
                    end)

                    ColorPickerButton.MouseButton1Click:Connect(function()
                        ColorPicker:Toggle()
                    end)

                    UserInputService.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and ColorPicker.Open then
                            local MousePos = UserInputService:GetMouseLocation()
                            local AbsPos, AbsSize = ColorPickerList.AbsolutePosition, ColorPickerList.AbsoluteSize

                            if
                                MousePos.X < AbsPos.X
                                or MousePos.X > AbsPos.X + AbsSize.X
                                or MousePos.Y < AbsPos.Y
                                or MousePos.Y > AbsPos.Y + AbsSize.Y
                            then
                                ColorPicker:Close()
                            end
                        end
                    end)

                    return ColorPicker
                end

                function Depbox:AddDivider()
                    local Divider = {}
                    Divider.Type = "Divider"

                    local DividerHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 8),
                        Parent = DepboxHolder,
                    })

                    local DividerLine = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "OutlineColor",
                        Position = UDim2.fromOffset(0, 4),
                        Size = UDim2.new(1, 0, 0, 1),
                        Parent = DividerHolder,
                    })

                    Divider.Holder = DividerHolder
                    Divider.Visible = true

                    table.insert(Depbox.Elements, Divider)

                    function Divider:SetVisible(Visible: boolean)
                        Divider.Visible = Visible
                        DividerHolder.Visible = Visible
                    end

                    return Divider
                end

                function Depbox:Resize()
                    local ContentSize = 0
                    for _, Element in pairs(Depbox.Elements) do
                        if Element.Visible then
                            ContentSize += Element.Holder.AbsoluteSize.Y + 4
                        end
                    end

                    DepboxHolder.Size = UDim2.new(1, 0, 0, ContentSize)
                end

                function Depbox:Update(Force: boolean?)
                    for _, Element in pairs(Depbox.Elements) do
                        if Element.Type == "Toggle" and Element.Value then
                            for _, SubDepbox in pairs(Depbox.DependencyBoxes) do
                                if SubDepbox.Toggle == Element then
                                    SubDepbox.Holder.Visible = true
                                end
                            end
                        elseif Element.Type == "Toggle" and not Element.Value then
                            for _, SubDepbox in pairs(Depbox.DependencyBoxes) do
                                if SubDepbox.Toggle == Element then
                                    SubDepbox.Holder.Visible = false
                                end
                            end
                        end
                    end

                    Depbox:Resize()
                end

                return Depbox
            end

            Groupbox:Resize()
            table.insert(Window.Groupboxes, Groupbox)

            return Groupbox
        end

        function Tab:CreateTabbox(Config: { [string]: any })
            Config = Library:Validate(Config, {
                Text = "Tabbox",
            })

            local Tabbox = {}
            Tabbox.Tabs = {}

            local TabboxHolder = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.new(1, 0, 0, 30),
                Parent = TabHolder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                Parent = TabboxHolder,
            })

            local TabboxPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 6),
                Parent = TabboxHolder,
            })

            local TabboxButtonHolder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = TabboxHolder,
            })

            local TabboxList = New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabboxButtonHolder,
            })

            local TabboxContent = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(0, 30),
                Size = UDim2.new(1, 0, 1, -30),
                Parent = TabboxHolder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                Parent = TabboxContent,
            })

            local TabboxContentPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 6),
                Parent = TabboxContent,
            })

            Tabbox.Holder = TabboxHolder
            Tabbox.Content = TabboxContent

            function Tabbox:CreateTab(Config: { [string]: any })
                Config = Library:Validate(Config, {
                    Text = "Tab",
                })

                local SubTab = {}
                SubTab.Elements = {}
                SubTab.DependencyBoxes = {}

                local SubTabButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(0, 100, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    Parent = TabboxButtonHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = SubTabButton,
                })

                local SubTabHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Visible = false,
                    Parent = TabboxContent,
                })

                local SubTabList = New("UIListLayout", {
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = SubTabHolder,
                })

                SubTab.Button = SubTabButton
                SubTab.Holder = SubTabHolder
                SubTab.ButtonHolder = TabboxButtonHolder

                function SubTab:AddLabel(Config: { [string]: any })
                    Config = Library:Validate(Config, {
                        Text = "Label",
                        Visible = true,
                    })

                    local Label = {}
                    Label.Type = "Label"

                    local LabelHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = SubTabHolder,
                    })

                    local LabelText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        Parent = LabelHolder,
                    })

                    Label.Holder = LabelHolder
                    Label.Text = Config.Text
                    Label.Visible = Config.Visible

                    table.insert(Labels, Label)
                    table.insert(SubTab.Elements, Label)

                    function Label:SetText(Text: string)
                        Label.Text = Text
                        LabelText.Text = Text
                    end

                    function Label:SetVisible(Visible: boolean)
                        Label.Visible = Visible
                        LabelHolder.Visible = Visible
                    end

                    return Label
                end

                function SubTab:AddButton(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Button)

                    local Button = {}
                    Button.Type = "Button"

                    local ButtonHolder = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 28),
                        Text = "",
                        Parent = SubTabHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ButtonHolder,
                    })

                    local ButtonText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        Parent = ButtonHolder,
                    })

                    Button.Holder = ButtonHolder
                    Button.Text = Config.Text
                    Button.Visible = Config.Visible

                    table.insert(Buttons, Button)
                    table.insert(SubTab.Elements, Button)

                    ButtonHolder.MouseButton1Click:Connect(function()
                        Library:SafeCallback(Config.Callback, Button)
                    end)

                    function Button:SetText(Text: string)
                        Button.Text = Text
                        ButtonText.Text = Text
                    end

                    function Button:SetVisible(Visible: boolean)
                        Button.Visible = Visible
                        ButtonHolder.Visible = Visible
                    end

                    return Button
                end

                function SubTab:AddToggle(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Toggle)

                    local Toggle = {}
                    Toggle.Type = "Toggle"
                    Toggle.Value = Config.Default

                    local ToggleHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 28),
                        Parent = SubTabHolder,
                    })

                    local ToggleButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ToggleHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ToggleButton,
                    })

                    local ToggleText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(28, 0),
                        Size = UDim2.new(1, -28, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = ToggleButton,
                    })

                    local ToggleOuter = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(8, 0.5),
                        Size = UDim2.fromOffset(16, 16),
                        Parent = ToggleButton,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 8),
                        Parent = ToggleOuter,
                    })

                    local ToggleInner = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "AccentColor",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Visible = Toggle.Value,
                        Parent = ToggleOuter,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ToggleInner,
                    })

                    Toggle.Holder = ToggleHolder
                    Toggle.Text = Config.Text
                    Toggle.Visible = Config.Visible

                    table.insert(Toggles, Toggle)
                    table.insert(SubTab.Elements, Toggle)

                    function Toggle:SetValue(Value: boolean, Callback: boolean?)
                        if Toggle.Value == Value then
                            return
                        end

                        Toggle.Value = Value
                        ToggleInner.Visible = Value

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Toggle)
                        end
                        Library:SafeCallback(Config.Changed, Value, Toggle)
                    end

                    function Toggle:GetValue()
                        return Toggle.Value
                    end

                    function Toggle:SetText(Text: string)
                        Toggle.Text = Text
                        ToggleText.Text = Text
                    end

                    function Toggle:SetVisible(Visible: boolean)
                        Toggle.Visible = Visible
                        ToggleHolder.Visible = Visible
                    end

                    ToggleButton.MouseButton1Click:Connect(function()
                        Toggle:SetValue(not Toggle.Value, true)
                    end)

                    return Toggle
                end

                function SubTab:AddSlider(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Slider)

                    local Slider = {}
                    Slider.Type = "Slider"
                    Slider.Value = Config.Default

                    local SliderHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 50),
                        Parent = SubTabHolder,
                    })

                    local SliderText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = Config.Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix,
                        TextSize = 14,
                        Parent = SliderHolder,
                    })

                    local SliderBar = New("Frame", {
                        AnchorPoint = Vector2.new(0, 1),
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 50),
                        Size = UDim2.new(1, 0, 0, 4),
                        Parent = SliderHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 2),
                        Parent = SliderBar,
                    })

                    local SliderFill = New("Frame", {
                        BackgroundColor3 = "AccentColor",
                        Size = UDim2.fromScale((Slider.Value - Config.Min) / (Config.Max - Config.Min), 1),
                        Parent = SliderBar,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 2),
                        Parent = SliderFill,
                    })

                    local SliderButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = SliderHolder,
                    })

                    Slider.Holder = SliderHolder
                    Slider.Text = Config.Text
                    Slider.Visible = Config.Visible

                    table.insert(Options, Slider)
                    table.insert(SubTab.Elements, Slider)

                    function Slider:SetValue(Value: number, Callback: boolean?)
                        Value = math.clamp(Value, Config.Min, Config.Max)
                        if Slider.Value == Value then
                            return
                        end

                        Slider.Value = Value
                        SliderFill.Size = UDim2.fromScale((Value - Config.Min) / (Config.Max - Config.Min), 1)
                        SliderText.Text = Config.Text .. ": " .. Config.Suffix .. Round(Value, Config.Rounding) .. Config.Suffix

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Slider)
                        end
                        Library:SafeCallback(Config.Changed, Value, Slider)
                    end

                    function Slider:GetValue()
                        return Slider.Value
                    end

                    function Slider:SetText(Text: string)
                        Slider.Text = Text
                        SliderText.Text = Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix
                    end

                    function Slider:SetVisible(Visible: boolean)
                        Slider.Visible = Visible
                        SliderHolder.Visible = Visible
                    end

                    local Dragging = false
                    SliderButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            Dragging = true
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = false
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(Input)
                        if Dragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = SliderBar.AbsolutePosition
                            local BarSize = SliderBar.AbsoluteSize

                            local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                            local Value = Config.Min + (Config.Max - Config.Min) * Percent

                            Slider:SetValue(Round(Value, Config.Rounding), true)
                        end
                    end)

                    return Slider
                end

                function SubTab:AddTextbox(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Input)

                    local Textbox = {}
                    Textbox.Type = "Textbox"
                    Textbox.Value = Config.Default

                    local TextboxHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 50),
                        Parent = SubTabHolder,
                    })

                    local TextboxText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Text = Config.Text,
                        TextSize = 14,
                        Parent = TextboxHolder,
                    })

                    local TextboxBox = New("TextBox", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 20),
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = Config.Default,
                        PlaceholderText = Config.Placeholder,
                        Parent = TextboxHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = TextboxBox,
                    })

                    Textbox.Holder = TextboxHolder
                    Textbox.Text = Config.Text
                    Textbox.Visible = Config.Visible

                    table.insert(Options, Textbox)
                    table.insert(SubTab.Elements, Textbox)

                    function Textbox:SetValue(Value: string, Callback: boolean?)
                        if Textbox.Value == Value then
                            return
                        end

                        Textbox.Value = Value
                        TextboxBox.Text = Value

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Textbox)
                        end
                        Library:SafeCallback(Config.Changed, Value, Textbox)
                    end

                    function Textbox:GetValue()
                        return Textbox.Value
                    end

                    function Textbox:SetText(Text: string)
                        Textbox.Text = Text
                        TextboxText.Text = Text
                    end

                    function Textbox:SetVisible(Visible: boolean)
                        Textbox.Visible = Visible
                        TextboxHolder.Visible = Visible
                    end

                    TextboxBox.FocusLost:Connect(function(EnterPressed)
                        if Config.Numeric then
                            local Value = tonumber(TextboxBox.Text)
                            if Value then
                                Textbox:SetValue(tostring(Value), true)
                            else
                                TextboxBox.Text = Textbox.Value
                            end
                        else
                            Textbox:SetValue(TextboxBox.Text, true)
                        end
                    end)

                    return Textbox
                end

                function SubTab:AddDropdown(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.Dropdown)

                    local Dropdown = {}
                    Dropdown.Type = "Dropdown"
                    Dropdown.Value = Config.Multi and {} or Config.Values[1]
                    Dropdown.Open = false

                    local DropdownHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = SubTabHolder,
                    })

                    local DropdownButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = "",
                        Parent = DropdownHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = DropdownButton,
                    })

                    local DropdownText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -24, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = DropdownButton,
                    })

                    local DropdownArrow = New("ImageLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(12, 12),
                        Image = Library:GetIcon("chevron-down").Url,
                        Parent = DropdownButton,
                    })

                    local DropdownList = New("Frame", {
                        BackgroundColor3 = "MainColor",
                        Position = UDim2.fromOffset(0, 30),
                        Size = UDim2.new(1, 0, 0, 0),
                        Visible = false,
                        ZIndex = 10,
                        Parent = DropdownHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = DropdownList,
                    })

                    local DropdownPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = DropdownList,
                    })

                    local DropdownContainer = New("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        ScrollBarThickness = 0,
                        Parent = DropdownList,
                    })

                    local DropdownListLayout = New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = DropdownContainer,
                    })

                    Dropdown.Holder = DropdownHolder
                    Dropdown.Text = Config.Text
                    Dropdown.Visible = Config.Visible

                    table.insert(Options, Dropdown)
                    table.insert(SubTab.Elements, Dropdown)

                    function Dropdown:RecalculateListSize()
                        local ListSize = 0
                        for _, Option in pairs(DropdownContainer:GetChildren()) do
                            if Option:IsA("TextButton") then
                                ListSize += Option.AbsoluteSize.Y + 2
                            end
                        end

                        DropdownList.Size = UDim2.new(1, 0, 0, math.min(ListSize, Config.MaxVisibleDropdownItems * 24))
                        DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, ListSize)
                    end

                    function Dropdown:SetValue(Value: any, Callback: boolean?)
                        if Config.Multi then
                            if type(Value) ~= "table" then
                                return
                            end

                            local NewValue = {}
                            for _, V in pairs(Value) do
                                if table.find(Config.Values, V) then
                                    table.insert(NewValue, V)
                                end
                            end

                            if #NewValue == #Dropdown.Value then
                                local Same = true
                                for _, V in pairs(NewValue) do
                                    if not table.find(Dropdown.Value, V) then
                                        Same = false
                                        break
                                    end
                                end

                                if Same then
                                    return
                                end
                            end

                            Dropdown.Value = NewValue
                            DropdownText.Text = #NewValue > 0 and table.concat(NewValue, ", ") or Config.Text

                            if Callback then
                                Library:SafeCallback(Config.Callback, NewValue, Dropdown)
                            end
                            Library:SafeCallback(Config.Changed, NewValue, Dropdown)
                        else
                            if not table.find(Config.Values, Value) then
                                return
                            end

                            if Dropdown.Value == Value then
                                return
                            end

                            Dropdown.Value = Value
                            DropdownText.Text = Value

                            if Callback then
                                Library:SafeCallback(Config.Callback, Value, Dropdown)
                            end
                            Library:SafeCallback(Config.Changed, Value, Dropdown)
                        end
                    end

                    function Dropdown:GetValue()
                        return Dropdown.Value
                    end

                    function Dropdown:SetText(Text: string)
                        Dropdown.Text = Text
                        if not Config.Multi or #Dropdown.Value == 0 then
                            DropdownText.Text = Text
                        end
                    end

                    function Dropdown:SetVisible(Visible: boolean)
                        Dropdown.Visible = Visible
                        DropdownHolder.Visible = Visible
                    end

                    function Dropdown:Open()
                        if Dropdown.Open then
                            return
                        end

                        Dropdown.Open = true
                        DropdownList.Visible = true
                        DropdownArrow.Rotation = 180
                    end

                    function Dropdown:Close()
                        if not Dropdown.Open then
                            return
                        end

                        Dropdown.Open = false
                        DropdownList.Visible = false
                        DropdownArrow.Rotation = 0
                    end

                    function Dropdown:Toggle()
                        if Dropdown.Open then
                            Dropdown:Close()
                        else
                            Dropdown:Open()
                        end
                    end

                    for _, Value in pairs(Config.Values) do
                        local OptionButton = New("TextButton", {
                            BackgroundColor3 = "BackgroundColor",
                            Size = UDim2.new(1, 0, 0, 24),
                            Text = Value,
                            TextSize = 14,
                            Parent = DropdownContainer,
                        })
                        New("UICorner", {
                            CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                            Parent = OptionButton,
                        })

                        if Config.Multi then
                            local OptionTick = New("ImageLabel", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(1, -8, 0.5, 0),
                                Size = UDim2.fromOffset(12, 12),
                                Image = Library:GetIcon("check").Url,
                                Visible = false,
                                Parent = OptionButton,
                            })

                            if table.find(Dropdown.Value, Value) then
                                OptionTick.Visible = true
                            end

                            OptionButton.MouseButton1Click:Connect(function()
                                local NewValue = {}
                                for _, V in pairs(Dropdown.Value) do
                                    table.insert(NewValue, V)
                                end

                                if table.find(NewValue, Value) then
                                    table.remove(NewValue, table.find(NewValue, Value))
                                    OptionTick.Visible = false
                                else
                                    table.insert(NewValue, Value)
                                    OptionTick.Visible = true
                                end

                                Dropdown:SetValue(NewValue, true)
                            end)
                        else
                            OptionButton.MouseButton1Click:Connect(function()
                                Dropdown:SetValue(Value, true)
                                Dropdown:Close()
                            end)
                        end
                    end

                    Dropdown:RecalculateListSize()

                    DropdownButton.MouseButton1Click:Connect(function()
                        Dropdown:Toggle()
                    end)

                    UserInputService.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Open then
                            local MousePos = UserInputService:GetMouseLocation()
                            local AbsPos, AbsSize = DropdownList.AbsolutePosition, DropdownList.AbsoluteSize

                            if
                                MousePos.X < AbsPos.X
                                or MousePos.X > AbsPos.X + AbsSize.X
                                or MousePos.Y < AbsPos.Y
                                or MousePos.Y > AbsPos.Y + AbsSize.Y
                            then
                                Dropdown:Close()
                            end
                        end
                    end)

                    return Dropdown
                end

                function SubTab:AddKeyPicker(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.KeyPicker)

                    local KeyPicker = {}
                    KeyPicker.Type = "KeyPicker"
                    KeyPicker.Value = Config.Default
                    KeyPicker.Modifiers = Config.DefaultModifiers
                    KeyPicker.Picking = false

                    local KeyPickerHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = SubTabHolder,
                    })

                    local KeyPickerButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = "",
                        Parent = KeyPickerHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = KeyPickerButton,
                    })

                    local KeyPickerText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -24, 1, 0),
                        Text = Config.Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value)),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = KeyPickerButton,
                    })

                    local KeyPickerReset = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(16, 16),
                        Text = "×",
                        TextSize = 20,
                        Parent = KeyPickerButton,
                    })

                    KeyPicker.Holder = KeyPickerHolder
                    KeyPicker.Text = Config.Text
                    KeyPicker.Visible = Config.Visible

                    table.insert(Options, KeyPicker)
                    table.insert(SubTab.Elements, KeyPicker)

                    function KeyPicker:SetValue(Value: Enum.KeyCode, Callback: boolean?)
                        if KeyPicker.Value == Value then
                            return
                        end

                        KeyPicker.Value = Value
                        KeyPickerText.Text = Config.Text .. ": " .. (Value == "None" and "None" or Library:GetKeyString(Value))

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, KeyPicker)
                        end
                        Library:SafeCallback(Config.Changed, Value, KeyPicker)
                    end

                    function KeyPicker:GetValue()
                        return KeyPicker.Value
                    end

                    function KeyPicker:SetText(Text: string)
                        KeyPicker.Text = Text
                        KeyPickerText.Text = Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value))
                    end

                    function KeyPicker:SetVisible(Visible: boolean)
                        KeyPicker.Visible = Visible
                        KeyPickerHolder.Visible = Visible
                    end

                    KeyPickerButton.MouseButton1Click:Connect(function()
                        KeyPicker.Picking = true
                        KeyPickerText.Text = Config.Text .. ": ..."
                    end)

                    KeyPickerReset.MouseButton1Click:Connect(function()
                        KeyPicker:SetValue("None", true)
                    end)

                    UserInputService.InputBegan:Connect(function(Input)
                        if KeyPicker.Picking then
                            KeyPicker.Picking = false

                            if Input.UserInputType == Enum.UserInputType.Keyboard then
                                KeyPicker:SetValue(Input.KeyCode, true)
                            elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                KeyPicker:SetValue(Enum.KeyCode.MouseButton1, true)
                            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                                KeyPicker:SetValue(Enum.KeyCode.MouseButton2, true)
                            end
                        end
                    end)

                    return KeyPicker
                end

                function SubTab:AddColorPicker(Config: { [string]: any })
                    Config = Library:Validate(Config, Templates.ColorPicker)

                    local ColorPicker = {}
                    ColorPicker.Type = "ColorPicker"
                    ColorPicker.Value = Config.Default
                    ColorPicker.Open = false

                    local ColorPickerHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = SubTabHolder,
                    })

                    local ColorPickerButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = "",
                        Parent = ColorPickerHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerButton,
                    })

                    local ColorPickerText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -40, 1, 0),
                        Text = Config.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = ColorPickerButton,
                    })

                    local ColorPickerPreview = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = ColorPicker.Value,
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(24, 24),
                        Parent = ColorPickerButton,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerPreview,
                    })

                    local ColorPickerList = New("Frame", {
                        BackgroundColor3 = "MainColor",
                        Position = UDim2.fromOffset(0, 30),
                        Size = UDim2.new(1, 0, 0, 0),
                        Visible = false,
                        ZIndex = 10,
                        Parent = ColorPickerHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerList,
                    })

                    local ColorPickerPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = ColorPickerList,
                    })

                    local ColorPickerContainer = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Parent = ColorPickerList,
                    })

                    local ColorPickerHue = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 0),
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerHue,
                    })

                    local ColorPickerHueImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://4155801252",
                        Parent = ColorPickerHue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerHueImage,
                    })

                    local ColorPickerHueButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ColorPickerHue,
                    })

                    local ColorPickerHueSelector = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "White",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Parent = ColorPickerHue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ColorPickerHueSelector,
                    })

                    local ColorPickerSaturation = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 24),
                        Size = UDim2.new(1, 0, 0, 100),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerSaturation,
                    })

                    local ColorPickerSaturationImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://4155801252",
                        Parent = ColorPickerSaturation,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerSaturationImage,
                    })

                    local ColorPickerSaturationButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ColorPickerSaturation,
                    })

                    local ColorPickerSaturationSelector = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "White",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Parent = ColorPickerSaturation,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ColorPickerSaturationSelector,
                    })

                    local ColorPickerValue = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 128),
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerValue,
                    })

                    local ColorPickerValueImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://4155801252",
                        Parent = ColorPickerValue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerValueImage,
                    })

                    local ColorPickerValueButton = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = ColorPickerValue,
                    })

                    local ColorPickerValueSelector = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "White",
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(8, 8),
                        Parent = ColorPickerValue,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = ColorPickerValueSelector,
                    })

                    local ColorPickerHex = New("TextBox", {
                        AnchorPoint = Vector2.new(0, 1),
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(0, 152),
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = "#" .. ColorPicker.Value:ToHex(),
                        Parent = ColorPickerContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = ColorPickerHex,
                    })

                    ColorPickerList.Size = UDim2.new(1, 0, 0, 176)

                    ColorPicker.Holder = ColorPickerHolder
                    ColorPicker.Text = Config.Text
                    ColorPicker.Visible = Config.Visible

                    table.insert(Options, ColorPicker)
                    table.insert(SubTab.Elements, ColorPicker)

                    function ColorPicker:SetValue(Value: Color3, Callback: boolean?)
                        if ColorPicker.Value == Value then
                            return
                        end

                        ColorPicker.Value = Value
                        ColorPickerPreview.BackgroundColor3 = Value
                        ColorPickerHex.Text = "#" .. Value:ToHex()

                        local H, S, V = Value:ToHSV()
                        ColorPickerHueSelector.Position = UDim2.fromScale(H, 0.5)
                        ColorPickerSaturationSelector.Position = UDim2.fromScale(S, 1 - V)
                        ColorPickerValueSelector.Position = UDim2.fromScale(0.5, 1 - V)

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, ColorPicker)
                        end
                        Library:SafeCallback(Config.Changed, Value, ColorPicker)
                    end

                    function ColorPicker:GetValue()
                        return ColorPicker.Value
                    end

                    function ColorPicker:SetText(Text: string)
                        ColorPicker.Text = Text
                        ColorPickerText.Text = Text
                    end

                    function ColorPicker:SetVisible(Visible: boolean)
                        ColorPicker.Visible = Visible
                        ColorPickerHolder.Visible = Visible
                    end

                    function ColorPicker:Open()
                        if ColorPicker.Open then
                            return
                        end

                        ColorPicker.Open = true
                        ColorPickerList.Visible = true
                    end

                    function ColorPicker:Close()
                        if not ColorPicker.Open then
                            return
                        end

                        ColorPicker.Open = false
                        ColorPickerList.Visible = false
                    end

                    function ColorPicker:Toggle()
                        if ColorPicker.Open then
                            ColorPicker:Close()
                        else
                            ColorPicker:Open()
                        end
                    end

                    local function UpdateFromHue()
                        local H = (ColorPickerHueSelector.AbsolutePosition.X - ColorPickerHue.AbsolutePosition.X) / ColorPickerHue.AbsoluteSize.X
                        local S, V = ColorPicker.Value:ToHSV()
                        ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                    end

                    local function UpdateFromSaturation()
                        local S = (ColorPickerSaturationSelector.AbsolutePosition.X - ColorPickerSaturation.AbsolutePosition.X) / ColorPickerSaturation.AbsoluteSize.X
                        local V = 1 - (ColorPickerSaturationSelector.AbsolutePosition.Y - ColorPickerSaturation.AbsolutePosition.Y) / ColorPickerSaturation.AbsoluteSize.Y
                        local H = ColorPicker.Value:ToHSV()
                        ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                    end

                    local function UpdateFromValue()
                        local V = 1 - (ColorPickerValueSelector.AbsolutePosition.Y - ColorPickerValue.AbsolutePosition.Y) / ColorPickerValue.AbsoluteSize.Y
                        local H, S = ColorPicker.Value:ToHSV()
                        ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                    end

                    local function UpdateFromHex()
                        local Hex = ColorPickerHex.Text:match("#(%x%x%x%x%x%x)")
                        if Hex then
                            local R = tonumber(Hex:sub(1, 2), 16) / 255
                            local G = tonumber(Hex:sub(3, 4), 16) / 255
                            local B = tonumber(Hex:sub(5, 6), 16) / 255
                            ColorPicker:SetValue(Color3.new(R, G, B), true)
                        else
                            ColorPickerHex.Text = "#" .. ColorPicker.Value:ToHex()
                        end
                    end

                    local HueDragging = false
                    ColorPickerHueButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            HueDragging = true
                            UpdateFromHue()
                        end
                    end)

                    local SaturationDragging = false
                    ColorPickerSaturationButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            SaturationDragging = true
                            UpdateFromSaturation()
                        end
                    end)

                    local ValueDragging = false
                    ColorPickerValueButton.InputBegan:Connect(function(Input)
                        if IsClickInput(Input) then
                            ValueDragging = true
                            UpdateFromValue()
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(Input)
                        if HueDragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = ColorPickerHue.AbsolutePosition
                            local BarSize = ColorPickerHue.AbsoluteSize

                            local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                            ColorPickerHueSelector.Position = UDim2.fromScale(Percent, 0.5)
                            UpdateFromHue()
                        elseif SaturationDragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = ColorPickerSaturation.AbsolutePosition
                            local BarSize = ColorPickerSaturation.AbsoluteSize

                            local PercentX = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                            local PercentY = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                            ColorPickerSaturationSelector.Position = UDim2.fromScale(PercentX, PercentY)
                            UpdateFromSaturation()
                        elseif ValueDragging and IsHoverInput(Input) then
                            local MousePos = UserInputService:GetMouseLocation()
                            local BarPos = ColorPickerValue.AbsolutePosition
                            local BarSize = ColorPickerValue.AbsoluteSize

                            local Percent = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                            ColorPickerValueSelector.Position = UDim2.fromScale(0.5, Percent)
                            UpdateFromValue()
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            HueDragging = false
                            SaturationDragging = false
                            ValueDragging = false
                        end
                    end)

                    ColorPickerHex.FocusLost:Connect(function()
                        UpdateFromHex()
                    end)

                    ColorPickerButton.MouseButton1Click:Connect(function()
                        ColorPicker:Toggle()
                    end)

                    UserInputService.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 and ColorPicker.Open then
                            local MousePos = UserInputService:GetMouseLocation()
                            local AbsPos, AbsSize = ColorPickerList.AbsolutePosition, ColorPickerList.AbsoluteSize

                            if
                                MousePos.X < AbsPos.X
                                or MousePos.X > AbsPos.X + AbsSize.X
                                or MousePos.Y < AbsPos.Y
                                or MousePos.Y > AbsPos.Y + AbsSize.Y
                            then
                                ColorPicker:Close()
                            end
                        end
                    end)

                    return ColorPicker
                end

                function SubTab:AddDivider()
                    local Divider = {}
                    Divider.Type = "Divider"

                    local DividerHolder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 8),
                        Parent = SubTabHolder,
                    })

                    local DividerLine = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "OutlineColor",
                        Position = UDim2.fromOffset(0, 4),
                        Size = UDim2.new(1, 0, 0, 1),
                        Parent = DividerHolder,
                    })

                    Divider.Holder = DividerHolder
                    Divider.Visible = true

                    table.insert(SubTab.Elements, Divider)

                    function Divider:SetVisible(Visible: boolean)
                        Divider.Visible = Visible
                        DividerHolder.Visible = Visible
                    end

                    return Divider
                end

                function SubTab:Resize()
                    local ContentSize = 0
                    for _, Element in pairs(SubTab.Elements) do
                        if Element.Visible then
                            ContentSize += Element.Holder.AbsoluteSize.Y + 4
                        end
                    end

                    SubTabHolder.Size = UDim2.new(1, 0, 0, ContentSize)
                end

                function SubTab:Show()
                    if Tabbox.ActiveTab == SubTab then
                        return
                    end

                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab.Button.BackgroundColor3 = Library.Scheme.BackgroundColor
                        Tabbox.ActiveTab.Holder.Visible = false
                    end

                    Tabbox.ActiveTab = SubTab
                    SubTab.Button.BackgroundColor3 = Library.Scheme.AccentColor
                    SubTab.Holder.Visible = true

                    SubTab:Resize()
                end

                SubTabButton.MouseButton1Click:Connect(function()
                    SubTab:Show()
                end)

                table.insert(Tabbox.Tabs, SubTab)
                table.insert(SubTab.Elements, SubTab)

                if #Tabbox.Tabs == 1 then
                    SubTab:Show()
                end

                return SubTab
            end

            Tabbox:Resize()
            table.insert(Window.Tabboxes, Tabbox)

            return Tabbox
        end

        function Tab:CreateDependencyBox(Toggle: any)
            local Depbox = {}
            Depbox.Type = "DependencyBox"
            Depbox.Toggle = Toggle
            Depbox.Elements = {}
            Depbox.DependencyBoxes = {}

            local DepboxHolder = New("Frame", {
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = TabHolder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                Parent = DepboxHolder,
            })

            local DepboxPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 6),
                Parent = DepboxHolder,
            })

            local DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = DepboxHolder,
            })

            Depbox.Holder = DepboxHolder
            Depbox.Visible = false

            table.insert(Window.DependencyGroupboxes, Depbox)

            function Depbox:AddLabel(Config: { [string]: any })
                Config = Library:Validate(Config, {
                    Text = "Label",
                    Visible = true,
                })

                local Label = {}
                Label.Type = "Label"

                local LabelHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = DepboxHolder,
                })

                local LabelText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    Parent = LabelHolder,
                })

                Label.Holder = LabelHolder
                Label.Text = Config.Text
                Label.Visible = Config.Visible

                table.insert(Labels, Label)
                table.insert(Depbox.Elements, Label)

                function Label:SetText(Text: string)
                    Label.Text = Text
                    LabelText.Text = Text
                end

                function Label:SetVisible(Visible: boolean)
                    Label.Visible = Visible
                    LabelHolder.Visible = Visible
                end

                return Label
            end

            function Depbox:AddButton(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Button)

                local Button = {}
                Button.Type = "Button"

                local ButtonHolder = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 28),
                    Text = "",
                    Parent = DepboxHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ButtonHolder,
                })

                local ButtonText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    Parent = ButtonHolder,
                })

                Button.Holder = ButtonHolder
                Button.Text = Config.Text
                Button.Visible = Config.Visible

                table.insert(Buttons, Button)
                table.insert(Depbox.Elements, Button)

                ButtonHolder.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Config.Callback, Button)
                end)

                function Button:SetText(Text: string)
                    Button.Text = Text
                    ButtonText.Text = Text
                end

                function Button:SetVisible(Visible: boolean)
                    Button.Visible = Visible
                    ButtonHolder.Visible = Visible
                end

                return Button
            end

            function Depbox:AddToggle(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Toggle)

                local Toggle = {}
                Toggle.Type = "Toggle"
                Toggle.Value = Config.Default

                local ToggleHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = DepboxHolder,
                })

                local ToggleButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ToggleHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ToggleButton,
                })

                local ToggleText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(28, 0),
                    Size = UDim2.new(1, -28, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleButton,
                })

                local ToggleOuter = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(8, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = ToggleButton,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = ToggleOuter,
                })

                local ToggleInner = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "AccentColor",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Visible = Toggle.Value,
                    Parent = ToggleOuter,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ToggleInner,
                })

                Toggle.Holder = ToggleHolder
                Toggle.Text = Config.Text
                Toggle.Visible = Config.Visible

                table.insert(Toggles, Toggle)
                table.insert(Depbox.Elements, Toggle)

                function Toggle:SetValue(Value: boolean, Callback: boolean?)
                    if Toggle.Value == Value then
                        return
                    end

                    Toggle.Value = Value
                    ToggleInner.Visible = Value

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, Toggle)
                    end
                    Library:SafeCallback(Config.Changed, Value, Toggle)
                end

                function Toggle:GetValue()
                    return Toggle.Value
                end

                function Toggle:SetText(Text: string)
                    Toggle.Text = Text
                    ToggleText.Text = Text
                end

                function Toggle:SetVisible(Visible: boolean)
                    Toggle.Visible = Visible
                    ToggleHolder.Visible = Visible
                end

                ToggleButton.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value, true)
                end)

                return Toggle
            end

            function Depbox:AddSlider(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Slider)

                local Slider = {}
                Slider.Type = "Slider"
                Slider.Value = Config.Default

                local SliderHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = DepboxHolder,
                })

                local SliderText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = Config.Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix,
                    TextSize = 14,
                    Parent = SliderHolder,
                })

                local SliderBar = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 50),
                    Size = UDim2.new(1, 0, 0, 4),
                    Parent = SliderHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 2),
                    Parent = SliderBar,
                })

                local SliderFill = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    Size = UDim2.fromScale((Slider.Value - Config.Min) / (Config.Max - Config.Min), 1),
                    Parent = SliderBar,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 2),
                    Parent = SliderFill,
                })

                local SliderButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = SliderHolder,
                })

                Slider.Holder = SliderHolder
                Slider.Text = Config.Text
                Slider.Visible = Config.Visible

                table.insert(Options, Slider)
                table.insert(Depbox.Elements, Slider)

                function Slider:SetValue(Value: number, Callback: boolean?)
                    Value = math.clamp(Value, Config.Min, Config.Max)
                    if Slider.Value == Value then
                        return
                    end

                    Slider.Value = Value
                    SliderFill.Size = UDim2.fromScale((Value - Config.Min) / (Config.Max - Config.Min), 1)
                    SliderText.Text = Config.Text .. ": " .. Config.Suffix .. Round(Value, Config.Rounding) .. Config.Suffix

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, Slider)
                    end
                    Library:SafeCallback(Config.Changed, Value, Slider)
                end

                function Slider:GetValue()
                    return Slider.Value
                end

                function Slider:SetText(Text: string)
                    Slider.Text = Text
                    SliderText.Text = Text .. ": " .. Config.Suffix .. Round(Slider.Value, Config.Rounding) .. Config.Suffix
                end

                function Slider:SetVisible(Visible: boolean)
                    Slider.Visible = Visible
                    SliderHolder.Visible = Visible
                end

                local Dragging = false
                SliderButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        Dragging = true
                    end
                end)

                UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = SliderBar.AbsolutePosition
                        local BarSize = SliderBar.AbsoluteSize

                        local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                        local Value = Config.Min + (Config.Max - Config.Min) * Percent

                        Slider:SetValue(Round(Value, Config.Rounding), true)
                    end
                end)

                return Slider
            end

            function Depbox:AddTextbox(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Input)

                local Textbox = {}
                Textbox.Type = "Textbox"
                Textbox.Value = Config.Default

                local TextboxHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = DepboxHolder,
                })

                local TextboxText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = Config.Text,
                    TextSize = 14,
                    Parent = TextboxHolder,
                })

                local TextboxBox = New("TextBox", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, 24),
                    Text = Config.Default,
                    PlaceholderText = Config.Placeholder,
                    Parent = TextboxHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = TextboxBox,
                })

                Textbox.Holder = TextboxHolder
                Textbox.Text = Config.Text
                Textbox.Visible = Config.Visible

                table.insert(Options, Textbox)
                table.insert(Depbox.Elements, Textbox)

                function Textbox:SetValue(Value: string, Callback: boolean?)
                    if Textbox.Value == Value then
                        return
                    end

                    Textbox.Value = Value
                    TextboxBox.Text = Value

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, Textbox)
                    end
                    Library:SafeCallback(Config.Changed, Value, Textbox)
                end

                function Textbox:GetValue()
                    return Textbox.Value
                end

                function Textbox:SetText(Text: string)
                    Textbox.Text = Text
                    TextboxText.Text = Text
                end

                function Textbox:SetVisible(Visible: boolean)
                    Textbox.Visible = Visible
                    TextboxHolder.Visible = Visible
                end

                TextboxBox.FocusLost:Connect(function(EnterPressed)
                    if Config.Numeric then
                        local Value = tonumber(TextboxBox.Text)
                        if Value then
                            Textbox:SetValue(tostring(Value), true)
                        else
                            TextboxBox.Text = Textbox.Value
                        end
                    else
                        Textbox:SetValue(TextboxBox.Text, true)
                    end
                end)

                return Textbox
            end

            function Depbox:AddDropdown(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.Dropdown)

                local Dropdown = {}
                Dropdown.Type = "Dropdown"
                Dropdown.Value = Config.Multi and {} or Config.Values[1]
                Dropdown.Open = false

                local DropdownHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = DepboxHolder,
                })

                local DropdownButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    Parent = DropdownHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = DropdownButton,
                })

                local DropdownText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -24, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = DropdownButton,
                })

                local DropdownArrow = New("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    Image = Library:GetIcon("chevron-down").Url,
                    Parent = DropdownButton,
                })

                local DropdownList = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromOffset(0, 30),
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ZIndex = 10,
                    Parent = DropdownHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = DropdownList,
                })

                local DropdownPadding = New("UIPadding", {
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    PaddingTop = UDim.new(0, 4),
                    Parent = DropdownList,
                })

                local DropdownContainer = New("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 0,
                    Parent = DropdownList,
                })

                local DropdownListLayout = New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = DropdownContainer,
                })

                Dropdown.Holder = DropdownHolder
                Dropdown.Text = Config.Text
                Dropdown.Visible = Config.Visible

                table.insert(Options, Dropdown)
                table.insert(Depbox.Elements, Dropdown)

                function Dropdown:RecalculateListSize()
                    local ListSize = 0
                    for _, Option in pairs(DropdownContainer:GetChildren()) do
                        if Option:IsA("TextButton") then
                            ListSize += Option.AbsoluteSize.Y + 2
                        end
                    end

                    DropdownList.Size = UDim2.new(1, 0, 0, math.min(ListSize, Config.MaxVisibleDropdownItems * 24))
                    DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, ListSize)
                end

                function Dropdown:SetValue(Value: any, Callback: boolean?)
                    if Config.Multi then
                        if type(Value) ~= "table" then
                            return
                        end

                        local NewValue = {}
                        for _, V in pairs(Value) do
                            if table.find(Config.Values, V) then
                                table.insert(NewValue, V)
                            end
                        end

                        if #NewValue == #Dropdown.Value then
                            local Same = true
                            for _, V in pairs(NewValue) do
                                if not table.find(Dropdown.Value, V) then
                                    Same = false
                                    break
                                end
                            end

                            if Same then
                                return
                            end
                        end

                        Dropdown.Value = NewValue
                        DropdownText.Text = #NewValue > 0 and table.concat(NewValue, ", ") or Config.Text

                        if Callback then
                            Library:SafeCallback(Config.Callback, NewValue, Dropdown)
                        end
                        Library:SafeCallback(Config.Changed, NewValue, Dropdown)
                    else
                        if not table.find(Config.Values, Value) then
                            return
                        end

                        if Dropdown.Value == Value then
                            return
                        end

                        Dropdown.Value = Value
                        DropdownText.Text = Value

                        if Callback then
                            Library:SafeCallback(Config.Callback, Value, Dropdown)
                        end
                        Library:SafeCallback(Config.Changed, Value, Dropdown)
                    end
                end

                function Dropdown:GetValue()
                    return Dropdown.Value
                end

                function Dropdown:SetText(Text: string)
                    Dropdown.Text = Text
                    if not Config.Multi or #Dropdown.Value == 0 then
                        DropdownText.Text = Text
                    end
                end

                function Dropdown:SetVisible(Visible: boolean)
                    Dropdown.Visible = Visible
                    DropdownHolder.Visible = Visible
                end

                function Dropdown:Open()
                    if Dropdown.Open then
                        return
                    end

                    Dropdown.Open = true
                    DropdownList.Visible = true
                    DropdownArrow.Rotation = 180
                end

                function Dropdown:Close()
                    if not Dropdown.Open then
                        return
                    end

                    Dropdown.Open = false
                    DropdownList.Visible = false
                    DropdownArrow.Rotation = 0
                end

                function Dropdown:Toggle()
                    if Dropdown.Open then
                        Dropdown:Close()
                    else
                        Dropdown:Open()
                    end
                end

                for _, Value in pairs(Config.Values) do
                    local OptionButton = New("TextButton", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = Value,
                        TextSize = 14,
                        Parent = DropdownContainer,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                        Parent = OptionButton,
                    })

                    if Config.Multi then
                        local OptionTick = New("ImageLabel", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -8, 0.5, 0),
                            Size = UDim2.fromOffset(12, 12),
                            Image = Library:GetIcon("check").Url,
                            Visible = false,
                            Parent = OptionButton,
                        })

                        if table.find(Dropdown.Value, Value) then
                            OptionTick.Visible = true
                        end

                        OptionButton.MouseButton1Click:Connect(function()
                            local NewValue = {}
                            for _, V in pairs(Dropdown.Value) do
                                table.insert(NewValue, V)
                            end

                            if table.find(NewValue, Value) then
                                table.remove(NewValue, table.find(NewValue, Value))
                                OptionTick.Visible = false
                            else
                                table.insert(NewValue, Value)
                                OptionTick.Visible = true
                            end

                            Dropdown:SetValue(NewValue, true)
                        end)
                    else
                        OptionButton.MouseButton1Click:Connect(function()
                            Dropdown:SetValue(Value, true)
                            Dropdown:Close()
                        end)
                    end
                end

                Dropdown:RecalculateListSize()

                DropdownButton.MouseButton1Click:Connect(function()
                    Dropdown:Toggle()
                end)

                UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Open then
                        local MousePos = UserInputService:GetMouseLocation()
                        local AbsPos, AbsSize = DropdownList.AbsolutePosition, DropdownList.AbsoluteSize

                        if
                            MousePos.X < AbsPos.X
                            or MousePos.X > AbsPos.X + AbsSize.X
                            or MousePos.Y < AbsPos.Y
                            or MousePos.Y > AbsPos.Y + AbsSize.Y
                        then
                            Dropdown:Close()
                        end
                    end
                end)

                return Dropdown
            end

            function Depbox:AddKeyPicker(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.KeyPicker)

                local KeyPicker = {}
                KeyPicker.Type = "KeyPicker"
                KeyPicker.Value = Config.Default
                KeyPicker.Modifiers = Config.DefaultModifiers
                KeyPicker.Picking = false

                local KeyPickerHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = DepboxHolder,
                })

                local KeyPickerButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    Parent = KeyPickerHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = KeyPickerButton,
                })

                local KeyPickerText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -24, 1, 0),
                    Text = Config.Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value)),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = KeyPickerButton,
                })

                local KeyPickerReset = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    Text = "×",
                    TextSize = 20,
                    Parent = KeyPickerButton,
                })

                KeyPicker.Holder = KeyPickerHolder
                KeyPicker.Text = Config.Text
                KeyPicker.Visible = Config.Visible

                table.insert(Options, KeyPicker)
                table.insert(Depbox.Elements, KeyPicker)

                function KeyPicker:SetValue(Value: Enum.KeyCode, Callback: boolean?)
                    if KeyPicker.Value == Value then
                        return
                    end

                    KeyPicker.Value = Value
                    KeyPickerText.Text = Config.Text .. ": " .. (Value == "None" and "None" or Library:GetKeyString(Value))

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, KeyPicker)
                    end
                    Library:SafeCallback(Config.Changed, Value, KeyPicker)
                end

                function KeyPicker:GetValue()
                    return KeyPicker.Value
                end

                function KeyPicker:SetText(Text: string)
                    KeyPicker.Text = Text
                    KeyPickerText.Text = Text .. ": " .. (KeyPicker.Value == "None" and "None" or Library:GetKeyString(KeyPicker.Value))
                end

                function KeyPicker:SetVisible(Visible: boolean)
                    KeyPicker.Visible = Visible
                    KeyPickerHolder.Visible = Visible
                end

                KeyPickerButton.MouseButton1Click:Connect(function()
                    KeyPicker.Picking = true
                    KeyPickerText.Text = Config.Text .. ": ..."
                end)

                KeyPickerReset.MouseButton1Click:Connect(function()
                    KeyPicker:SetValue("None", true)
                end)

                UserInputService.InputBegan:Connect(function(Input)
                    if KeyPicker.Picking then
                        KeyPicker.Picking = false

                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            KeyPicker:SetValue(Input.KeyCode, true)
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            KeyPicker:SetValue(Enum.KeyCode.MouseButton1, true)
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker:SetValue(Enum.KeyCode.MouseButton2, true)
                        end
                    end
                end)

                return KeyPicker
            end

            function Depbox:AddColorPicker(Config: { [string]: any })
                Config = Library:Validate(Config, Templates.ColorPicker)

                local ColorPicker = {}
                ColorPicker.Type = "ColorPicker"
                ColorPicker.Value = Config.Default
                ColorPicker.Open = false

                local ColorPickerHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = DepboxHolder,
                })

                local ColorPickerButton = New("TextButton", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    Parent = ColorPickerHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerButton,
                })

                local ColorPickerText = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Text = Config.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ColorPickerButton,
                })

                local ColorPickerPreview = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = ColorPicker.Value,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(24, 24),
                    Parent = ColorPickerButton,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerPreview,
                })

                local ColorPickerList = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromOffset(0, 30),
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ZIndex = 10,
                    Parent = ColorPickerHolder,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerList,
                })

                local ColorPickerPadding = New("UIPadding", {
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    PaddingTop = UDim.new(0, 4),
                    Parent = ColorPickerList,
                })

                local ColorPickerContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Parent = ColorPickerList,
                })

                local ColorPickerHue = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerHue,
                })

                local ColorPickerHueImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = "rbxassetid://4155801252",
                    Parent = ColorPickerHue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerHueImage,
                })

                local ColorPickerHueButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ColorPickerHue,
                })

                local ColorPickerHueSelector = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "White",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Parent = ColorPickerHue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorPickerHueSelector,
                })

                local ColorPickerSaturation = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 24),
                    Size = UDim2.new(1, 0, 0, 100),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerSaturation,
                })

                local ColorPickerSaturationImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = "rbxassetid://4155801252",
                    Parent = ColorPickerSaturation,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerSaturationImage,
                })

                local ColorPickerSaturationButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ColorPickerSaturation,
                })

                local ColorPickerSaturationSelector = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "White",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Parent = ColorPickerSaturation,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorPickerSaturationSelector,
                })

                local ColorPickerValue = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 128),
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerValue,
                })

                local ColorPickerValueImage = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Image = "rbxassetid://4155801252",
                    Parent = ColorPickerValue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerValueImage,
                })

                local ColorPickerValueButton = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ColorPickerValue,
                })

                local ColorPickerValueSelector = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "White",
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(8, 8),
                    Parent = ColorPickerValue,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorPickerValueSelector,
                })

                local ColorPickerHex = New("TextBox", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(0, 152),
                    Size = UDim2.new(1, 0, 0, 24),
                    Text = "#" .. ColorPicker.Value:ToHex(),
                    Parent = ColorPickerContainer,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                    Parent = ColorPickerHex,
                })

                ColorPickerList.Size = UDim2.new(1, 0, 0, 176)

                ColorPicker.Holder = ColorPickerHolder
                ColorPicker.Text = Config.Text
                ColorPicker.Visible = Config.Visible

                table.insert(Options, ColorPicker)
                table.insert(Depbox.Elements, ColorPicker)

                function ColorPicker:SetValue(Value: Color3, Callback: boolean?)
                    if ColorPicker.Value == Value then
                        return
                    end

                    ColorPicker.Value = Value
                    ColorPickerPreview.BackgroundColor3 = Value
                    ColorPickerHex.Text = "#" .. Value:ToHex()

                    local H, S, V = Value:ToHSV()
                    ColorPickerHueSelector.Position = UDim2.fromScale(H, 0.5)
                    ColorPickerSaturationSelector.Position = UDim2.fromScale(S, 1 - V)
                    ColorPickerValueSelector.Position = UDim2.fromScale(0.5, 1 - V)

                    if Callback then
                        Library:SafeCallback(Config.Callback, Value, ColorPicker)
                    end
                    Library:SafeCallback(Config.Changed, Value, ColorPicker)
                end

                function ColorPicker:GetValue()
                    return ColorPicker.Value
                end

                function ColorPicker:SetText(Text: string)
                    ColorPicker.Text = Text
                    ColorPickerText.Text = Text
                end

                function ColorPicker:SetVisible(Visible: boolean)
                    ColorPicker.Visible = Visible
                    ColorPickerHolder.Visible = Visible
                end

                function ColorPicker:Open()
                    if ColorPicker.Open then
                        return
                    end

                    ColorPicker.Open = true
                    ColorPickerList.Visible = true
                end

                function ColorPicker:Close()
                    if not ColorPicker.Open then
                        return
                    end

                    ColorPicker.Open = false
                    ColorPickerList.Visible = false
                end

                function ColorPicker:Toggle()
                    if ColorPicker.Open then
                        ColorPicker:Close()
                    else
                        ColorPicker:Open()
                    end
                end

                local function UpdateFromHue()
                    local H = (ColorPickerHueSelector.AbsolutePosition.X - ColorPickerHue.AbsolutePosition.X) / ColorPickerHue.AbsoluteSize.X
                    local S, V = ColorPicker.Value:ToHSV()
                    ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                end

                local function UpdateFromSaturation()
                    local S = (ColorPickerSaturationSelector.AbsolutePosition.X - ColorPickerSaturation.AbsolutePosition.X) / ColorPickerSaturation.AbsoluteSize.X
                    local V = 1 - (ColorPickerSaturationSelector.AbsolutePosition.Y - ColorPickerSaturation.AbsolutePosition.Y) / ColorPickerSaturation.AbsoluteSize.Y
                    local H = ColorPicker.Value:ToHSV()
                    ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                end

                local function UpdateFromValue()
                    local V = 1 - (ColorPickerValueSelector.AbsolutePosition.Y - ColorPickerValue.AbsolutePosition.Y) / ColorPickerValue.AbsoluteSize.Y
                    local H, S = ColorPicker.Value:ToHSV()
                    ColorPicker:SetValue(Color3.fromHSV(H, S, V), true)
                end

                local function UpdateFromHex()
                    local Hex = ColorPickerHex.Text:match("#(%x%x%x%x%x%x)")
                    if Hex then
                        local R = tonumber(Hex:sub(1, 2), 16) / 255
                        local G = tonumber(Hex:sub(3, 4), 16) / 255
                        local B = tonumber(Hex:sub(5, 6), 16) / 255
                        ColorPicker:SetValue(Color3.new(R, G, B), true)
                    else
                        ColorPickerHex.Text = "#" .. ColorPicker.Value:ToHex()
                    end
                end

                local HueDragging = false
                ColorPickerHueButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        HueDragging = true
                        UpdateFromHue()
                    end
                end)

                local SaturationDragging = false
                ColorPickerSaturationButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        SaturationDragging = true
                        UpdateFromSaturation()
                    end
                end)

                local ValueDragging = false
                ColorPickerValueButton.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        ValueDragging = true
                        UpdateFromValue()
                    end
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if HueDragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = ColorPickerHue.AbsolutePosition
                        local BarSize = ColorPickerHue.AbsoluteSize

                        local Percent = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                        ColorPickerHueSelector.Position = UDim2.fromScale(Percent, 0.5)
                        UpdateFromHue()
                    elseif SaturationDragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = ColorPickerSaturation.AbsolutePosition
                        local BarSize = ColorPickerSaturation.AbsoluteSize

                        local PercentX = math.clamp((MousePos.X - BarPos.X) / BarSize.X, 0, 1)
                        local PercentY = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                        ColorPickerSaturationSelector.Position = UDim2.fromScale(PercentX, PercentY)
                        UpdateFromSaturation()
                    elseif ValueDragging and IsHoverInput(Input) then
                        local MousePos = UserInputService:GetMouseLocation()
                        local BarPos = ColorPickerValue.AbsolutePosition
                        local BarSize = ColorPickerValue.AbsoluteSize

                        local Percent = math.clamp((MousePos.Y - BarPos.Y) / BarSize.Y, 0, 1)
                        ColorPickerValueSelector.Position = UDim2.fromScale(0.5, Percent)
                        UpdateFromValue()
                    end
                end)

                UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        HueDragging = false
                        SaturationDragging = false
                        ValueDragging = false
                    end
                end)

                ColorPickerHex.FocusLost:Connect(function()
                    UpdateFromHex()
                end)

                ColorPickerButton.MouseButton1Click:Connect(function()
                    ColorPicker:Toggle()
                end)

                UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and ColorPicker.Open then
                        local MousePos = UserInputService:GetMouseLocation()
                        local AbsPos, AbsSize = ColorPickerList.AbsolutePosition, ColorPickerList.AbsoluteSize

                        if
                            MousePos.X < AbsPos.X
                            or MousePos.X > AbsPos.X + AbsSize.X
                            or MousePos.Y < AbsPos.Y
                            or MousePos.Y > AbsPos.Y + AbsSize.Y
                        then
                            ColorPicker:Close()
                        end
                    end
                end)

                return ColorPicker
            end

            function Depbox:AddDivider()
                local Divider = {}
                Divider.Type = "Divider"

                local DividerHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 8),
                    Parent = DepboxHolder,
                })

                local DividerLine = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = "OutlineColor",
                    Position = UDim2.fromOffset(0, 4),
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = DividerHolder,
                })

                Divider.Holder = DividerHolder
                Divider.Visible = true

                table.insert(Depbox.Elements, Divider)

                function Divider:SetVisible(Visible: boolean)
                    Divider.Visible = Visible
                    DividerHolder.Visible = Visible
                end

                return Divider
            end

            function Depbox:Resize()
                local ContentSize = 0
                for _, Element in pairs(Depbox.Elements) do
                    if Element.Visible then
                        ContentSize += Element.Holder.AbsoluteSize.Y + 4
                    end
                end

                DepboxHolder.Size = UDim2.new(1, 0, 0, ContentSize)
            end

            function Depbox:Update(Force: boolean?)
                for _, Element in pairs(Depbox.Elements) do
                    if Element.Type == "Toggle" and Element.Value then
                        for _, SubDepbox in pairs(Depbox.DependencyBoxes) do
                            if SubDepbox.Toggle == Element then
                                SubDepbox.Holder.Visible = true
                            end
                        end
                    elseif Element.Type == "Toggle" and not Element.Value then
                        for _, SubDepbox in pairs(Depbox.DependencyBoxes) do
                            if SubDepbox.Toggle == Element then
                                SubDepbox.Holder.Visible = false
                            end
                        end
                    end
                end

                Depbox:Resize()
            end

            return Depbox
        end

        Tab:Resize()
        table.insert(Window.Tabs, Tab)

        return Tab
    end

    --// Keybinds Tab \\--
    local KeybindsTab = Window:CreateTab({
        Text = "Keybinds",
        IsKeyTab = true,
    })

    local KeybindsHolder = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(1, 0, 1, 0),
        Parent = KeybindsTab.Holder,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = KeybindsHolder,
    })

    local KeybindsPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 6),
        Parent = KeybindsHolder,
    })

    local KeybindsList = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = KeybindsHolder,
    })

    Library.KeybindFrame = New("Frame", {
        BackgroundColor3 = "MainColor",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(0, 0),
        Parent = KeybindsHolder,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Library.KeybindFrame,
    })

    Library.KeybindContainer = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = Library.KeybindFrame,
    })

    local KeybindsContainerList = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.KeybindContainer,
    })

    function Window:CreateKeybind(Config: { [string]: any })
        Config = Library:Validate(Config, {
            Text = "Keybind",
            Mode = "Toggle",
            Default = "None",
            DefaultModifiers = {},
            SyncToggleState = false,
            Callback = function() end,
            ChangedCallback = function() end,
            Changed = function() end,
            Clicked = function() end,
        })

        local Keybind = {}
        Keybind.Value = Config.Default
        Keybind.Modifiers = Config.DefaultModifiers
        Keybind.Mode = Config.Mode
        Keybind.Picking = false
        Keybind.Holding = false
        Keybind.Enabled = false

        local KeybindHolder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = UDim2.new(1, 0, 0, 30),
            Parent = Library.KeybindContainer,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius - 1),
            Parent = KeybindHolder,
        })

        local KeybindText = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -100, 1, 0),
            Text = Config.Text .. ": " .. (Keybind.Value == "None" and "None" or Library:GetKeyString(Keybind.Value)),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = KeybindHolder,
        })

        local KeybindButton = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(80, 20),
            Text = Keybind.Value == "None" and "Set" or "Change",
            TextSize = 12,
            Parent = KeybindHolder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius - 1),
            Parent = KeybindButton,
        })

        local KeybindReset = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -92, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Text = "×",
            TextSize = 20,
            Parent = KeybindHolder,
        })

        Keybind.Holder = KeybindHolder
        Keybind.Label = KeybindText
        Keybind.Button = KeybindButton

        table.insert(Library.KeybindToggles, Keybind)

        function Keybind:SetValue(Value: Enum.KeyCode, Callback: boolean?)
            if Keybind.Value == Value then
                return
            end

            Keybind.Value = Value
            KeybindText.Text = Config.Text .. ": " .. (Value == "None" and "None" or Library:GetKeyString(Value))
            KeybindButton.Text = Value == "None" and "Set" or "Change"

            if Callback then
                Library:SafeCallback(Config.Callback, Value, Keybind)
            end
            Library:SafeCallback(Config.ChangedCallback, Value, Keybind)
            Library:SafeCallback(Config.Changed, Value, Keybind)
        end

        function Keybind:GetValue()
            return Keybind.Value
        end

        function Keybind:SetText(Text: string)
            Config.Text = Text
            KeybindText.Text = Text .. ": " .. (Keybind.Value == "None" and "None" or Library:GetKeyString(Keybind.Value))
        end

        function Keybind:SetMode(Mode: string)
            Keybind.Mode = Mode
        end

        function Keybind:SetEnabled(Enabled: boolean)
            Keybind.Enabled = Enabled
        end

        function Keybind:Update()
            if Library.ShowToggleFrameInKeybinds then
                KeybindHolder.Visible = Keybind.Value ~= "None"
            else
                KeybindHolder.Visible = true
            end
        end

        KeybindButton.MouseButton1Click:Connect(function()
            Keybind.Picking = true
            KeybindText.Text = Config.Text .. ": ..."
            KeybindButton.Text = "..."
        end)

        KeybindReset.MouseButton1Click:Connect(function()
            Keybind:SetValue("None", true)
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if Keybind.Picking then
                Keybind.Picking = false

                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    Keybind:SetValue(Input.KeyCode, true)
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Keybind:SetValue(Enum.KeyCode.MouseButton1, true)
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    Keybind:SetValue(Enum.KeyCode.MouseButton2, true)
                end
            elseif Keybind.Value ~= "None" and Input.KeyCode == Keybind.Value then
                if Keybind.Mode == "Toggle" then
                    Keybind.Enabled = not Keybind.Enabled
                    Library:SafeCallback(Config.Callback, Keybind.Enabled, Keybind)
                    Library:SafeCallback(Config.Clicked, Keybind)
                elseif Keybind.Mode == "Hold" then
                    Keybind.Holding = true
                    Keybind.Enabled = true
                    Library:SafeCallback(Config.Callback, true, Keybind)
                    Library:SafeCallback(Config.Clicked, Keybind)
                elseif Keybind.Mode == "Always" then
                    Keybind.Enabled = true
                    Library:SafeCallback(Config.Callback, true, Keybind)
                    Library:SafeCallback(Config.Clicked, Keybind)
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(Input)
            if Keybind.Value ~= "None" and Input.KeyCode == Keybind.Value then
                if Keybind.Mode == "Hold" and Keybind.Holding then
                    Keybind.Holding = false
                    Keybind.Enabled = false
                    Library:SafeCallback(Config.Callback, false, Keybind)
                end
            end
        end)

        Keybind:Update()
        Library:UpdateKeybindFrame()

        return Keybind
    end

    --// Window Functions \\--
    function Window:ToggleKeybinds()
        if Library.ActiveTab == KeybindsTab then
            if #Window.Tabs > 1 then
                Window:SelectTab(Window.Tabs[1])
            end
        else
            Window:SelectTab(KeybindsTab)
        end
    end

    --// Window Events \\--
    CloseButton.MouseButton1Click:Connect(function()
        Window:Hide()
    end)

    UserInputService.InputBegan:Connect(function(Input)
        if Input.KeyCode == Config.ToggleKeybind then
            Window:Toggle()
        end
    end)

    if Config.Center then
        Window:Center()
    end

    if Config.AutoShow then
        Window:Show()
    end

    Library:MakeDraggable(Background, Topbar, false, true)

    if Config.Resizable then
        Library:MakeResizable(Background, Background, function()
            Window:Resize()
        end)
    end

    Window:Resize()

    table.insert(Library.Tabs, KeybindsTab)

    if #Window.Tabs > 0 then
        Window:SelectTab(Window.Tabs[1])
    end

    return Window
end

--// Notification \\--
function Library:Notify(Config: { [string]: any })
    Config = Library:Validate(Config, {
        Text = "Notification",
        Duration = 3,
        Callback = function() end,
    })

    local Notification = {}
    Notification.Hovering = false

    local NotificationHolder = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0, 300, 0, 0),
        Parent = NotificationArea,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = NotificationHolder,
    })

    local NotificationPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 6),
        Parent = NotificationHolder,
    })

    local NotificationText = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = Config.Text,
        TextSize = 14,
        TextWrapped = true,
        Parent = NotificationHolder,
    })

    local NotificationClose = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(16, 16),
        Text = "×",
        TextSize = 20,
        Parent = NotificationHolder,
    })

    Notification.Holder = NotificationHolder

    table.insert(Library.Notifications, Notification)

    function Notification:Resize()
        local TextSize = Library:GetTextBounds(Config.Text, Library.Scheme.Font, 14, 288)
        NotificationHolder.Size = UDim2.fromOffset(300, TextSize + 12)
    end

    function Notification:Remove()
        if Notification.Removing then
            return
        end

        Notification.Removing = true

        local Tween = TweenService:Create(
            NotificationHolder,
            Library.NotifyTweenInfo,
            { Position = UDim2.new(1, NotificationHolder.AbsoluteSize.X + 6, 0, NotificationHolder.Position.Y.Offset) }
        )
        Tween:Play()

        Tween.Completed:Connect(function()
            NotificationHolder:Destroy()
            table.remove(Library.Notifications, table.find(Library.Notifications, Notification))
        end)
    end

    Notification:Resize()

    NotificationHolder.MouseEnter:Connect(function()
        Notification.Hovering = true
    end)

    NotificationHolder.MouseLeave:Connect(function()
        Notification.Hovering = false
    end)

    NotificationClose.MouseButton1Click:Connect(function()
        Notification:Remove()
    end)

    local Tween = TweenService:Create(
        NotificationHolder,
        Library.NotifyTweenInfo,
        { Position = UDim2.new(0, 0, 0, NotificationHolder.Position.Y.Offset) }
    )
    Tween:Play()

    task.delay(Config.Duration, function()
        if not Notification.Hovering then
            Notification:Remove()
        end
    end)

    return Notification
end

--// Unload \\--
function Library:Unload()
    if Library.Unloaded then
        return
    end

    Library.Unloaded = true

    for _, Connection in pairs(Library.Signals) do
        if Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _, Connection in pairs(Library.UnloadSignals) do
        if Connection.Connected then
            Connection:Disconnect()
        end
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    if Library.UnloadCallback then
        Library:SafeCallback(Library.UnloadCallback)
    end
end

--// Return \\--
return Library
