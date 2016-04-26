
	;	http://forum.script-coding.com/viewtopic.php?id=11447

#NoEnv
#SingleInstance Force
#KeyHistory 0
ListLines Off
SetBatchLines,-1
OnExit("ZoomOnClose")
Try Menu, Tray, Icon, Shell32, 23
OnMessage(0xF, "WM_Paint")
OnMessage(0x214, "WM_SIZING")
OnMessage(0x0020, "WM_SETCURSOR")
Global oZoom := {}

oZoom.Zoom := 2
oZoom.Mark := "Cross"		; Cross, Square, Grid, None

; WinX := 1559
; WinY := 594
WinW := 300
WinH := 360

Gui, Zoom: +AlwaysOnTop +Resize -DPIScale +hwndhGui +LabelZoomOn
Gui, Zoom: Font, s12
Gui, Zoom: Color, F0F0F0
Gui, Zoom: Add, Slider, vSliderZoom gSliderZoom x8 Range1-50 w176 Center AltSubmit NoTicks, % oZoom.Zoom
Gui, Zoom: Add, Text, vTextZoom Center x+10 yp+3 w36, % oZoom.Zoom
Gui, Zoom: Font
Gui, Zoom: Add, Button, gChangeMark vChangeMark x+10 yp w52, % oZoom.Mark
Gui, Dev: +HWNDhDev -Caption -DPIScale +Parent%hGui%
Gui, Dev: Add, Pic, hwndhDevCon
Gui, Dev: Show, NA
Gui, Dev: Color, ffffff

; Gui, Zoom: Show, x%WinX% y%WinY% w%WinW% h%WinH%, Magnify
Gui, Zoom: Show, w%WinW% h%WinH%, Magnify
Gui, Zoom: +MinSize

oZoom.hdcSrc := DllCall("GetDC", "Ptr", 0)
oZoom.hdcDest := DllCall("GetDC", "Ptr", hDevCon, "Ptr")
oZoom.hdcMemory := DllCall("CreateCompatibleDC", "Ptr", 0)
DllCall("Gdi32.Dll\SetStretchBltMode", "Ptr", oZoom.hdcDest, "Int", 4)
oZoom.hGui := hGui
oZoom.hDev := hDev
oZoom.hDevCon := hDevCon
Magnify()
Return

#If !oZoom.Minimize

+Up::MouseStep(0, -1)
+Down::MouseStep(0, 1)
+Left::MouseStep(-1, 0)
+Right::MouseStep(1, 0)

^Up::
^DoWn::
^WheelUp::
^WheelDown::ChangeZoom(InStr(A_ThisHotKey, "DoWn") ? oZoom.Zoom + 1 : oZoom.Zoom - 1)

1:: oZoom.Pause := !oZoom.Pause

#If

Magnify() {
	If (!oZoom.Pause && !oZoom.Minimize && !oZoom.Sizing)
	{
		MouseGetPos, , , WinID
		If (WinID != oZoom.hGui)
		{
			SetTimer, Memory, Off
			DllCall("GetCursorPos", "int64P", pt)
			oZoom.MouseX := pt << 32 >> 32, oZoom.MouseY := pt >> 32
			StretchBlt(oZoom.hdcDest, 0, 0, oZoom.nWidthDest, oZoom.nHeightDest
				, oZoom.hdcSrc, oZoom.MouseX - oZoom.nXOriginSrcOffset, oZoom.MouseY - oZoom.nYOriginSrcOffset, oZoom.nWidthSrc, oZoom.nHeightSrc)
			For k, v In oZoom.oMarkers[oZoom.Mark]
				StretchBlt(oZoom.hdcDest, v.x, v.y, v.w, v.h, oZoom.hdcDest, v.x, v.y, v.w, v.h, 0x5A0049)	; PATINVERT
			SetTimer, Memory, -30
		}
	}
	SetTimer, Magnify, -10
}

Memory() {
	SysGet, VirtualScreenX, 76
	SysGet, VirtualScreenY, 77
	SysGet, VirtualScreenWidth, 78
	SysGet, VirtualScreenHeight, 79
	oZoom.nXOriginSrc := oZoom.MouseX - VirtualScreenX, oZoom.nYOriginSrc := oZoom.MouseY - VirtualScreenY
	hBM := DllCall("Gdi32.Dll\CreateCompatibleBitmap", "Ptr", oZoom.hdcSrc, "Int", VirtualScreenWidth, "Int", VirtualScreenHeight)
	DllCall("Gdi32.Dll\SelectObject", "Ptr", oZoom.hdcMemory, "Ptr", hBM), DllCall("DeleteObject", "Ptr", hBM)
	BitBlt(oZoom.hdcMemory, 0, 0, VirtualScreenWidth, VirtualScreenHeight, oZoom.hdcSrc, VirtualScreenX, VirtualScreenY)
	oZoom.VirtualScreenWidth := VirtualScreenWidth, oZoom.VirtualScreenHeight := VirtualScreenHeight
}

Redraw() {
	StretchBlt(oZoom.hdcDest, 0, 0, oZoom.nWidthDest, oZoom.nHeightDest
		, oZoom.hdcMemory, oZoom.nXOriginSrc - oZoom.nXOriginSrcOffset, oZoom.nYOriginSrc - oZoom.nYOriginSrcOffset, oZoom.nWidthSrc, oZoom.nHeightSrc)
	For k, v In oZoom.oMarkers[oZoom.Mark]
		StretchBlt(oZoom.hdcDest, v.x, v.y, v.w, v.h, oZoom.hdcDest, v.x, v.y, v.w, v.h, 0x5A0049)	; PATINVERT
}

SetSize() {
	Critical
	Static Top := 60, Left := 0, Right := 0, Bottom := 0
	SetTimer, Magnify, Off
	GetClientPos(oZoom.hGui, GuiWidth, GuiHeight)
	Width := GuiWidth - Left - Right
	Height := GuiHeight - Top - Bottom
	Zoom := oZoom.Zoom
	conW := Mod(Width, Zoom) ? Width - Mod(Width, Zoom) + Zoom : Width
	conW := Mod(conW // Zoom, 2) ? conW : conW + Zoom
	conH := Mod(Height, Zoom) ? Height - Mod(Height, Zoom) + Zoom : Height
	conH := Mod(conH // Zoom, 2) ? conH : conH + Zoom
	conX := ((conW - Width) // 2) * -1
	conY := ((conH - Height) // 2) * -1

	oZoom.nWidthSrc := conW // Zoom
	oZoom.nHeightSrc := conH // Zoom
	oZoom.nXOriginSrcOffset := oZoom.nWidthSrc // 2
	oZoom.nYOriginSrcOffset := oZoom.nHeightSrc // 2
	oZoom.nWidthDest := nWidthDest := conW
	oZoom.nHeightDest := nHeightDest := conH
	xCenter := conW / 2 - Zoom / 2
	yCenter := conH / 2 - Zoom / 2

	oZoom.oMarkers["Cross"] := [{x:0,y:yCenter - 1,w:nWidthDest,h:1}
		, {x:0,y:yCenter + Zoom,w:nWidthDest,h:1}
		, {x:xCenter - 1,y:0,w:1,h:nHeightDest}
		, {x:xCenter + Zoom,y:0,w:1,h:nHeightDest}]

	oZoom.oMarkers["Square"] := [{x:xCenter - 1,y:yCenter,w:Zoom + 2,h:1}
		, {x:xCenter - 1,y:yCenter + Zoom + 1,w:Zoom + 2,h:1}
		, {x:xCenter - 1,y:yCenter + 1,w:1,h:Zoom}
		, {x:xCenter + Zoom,y:yCenter + 1,w:1,h:Zoom}]

	oZoom.oMarkers["Grid"] := Zoom = 1 ? oZoom.oMarkers["Square"]
		: [{x:xCenter - Zoom,y:yCenter - Zoom,w:Zoom * 3,h:1}
		, {x:xCenter - Zoom,y:yCenter,w:Zoom * 3,h:1}
		, {x:xCenter - Zoom,y:yCenter + Zoom,w:Zoom * 3,h:1}
		, {x:xCenter - Zoom,y:yCenter + Zoom * 2,w:Zoom * 3,h:1}
		, {x:xCenter - Zoom,y:yCenter - Zoom,w:1,h:Zoom * 3}
		, {x:xCenter,y:yCenter - Zoom,w:1,h:Zoom * 3}
		, {x:xCenter + Zoom,y:yCenter - Zoom,w:1,h:Zoom * 3}
		, {x:xCenter + Zoom * 2,y:yCenter - Zoom,w:1,h:Zoom * 3}]

	SetWindowPos(oZoom.hDevCon, conX, conY, conW, conH)
	SetWindowPos(oZoom.hDev, Left, Top, Width, Height)
	Redraw()
	SetTimer, Magnify, -10
}

SetWindowPos(hWnd, x, y, w, h) {
	Static SWP_ASYNCWINDOWPOS := 0x4000, SWP_DEFERERASE := 0x2000, SWP_NOACTIVATE := 0x0010, SWP_NOCOPYBITS := 0x0100
		, SWP_NOOWNERZORDER := 0x0200, SWP_NOREDRAW := 0x0008, SWP_NOSENDCHANGING := 0x0400
		, uFlags := SWP_ASYNCWINDOWPOS|SWP_DEFERERASE|SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOOWNERZORDER|SWP_NOREDRAW|SWP_NOSENDCHANGING
	DllCall("SetWindowPos"
		, "Ptr", hWnd
		, "Ptr", 0
		, "Int", x
		, "Int", y
		, "Int", w
		, "Int", h
		, "UInt", uFlags)
}

ZoomOnSize() {
	If A_EventInfo != 1
	{
		oZoom.Minimize := 0
		SetTimer, SetSize, -10
	}
	Else
		oZoom.Minimize := 1
}

SliderZoom() {
	GuiControlGet, SliderZoom, Zoom:
	ChangeZoom(SliderZoom)
}

ChangeZoom(Val) {
	If (Val < 1 || Val > 50)
		Return
	SetTimer, Magnify, Off
	GuiControl, Zoom:, TextZoom, % oZoom.Zoom := Val
	If A_GuiControl =
		GuiControl, Zoom:, SliderZoom, % oZoom.Zoom
	SetTimer, SetSize, -10
}

ChangeMark() {
	oZoom.Mark := ["Cross","Square","Grid","None"][{"Cross":2,"Square":3,"Grid":4,"None":1}[oZoom.Mark]]
	GuiControl, Zoom:, ChangeMark, % oZoom.Mark
	Redraw()
}

ZoomOnClose() {
	ZoomOnEscape:
		DllCall("Gdi32.Dll\DeleteDC", "Ptr", oZoom.hdcDest)
		DllCall("Gdi32.Dll\DeleteDC", "Ptr", oZoom.hdcSrc)
		DllCall("Gdi32.Dll\DeleteDC", "Ptr", oZoom.hdcMemory)
		RestoreCursors()
		ExitApp
}

GetClientPos(hwnd, ByRef W, ByRef H)  {
	VarSetCapacity(pwi, 60, 0), NumPut(60, pwi, 0, "UInt")
	DllCall("GetWindowInfo", "Ptr", hwnd, "UInt", &pwi)
	W := NumGet(pwi, 28, "Int") - NumGet(pwi, 20, "Int")
	H := NumGet(pwi, 32, "Int") - NumGet(pwi, 24, "Int")
}

WM_Paint() {
	If A_GuiControl =
		SetTimer, Redraw, -30
}

WM_SIZING() {
	SetTimer, Magnify, Off
	oZoom.Sizing := 1
	SetTimer, NoSizing, 10
}

NoSizing() {
	If GetKeyState("LButton", "P")
		Return
	oZoom.Sizing := 0
	SetTimer, NoSizing, Off
	SetTimer, Magnify, -10
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster = 0xC000CA) {
	Return DllCall("Gdi32.Dll\BitBlt"
		, "Ptr", dDC
		, "Int", dx
		, "Int", dy
		, "Int", dw
		, "Int", dh
		, "Ptr", sDC
		, "Int", sx
		, "Int", sy
		, "Uint", Raster)
}

StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster = 0xC000CA) {
	Return DllCall("Gdi32.Dll\StretchBlt"
		, "Ptr", dDC
		, "Int", dx
		, "Int", dy
		, "Int", dw
		, "Int", dh
		, "Ptr", sDC
		, "Int", sx
		, "Int", sy
		, "Int", sw
		, "Int", sh
		, "Uint", Raster)
}

	; _________________________________________________ MoveHand _________________________________________________

WM_SETCURSOR(W, L, M, H) {
	If (oZoom.SIZING)
		Return
	If (oZoom.Pause && W = oZoom.hDev && GetKeyState("LButton", "P"))
	{
		SetTimer, Hand, -1
		Return oZoom.SIZING := 1
	}
}

Hand() {
	SetTimer, Magnify, Off
	DllCall("GetCursorPos", "int64P", pt)
	oZoom.MoveHandX := pt << 32 >> 32, oZoom.MoveHandY := pt >> 32
	oZoom.MoveXSrc := oZoom.nXOriginSrc, oZoom.MoveYSrc := oZoom.nYOriginSrc
	SetSystemCursor("HAND")
	SetTimer, MoveHand, 10
	KeyWait, LButton
	SetTimer, MoveHand, Off
	RestoreCursors()
	oZoom.SIZING := 0
	SetTimer, Magnify, -10
}

MoveHand() {
	Static PrnXOriginSrc, PrnYOriginSrc
	PrnXOriginSrc := oZoom.nXOriginSrc
	PrnYOriginSrc := oZoom.nYOriginSrc
	DllCall("GetCursorPos", "int64P", pt)
	MouseX := pt << 32 >> 32, MouseY := pt >> 32
	XOdds := oZoom.MoveHandX - MouseX
	XOff := XOdds > 0 ? Floor(XOdds / oZoom.Zoom) : Ceil(XOdds / oZoom.Zoom)
	oZoom.nXOriginSrc := oZoom.MoveXSrc + XOff
	YOdds := oZoom.MoveHandY - MouseY
	YOff := YOdds > 0 ? Floor(YOdds / oZoom.Zoom) : Ceil(YOdds / oZoom.Zoom)
	oZoom.nYOriginSrc := oZoom.MoveYSrc + YOff
	If (PrnXOriginSrc <> oZoom.nXOriginSrc || PrnYOriginSrc <> oZoom.nYOriginSrc)
		LimitsOriginSrc(), Redraw()
}

MoveStep(StepX, StepY) {
	oZoom.nXOriginSrc += StepX
	oZoom.nYOriginSrc += StepY
	LimitsOriginSrc(), Redraw()
}

LimitsOriginSrc() {
	X := oZoom.nXOriginSrc
	oZoom.nXOriginSrc := X < 0 ? 0 : X > oZoom.VirtualScreenWidth - 1 ? oZoom.VirtualScreenWidth - 1 : X
	Y := oZoom.nYOriginSrc
	oZoom.nYOriginSrc := Y < 0 ? 0 : Y > oZoom.VirtualScreenHeight - 1 ? oZoom.VirtualScreenHeight - 1 : Y
}

MouseStep(x, y) {
	If !oZoom.Pause
		MouseMove, x, y, 0, R
	Else
		MoveStep(x, y)
}

SetSystemCursor(CursorName, cx = 0, cy = 0) {
	Static SystemCursors := {ARROW:32512, IBEAM:32513, WAIT:32514, CROSS:32515, UPARROW:32516, SIZE:32640, ICON:32641, SIZENWSE:32642
					, SIZENESW:32643, SIZEWE:32644 ,SIZENS:32645, SIZEALL:32646, NO:32648, HAND:32649, APPSTARTING:32650, HELP:32651}
    Local CursorHandle, hImage, Name, ID
	If (CursorHandle := DllCall("LoadCursor", Uint, 0, Int, SystemCursors[CursorName]))
		For Name, ID in SystemCursors
			hImage := DllCall("CopyImage", Ptr, CursorHandle, Uint, 0x2, Int, cx, Int, cy, Uint, 0)
			, DllCall("SetSystemCursor", Ptr, hImage, Int, ID)
}

RestoreCursors() {
	Static SPI_SETCURSORS := 0x57
	DllCall("SystemParametersInfo", UInt, SPI_SETCURSORS, UInt, 0, UInt, 0, UInt, 0)
}

