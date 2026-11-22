#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-SetMainIcon Resources\FABconfig.ico
;@Ahk2Exe-SetProductName FABconfig
;@Ahk2Exe-SetDescription FABconfig - Add Fabrication Configuration
;@Ahk2Exe-SetCompanyName Virtual Building Supply`, LLC
;@Ahk2Exe-SetCopyright Copyright (C) 2026 Virtual Building Supply`, LLC. GNU GPL v3.

/* ---+---+---+---+---+---+---FABconfig+---+---+---+---+---+---+
 *
 * FABconfig - Add Fabrication Configuration
 * Adds the Autodesk Fabrication database this program runs from to
 * Fabrication as a named configuration: creates a configuration folder with
 * a map.ini that points back to the database, and registers it with each
 * recent Fabrication version.
 *
 * Copyright (C) 2026 Virtual Building Supply, LLC
 * Author: Scott Hendricks
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * Additional terms under GNU GPL version 3, section 7:
 *  (b) The copyright notice and author attribution above must be preserved
 *      in this file and in any modified version of it.
 *  (e) This License grants no rights to use the trade names, trademarks or
 *      logos of Virtual Building Supply, LLC, including the VBS logo files in
 *      the Resources folder. Modified versions that are distributed must
 *      replace them.
 *
 * Version: see APP_VERSION below (AutoHotkey v2)
 *
 * ---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 */

;======================= Configuration ==============================
APP_NAME    := "FABconfig"
; The version lives only here. The Ahk2Exe lines below copy it (without the
; "v") into the .exe's version details, so they must stay directly
; after this line. A second release on the same day adds a fourth number,
; like "v26.10.24.1".
APP_VERSION := "v26.11.22"
;@Ahk2Exe-Let U_version = %A_PriorLine~^.*"v([\d.]+)".*$~$1%
;@Ahk2Exe-SetVersion %U_version%
;@Ahk2Exe-ExeName FABconfig.exe
WIN_TITLE   := "FABconfig - Fabrication Configurations"
CONFIG_ROOT := "C:\fabrication-configurations"
; FABconfig marks the map.ini it writes with this first line. VBS databases'
; own map.ini files start with it as well.
MAP_MARKER  := "# Created by Virtual Building Supply"

; Fabrication versions to register the configuration with: 4 years back to
; 2 years ahead of the current year (same range as the original script).
YEAR_FROM := A_YYYY - 4
YEAR_TO   := A_YYYY + 2

; The database is the folder this script is run from.
; If there's no map.ini here (or this is a configuration folder),
; FABconfig asks for the database folder at start-up.
DB_DIR  := IsDatabaseFolder(A_ScriptDir) && FileExist(A_ScriptDir "\map.ini") ? A_ScriptDir : ""
DB_PATH := StrReplace(DB_DIR, "\", "/")   ; map.ini uses forward slashes
; [COMPANY-INFO] DBNAME is optional; without it the name starts blank.
DB_NAME := DB_DIR != "" ? Trim(IniRead(DB_DIR "\map.ini", "COMPANY-INFO", "DBNAME", "")) : ""
NO_DB_TEXT := "No database selected. Click Browse to choose one."

;======================= Colors (MapQuery Studio look) ==============
; The same dark and light palettes as MapQuery Studio (its theme.rs).
; Controls are colored by role name (bg, text, muted ...), not by color, so
; switching theme only has to re-apply the roles (see ApplyTheme).
; soft = accent tint on bg (info banner); chip = accent tint on the panel and
; cards (version chips, step numbers); tile = the app icon's color.
THEMES := Map(
    "dark", {
        bg: "181A1F", panel: "1F2228", card: "262930",
        text: "E2E5EB", muted: "9AA0AC",
        border: "383C46", edge: "545B69", field: "1E2026",
        btn: "3A3F4B", btnHover: "4A505E", navHover: "2A2E36",
        accent: "2F68E0", accentHover: "3A75F0", accentText: "8DB4FF", onAccent: "FFFFFF",
        danger: "B3261E", dangerHover: "C9342B",
        soft: "222D43", chip: "28344A", tile: "5B8FF9"
    },
    "light", {
        bg: "F4F6F9", panel: "FAFBFD", card: "FFFFFF",
        text: "1C2028", muted: "5F6775",
        border: "D6DBE3", edge: "C9D0DB", field: "FBFCFD",
        btn: "ECEFF4", btnHover: "E0E6F0", navHover: "EEF1F6",
        accent: "2563EB", accentHover: "1D4ED8", accentText: "1D4ED8", onAccent: "FFFFFF",
        danger: "B3261E", dangerHover: "8C1D18",
        soft: "E3EBFD", chip: "E3EBFD", tile: "5B8FF9"
    }
)

; The chosen theme is remembered per user. Dark is the default, as in MapQuery Studio.
SETTINGS_KEY := "HKCU\Software\Virtual Building Supply\FABconfig"
theme := RegRead(SETTINGS_KEY, "Theme", "dark")
if !THEMES.Has(theme)
    theme := "dark"

FONT      := "Segoe UI"
FONT_SEMI := "Segoe UI Semibold"
ICON_FONT := "Segoe MDL2 Assets"   ; built into Windows 10 and 11

; Picture files live in a Resources folder next to the script. The compiled
; .exe has them built in (the icon through SetMainIcon, the PNGs below), so it
; doesn't need the folder.
APP_ICO    := A_ScriptDir "\Resources\FABconfig.ico"
APP_PNG    := A_ScriptDir "\Resources\FABconfig.png"
LOGO_BADGE := A_ScriptDir "\Resources\VBS_Logo_Badge.png"
;@Ahk2Exe-AddResource Resources\FABconfig.png, FABCONFIG_ICON
;@Ahk2Exe-AddResource Resources\VBS_Logo_Badge.png, VBS_LOGO_BADGE

ABOUT_TEXT := "
(
FABconfig adds the Fabrication database in this folder to Autodesk Fabrication (Revit, CADmep, ESTmep, CAMduct) as a configuration you can choose when the program starts. Run it from inside the database folder, or choose the database folder when it asks.

The map.ini it writes points the Database, Items, Images, Profiles, Reports and Scripts folders at this database. Projects, DXFs, Blocks and Backups stay in the configuration folder, so local work stays separate from the shared database.

Nothing in the database folder itself is changed. Running it again with the same name updates that configuration.

Remove Configurations lists every configuration registered on this PC and removes the ones you tick: their registry entries for every Fabrication version and, if you choose, their folders (to the Recycle Bin, so they can be restored).
)"
README_URL := "https://github.com/Virtual-Building-Supply-LLC/FABconfig#how-to-use-it"
HELP_ADD := "
(
1.  Check the name. It's filled in from the database when it can be.

2.  Check the location. It follows the name; use Browse… to pick another folder.

3.  Optional: choose where ESTmep or CAMduct keep their projects. Left blank, they go in a projects folder inside the configuration location.

4.  Check the database folder. Use Browse… to pick a different database.

5.  Click Create Configuration (or press Enter).

6.  Start Fabrication and pick the new configuration from the list.
)"
HELP_REMOVE := "
(
1.  Open Remove Configurations in the sidebar.

2.  Tick the configurations you no longer need. Nothing is ticked for you.

3.  Leave "Also move each folder to the Recycle Bin" on to remove their folders too.

4.  Click Remove selected and check the list before you confirm.

5.  Changed your mind? Restore the folder from the Recycle Bin and run Add Configuration again.
)"
COPYRIGHT_TEXT := "Copyright © 2026 Virtual Building Supply, LLC. FABconfig is free software under the GNU General Public License v3 and comes with ABSOLUTELY NO WARRANTY. See the LICENSE file for details."

STEPS := [
    {Title: "Create folder", Text: "Its own folder on this PC"},
    {Title: "Write map.ini", Text: "Points Fabrication at this database"},
    {Title: "Copy picture",  Text: "config.png for the start-up list"},
    {Title: "Register",      Text: "Fabrication " YEAR_FROM "–" YEAR_TO}
]

;======================= Scaling ====================================
; Layout is designed at 100% scaling (96 DPI) and multiplied by SCALE.
SCALE := A_ScreenDPI / 96
S(n) => Round(n * SCALE)

currentView := "main"
locTouched  := false   ; true once the user edits or browses the location
settingLoc  := false
mainCtrls   := []
removeCtrls := []
helpCtrls   := []
aboutCtrls  := []
configs     := []      ; Remove view: one entry per list row
ctl    := {}
groups := []           ; clickable groups (nav items, buttons, menus)
hoverMap := Map()      ; control hwnd -> group id
hotId  := 0            ; group currently under the mouse
created := []          ; every control, in the order it was added
themed  := []          ; {C, Bg, Fg}: the color roles of each control
fields  := []          ; text boxes (their border shows focus)

if FileExist(APP_ICO)
    TraySetIcon(APP_ICO)           ; also becomes the window icon
else if !A_IsCompiled
    TraySetIcon(A_WinDir "\System32\shell32.dll", 4)

;======================= Build GUI ==================================
; +0x2000000 (WS_CLIPCHILDREN) stops the window background from painting
; over the controls, which reduces flicker when resizing.
g := Gui("+Resize -DPIScale +0x2000000", WIN_TITLE)
g.BackColor := Clr("bg")
g.OnEvent("Close",  (*) => ExitApp())
g.OnEvent("Escape", OnEscape)
g.OnEvent("Size",   OnResize)
g.Opt("+OwnDialogs")   ; folder pickers and messages stay on top of this window
OnMessage(0x200, OnMouseMove)    ; WM_MOUSEMOVE: hover effects
OnMessage(0x20,  OnSetCursor)    ; WM_SETCURSOR: hand cursor on clickable items

; ---- Backgrounds: sidebar, top bar, status bar ----
ctl.Side       := AddCtl("Text", "", "", "panel")
ctl.SideLine   := AddCtl("Text", "", "", "border")
ctl.Top        := AddCtl("Text", "", "", "bg")
ctl.TopLine    := AddCtl("Text", "", "", "border")
ctl.Status     := AddCtl("Text", "", "", "panel")
ctl.StatusLine := AddCtl("Text", "", "", "border")

; ---- Sidebar ----
tileBmp := LoadPng("FABCONFIG_ICON", APP_PNG, S(34), Clr("panel"))
if tileBmp {
    ctl.Tile := AddCtl("Picture", "w" S(34) " h" S(34), "HBITMAP:" tileBmp)
} else {
    SetF("s14", ICON_FONT)
    ctl.Tile := AddCtl("Text", "Center +0x200", Chr(0xE8F4), "tile", "onAccent")   ; NewFolder glyph
}
SetF("s13")
ctl.AppName := AddCtl("Text", "+0x200", APP_NAME, "panel", "text")

navMain   := MakeNav(0xE710, "Add Configuration",     (*) => ShowView("main"))
navRemove := MakeNav(0xE74D, "Remove Configurations", (*) => ShowView("remove"))

ctl.Div1 := AddCtl("Text", "", "", "border")
SetF("s8")
ctl.VerHead := AddCtl("Text", "", "REGISTERS WITH", "panel", "muted")
SetF("s9")
ctl.VerSub := AddCtl("Text", "", "Autodesk Fabrication versions", "panel", "muted")
chips := []
SetF("s9", FONT_SEMI)
Loop (YEAR_TO - YEAR_FROM + 1)
    chips.Push(AddCtl("Text", "Center +0x200", YEAR_FROM + A_Index - 1, "chip", "accentText"))

ctl.Div2 := AddCtl("Text", "", "", "border")
navExit := MakeNav(0xE7E8, "Exit", (*) => ExitApp())

; ---- Top bar: menus and the theme button ----
fileMenu := Menu()
fileMenu.Add("Add Configuration", (*) => ShowView("main"))
fileMenu.Add("Remove Configurations", (*) => ShowView("remove"))
fileMenu.Add()
fileMenu.Add("Exit", (*) => ExitApp())
helpMenu := Menu()
helpMenu.Add("How to use FABconfig", (*) => ShowView("help"))
helpMenu.Add("Online instructions`t↗", (*) => OpenInstructions())
helpMenu.Add()
helpMenu.Add("What's this?", (*) => ShowView("about"))
menuFile := MakeMenu("File", fileMenu)
menuHelp := MakeMenu("Help", helpMenu)
btnTheme := MakeButton(Ord(ThemeGlyph()), "", "btn", "btnHover", "text", ToggleTheme, true)

; ---- Status bar ----
SetF("s9")
ctl.StatusL := AddCtl("Text", "+0x200", StatusText(), "panel", "muted")
ctl.StatusR := AddCtl("Text", "Right +0x200", APP_VERSION, "panel", "muted")

; ---- Main view ----
ctl.Banner := AddCtl("Text", "", "", "soft")
SetF("s12", ICON_FONT)
ctl.BannerIcon := AddCtl("Text", "Center +0x200", Chr(0xE946), "soft", "accentText")   ; Info glyph
SetF("s10")
ctl.BannerText := AddCtl("Text", "+0x200", "Add this database to Autodesk Fabrication as a configuration.", "soft", "text")
mainCtrls.Push(ctl.Banner, ctl.BannerIcon, ctl.BannerText)
btnHow := MakeButton(0, "How it works…", "btn", "btnHover", "text", (*) => ShowView("about"), true, mainCtrls)

ctl.CardEdge := AddCtl("Text", "", "", "border")
ctl.Card     := AddCtl("Text", "", "", "card")
SetF("s12", FONT_SEMI)
ctl.CardTitle := AddCtl("Text", "", "Configuration details", "card", "text")
SetF("s9")
ctl.NameLbl := AddCtl("Text", "", "Configuration name", "card", "muted")
mainCtrls.Push(ctl.CardEdge, ctl.Card, ctl.CardTitle, ctl.NameLbl)
fName := MakeField(DB_NAME)
SetF("s9")
ctl.LocLbl := AddCtl("Text", "", "Configuration location", "card", "muted")
mainCtrls.Push(ctl.LocLbl)
fLoc := MakeField(CONFIG_ROOT "\" DB_NAME)   ; just the root if there's no DBNAME
btnBrowse := MakeButton(0xE838, "Browse…", "btn", "btnHover", "text", BrowseLocation, true, mainCtrls)
SetF("s9")
ctl.ProjLbl := AddCtl("Text", "", "ESTmep or CAMduct Project Location (optional)", "card", "muted")
mainCtrls.Push(ctl.ProjLbl)
fProj := MakeField("")   ; blank = a "projects" folder inside the configuration location
btnProj := MakeButton(0xE838, "Browse…", "btn", "btnHover", "text", BrowseProject, true, mainCtrls)
SetF("s9")
ctl.DbLbl := AddCtl("Text", "", "Fabrication database folder", "card", "muted")
mainCtrls.Push(ctl.DbLbl)
fDb := MakeField(DB_DIR != "" ? DB_DIR : NO_DB_TEXT, true)
btnDb := MakeButton(0xE838, "Browse…", "btn", "btnHover", "text", ChooseDatabase, true, mainCtrls)
btnCreate := MakeButton(0xE710, "Create Configuration", "accent", "accentHover", "onAccent", SaveConfig, false, mainCtrls, true)

ctl.Name := fName.Edit
ctl.Loc  := fLoc.Edit
ctl.Proj := fProj.Edit
ctl.Name.OnEvent("Change", OnNameChange)
ctl.Loc.OnEvent("Change", OnLocChange)

; Enter key saves (a hidden default button)
AddCtl("Button", "Default Hidden", "Save").OnEvent("Click", (*) => (currentView = "main") && SaveConfig())

; ---- Remove view (formerly FABclean) ----
ctl.RBanner := AddCtl("Text", "", "", "soft")
SetF("s12", ICON_FONT)
ctl.RBannerIcon := AddCtl("Text", "Center +0x200", Chr(0xE946), "soft", "accentText")
SetF("s10")
ctl.RBannerText := AddCtl("Text", "+0x200", "Fabrication configurations registered on this PC. Close Fabrication before removing any.", "soft", "text")
ctl.RCardEdge := AddCtl("Text", "", "", "border")
ctl.RCard     := AddCtl("Text", "", "", "card")
SetF("s12", FONT_SEMI)
ctl.RCardTitle := AddCtl("Text", "", "Configurations", "card", "text")
SetF("s9")
ctl.RHint := AddCtl("Text", "", "Tick the ones to remove. Nothing is ticked for you.", "card", "muted")
ctl.LvEdge := AddCtl("Text", "", "", "border")
SetF("s10")
lv := AddCtl("ListView", "Checked -E0x200 +LV0x10000 +LV0x20 -Multi"
    , ["Name", "Folder", "Versions", "Made by"], "card", "text")
ctl.Empty := AddCtl("Text", "Center", "No Fabrication configurations found.", "card", "muted")
; A themed checkbox ignores the text color, so the box has no text of its own
; and a separate label (which toggles it) carries the text.
ctl.Recycle := AddCtl("Checkbox", "Checked", "", "card")
ctl.RecycleLbl := AddCtl("Text", "+0x200", "Also move each folder to the Recycle Bin", "card", "text")
ctl.RecycleLbl.OnEvent("Click", (*) => ctl.Recycle.Value := !ctl.Recycle.Value)
removeCtrls.Push(ctl.RBanner, ctl.RBannerIcon, ctl.RBannerText, ctl.RCardEdge, ctl.RCard, ctl.RCardTitle
    , ctl.RHint, ctl.LvEdge, lv, ctl.Recycle, ctl.RecycleLbl)
btnRefresh := MakeButton(0xE72C, "Refresh", "btn", "btnHover", "text", (*) => RefreshConfigs(), true, removeCtrls)
btnRemove  := MakeButton(0xE74D, "Remove selected", "danger", "dangerHover", "onAccent", RemoveChecked, false, removeCtrls, true)

; The list's header asks the list how to draw its column titles
; (NM_CUSTOMDRAW); the list is subclassed to give them the text color.
lvHdr := SendMessage(0x101F, 0, 0, lv)   ; LVM_GETHEADER
DllCall("comctl32\SetWindowSubclass", "ptr", lv.Hwnd, "ptr", CallbackCreate(LvSubclass, , 6), "uptr", 1, "uptr", 0)

; ---- Help view (How to use FABconfig) ----
SetF("s13", FONT_SEMI)
ctl.HHead := AddCtl("Text", "", "How to use FABconfig", "bg", "text")
SetF("s10")
ctl.HSub := AddCtl("Text", "", "Close Fabrication first. Changes show the next time Fabrication starts.", "bg", "muted")
helpCtrls.Push(ctl.HHead, ctl.HSub)
helpCards := []
for card in [{Title: "Add a configuration", Body: HELP_ADD}, {Title: "Remove configurations", Body: HELP_REMOVE}] {
    card.Edge := AddCtl("Text", "", "", "border")
    card.Bg   := AddCtl("Text", "", "", "card")
    SetF("s11", FONT_SEMI)
    card.Head := AddCtl("Text", "", card.Title, "card", "text")
    SetF("s10")
    card.Text := AddCtl("Text", "", card.Body, "card", "text")
    helpCtrls.Push(card.Edge, card.Bg, card.Head, card.Text)
    helpCards.Push(card)
}
ctl.HStrip := AddCtl("Text", "", "", "soft")
SetF("s10")
ctl.HStripText := AddCtl("Text", "+0x200", "More detail and screenshots are in the online instructions.", "soft", "text")
helpCtrls.Push(ctl.HStrip, ctl.HStripText)
btnOnline := MakeButton(0xE8A7, "Open online instructions", "btn", "btnHover", "text", (*) => OpenInstructions(), true, helpCtrls)

; ---- About view ----
SetF("s13", FONT_SEMI)
ctl.AHead := AddCtl("Text", "", "What this program does", "bg", "text")
SetF("s10")
ctl.ASub := AddCtl("Text", "", "Here's what happens when you click Create Configuration.", "bg", "muted")
aboutCtrls.Push(ctl.AHead, ctl.ASub)

for i, st in STEPS {
    st.Edge := AddCtl("Text", "", "", "border")
    st.Bg   := AddCtl("Text", "", "", "card")
    SetF("s10", FONT_SEMI)
    st.Num  := AddCtl("Text", "Center +0x200", i, "chip", "accentText")
    st.Head := AddCtl("Text", "", st.Title, "card", "text")
    SetF("s9")
    st.Desc := AddCtl("Text", "", st.Text, "card", "muted")
    aboutCtrls.Push(st.Edge, st.Bg, st.Num, st.Head, st.Desc)
}

ctl.AEdge := AddCtl("Text", "", "", "border")
ctl.ACard := AddCtl("Text", "", "", "card")
SetF("s10")
ctl.ABody := AddCtl("Text", "", ABOUT_TEXT, "card", "text")
; The VBS logo stays on this page, beside the copyright line.
badgeBmp := LoadPng("VBS_LOGO_BADGE", LOGO_BADGE, S(32), "FFFFFF")
if badgeBmp
    ctl.Badge := AddCtl("Picture", "w" S(32) " h" S(32), "HBITMAP:" badgeBmp)
else
    ctl.Badge := AddCtl("Text", "", "", "card")
SetF("s9")
ctl.ACopy := AddCtl("Text", "", COPYRIGHT_TEXT, "card", "muted")
aboutCtrls.Push(ctl.AEdge, ctl.ACard, ctl.ABody, ctl.Badge, ctl.ACopy)

;======================= Show window ================================
MonitorGetWorkArea(MonitorGetPrimary(), &waL, &waT, &waR, &waB)
winW := Min(S(1180), waR - waL - S(40))
winH := Min(S(640), waB - waT - S(60))
g.Opt("+MinSize" winW "x" winH)

StackControls()
RefreshConfigs()
ShowView("main")
Layout(winW, winH)
SetControlThemes()
SetTitleBarTheme()
g.Show("w" winW " h" winH)
ctl.Name.Focus()
if (DB_DIR = "")
    ChooseDatabase()
return

;======================= Building blocks ============================
SetF(opts, face := FONT) => g.SetFont("norm " opts, face)

; The color for a role name in the current theme.
Clr(role) => THEMES[theme].%role%

; Every control goes through AddCtl so we know the order it was created in.
; +0x4000000 (WS_CLIPSIBLINGS) stops a control from painting over the
; controls stacked on top of it (for example a card painting over its text).
; bg and fg are color roles; they are re-applied when the theme changes.
AddCtl(type, opts := "", text := "", bg := "", fg := "") {
    if (bg != "")
        opts := "Background" Clr(bg) " " opts
    if (fg != "")
        g.SetFont("c" Clr(fg))
    c := g.Add(type, opts " +0x4000000", text)
    created.Push(c)
    if (bg != "" || fg != "")
        themed.Push({C: c, Bg: bg, Fg: fg})
    return c
}

; Windows stacks each new control *underneath* the ones before it, so the
; cards and the sidebar (created first) were covering everything placed on
; them. Re-stack so each control sits above the ones created before it.
StackControls() {
    for c in created
        DllCall("SetWindowPos", "ptr", c.Hwnd, "ptr", 0   ; 0 = HWND_TOP
            , "int", 0, "int", 0, "int", 0, "int", 0
            , "uint", 0x213)                             ; NOMOVE|NOSIZE|NOACTIVATE|NOOWNERZORDER
}

; A group is a set of controls that act as one clickable item with a hover
; color. Normal and Hover are color roles.
NewGroup(normal, hover, onClick) {
    grp := {Id: groups.Length + 1, Normal: normal, Hover: hover, OnClick: onClick, Parts: []}
    groups.Push(grp)
    return grp
}

AddPart(grp, ctrl) {
    grp.Parts.Push(ctrl)
    hoverMap[ctrl.Hwnd] := grp.Id
    ctrl.OnEvent("Click", (*) => grp.OnClick.Call())
    return ctrl
}

Paint(grp, role) {
    for c in grp.Parts
        c.Opt("+Background" Clr(role))
    for c in grp.Parts
        RedrawCtl(c)
}

; Repaint one control right away (honoring the controls stacked on top of it).
RedrawCtl(c) {
    DllCall("RedrawWindow", "ptr", c.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x185)   ; INVALIDATE|ERASE|ALLCHILDREN|UPDATENOW
}

; A sidebar item: a rounded pill that is filled with the accent color when selected.
MakeNav(glyph, label, onClick) {
    grp := NewGroup("panel", "navHover", onClick)
    grp.Bg := AddPart(grp, AddCtl("Text", "", "", "panel"))
    SetF("s12", ICON_FONT)
    grp.Icon := AddPart(grp, AddCtl("Text", "Center +0x200", Chr(glyph), "panel", "text"))
    SetF("s11")
    grp.Label := AddPart(grp, AddCtl("Text", "+0x200", label, "panel", "text"))
    return grp
}

SetNavActive(grp, on) {
    grp.Normal := on ? "accent" : "panel"
    grp.Hover := on ? "accent" : "navHover"
    fg := Clr(on ? "onAccent" : "text")
    grp.Icon.SetFont("c" fg)
    grp.Label.SetFont("c" fg)
    Paint(grp, grp.Normal)
}

; A top-bar menu title (File, Help) that drops down a menu.
MakeMenu(label, m) {
    grp := NewGroup("bg", "btn", (*) => ShowMenu(grp, m))
    SetF("s10")
    grp.Bg := AddPart(grp, AddCtl("Text", "Center +0x200", label, "bg", "text"))
    return grp
}

ShowMenu(grp, m) {
    grp.Bg.GetPos(&x, &y, , &h)
    SetHot(0)
    m.Show(x, y + h)
}

; A button: glyph and/or label on a rounded fill. bordered adds a 1px outline
; (the outline isn't a part, so it keeps its color on hover). glyph 0 = no
; icon, label "" = icon only. Its controls are added to list (a view's
; control list) when given.
MakeButton(glyph, label, base, hover, fg, onClick, bordered := false, list := 0, semi := false) {
    grp := NewGroup(base, hover, onClick)
    if bordered
        grp.Edge := AddCtl("Text", "", "", "edge")
    grp.Bg := AddPart(grp, AddCtl("Text", "", "", base))
    SetF("s11", ICON_FONT)
    grp.Icon := AddPart(grp, AddCtl("Text", "Center +0x200", glyph ? Chr(glyph) : "", base, fg))
    SetF("s10", semi ? FONT_SEMI : FONT)
    grp.Label := AddPart(grp, AddCtl("Text", "+0x200", label, base, fg))
    grp.Label.GetPos(, , &lw)            ; added without a width, so this is the text's width
    grp.LabelW := label = "" ? 0 : lw / SCALE
    grp.HasIcon := glyph != 0
    if list {
        if bordered
            list.Push(grp.Edge)
        list.Push(grp.Parts*)
    }
    return grp
}

; A rounded text box: a border layer (turns accent-colored when focused), a
; fill layer, and a borderless Edit on top. isStatic shows read-only text instead.
MakeField(value, isStatic := false) {
    f := {Focused: false}
    f.Border := AddCtl("Text", "", "", "edge")
    f.Fill   := AddCtl("Text", "", "", "field")
    SetF("s10")
    if isStatic {
        f.Edit := AddCtl("Text", "+0x8000 +0x200", value, "field", "text")   ; 0x8000: shorten long paths with "..."
    } else {
        f.Edit := AddCtl("Edit", "-E0x200 r1 -Wrap", value, "field", "text")
        f.Edit.OnEvent("Focus",     (*) => FieldFocus(f, true))
        f.Edit.OnEvent("LoseFocus", (*) => FieldFocus(f, false))
    }
    fields.Push(f)
    mainCtrls.Push(f.Border, f.Fill, f.Edit)
    return f
}

FieldFocus(f, on) {
    f.Focused := on
    f.Border.Opt("+Background" Clr(on ? "accent" : "edge"))
    RedrawCtl(f.Border)
    RedrawCtl(f.Fill)
    RedrawCtl(f.Edit)
}

; Loads a PNG (built into the compiled .exe as an RT_RCDATA resource, or from
; file when running the script) and draws it at size x size pixels with GDI+,
; over the background color bg (hex RGB) where the PNG is transparent.
; Returns an HBITMAP, or 0 if the picture isn't there.
LoadPng(resName, file, size, bg) {
    stream := 0, src := 0, hbm := 0
    if A_IsCompiled {
        stream := ResourceStream(resName)
        if !stream
            return 0
    } else if !FileExist(file) {
        return 0
    }
    DllCall("LoadLibrary", "str", "gdiplus")
    si := Buffer(24, 0), NumPut("uint", 1, si)                ; GdiplusStartupInput, version 1
    token := 0
    DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", si, "ptr", 0)
    if stream
        DllCall("gdiplus\GdipCreateBitmapFromStream", "ptr", stream, "ptr*", &src)
    else
        DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", file, "ptr*", &src)
    if src {
        ; Draw onto a size x size bitmap with high-quality scaling (the PNGs are
        ; 256 px), then convert it over the background color.
        dst := 0, gfx := 0
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", size, "int", size, "int", 0, "int", 0x26200A, "ptr", 0, "ptr*", &dst)   ; 32bppARGB
        DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", dst, "ptr*", &gfx)
        DllCall("gdiplus\GdipSetInterpolationMode", "ptr", gfx, "int", 7)      ; HighQualityBicubic
        DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", gfx, "int", 4)        ; HighQuality
        DllCall("gdiplus\GdipDrawImageRectI", "ptr", gfx, "ptr", src, "int", 0, "int", 0, "int", size, "int", size)
        DllCall("gdiplus\GdipDeleteGraphics", "ptr", gfx)
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", dst, "ptr*", &hbm, "uint", 0xFF000000 | Integer("0x" bg))
        DllCall("gdiplus\GdipDisposeImage", "ptr", dst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", src)
    }
    if stream
        ObjRelease(stream)
    DllCall("gdiplus\GdiplusShutdown", "ptr", token)
    return hbm
}

; A memory stream over a resource that AddResource built into the .exe, or 0.
ResourceStream(name) {
    hMod := DllCall("GetModuleHandle", "ptr", 0, "ptr")
    hRes := DllCall("FindResource", "ptr", hMod, "str", name, "ptr", 10, "ptr")   ; 10 = RT_RCDATA
    if !hRes
        return 0
    bytes := DllCall("SizeofResource", "ptr", hMod, "ptr", hRes, "uint")
    pData := DllCall("LockResource", "ptr", DllCall("LoadResource", "ptr", hMod, "ptr", hRes, "ptr"), "ptr")
    return DllCall("shlwapi\SHCreateMemStream", "ptr", pData, "uint", bytes, "ptr")
}

;======================= Theme ======================================
ThemeGlyph() => Chr(theme = "dark" ? 0xE708 : 0xE706)   ; moon in dark, sun in light

ToggleTheme(*) {
    global theme := (theme = "dark") ? "light" : "dark"
    try RegWrite(theme, "REG_SZ", SETTINGS_KEY, "Theme")
    SetHot(0)
    ApplyTheme()
}

; Re-applies every control's color roles in the current theme.
ApplyTheme() {
    g.BackColor := Clr("bg")
    for r in themed {
        if (r.Bg != "")
            r.C.Opt("+Background" Clr(r.Bg))
        if (r.Fg != "")
            r.C.SetFont("c" Clr(r.Fg))
    }
    for f in fields
        if f.Focused
            f.Border.Opt("+Background" Clr("accent"))
    btnTheme.Icon.Text := ThemeGlyph()
    if (ctl.Tile.Type = "Pic") {
        ; The icon's rounded corners are drawn over the sidebar color.
        if (bmp := LoadPng("FABCONFIG_ICON", APP_PNG, S(34), Clr("panel")))
            ctl.Tile.Value := "HBITMAP:" bmp
    }
    SetControlThemes()
    SetTitleBarTheme()
    g.GetClientPos(, , &w, &h)
    Layout(w, h)
    SetNavActive(navMain,   currentView = "main")
    SetNavActive(navRemove, currentView = "remove")
    DllCall("RedrawWindow", "ptr", g.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x185)
}

; A dark title bar in the dark theme (Windows 10 20H1 and later; older
; versions ignore it).
SetTitleBarTheme() {
    dark := theme = "dark"
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", g.Hwnd, "int", 20, "int*", dark, "int", 4)   ; DWMWA_USE_IMMERSIVE_DARK_MODE
    DllCall("SetWindowPos", "ptr", g.Hwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0
        , "uint", 0x37)   ; FRAMECHANGED|NOMOVE|NOSIZE|NOZORDER|NOACTIVATE: redraw the title bar
}

; Dark list header, scroll bars, checkbox and menus in the dark theme. Windows
; only draws these dark once the app opts into dark mode, through uxtheme
; functions that have no names, only ordinals: 135 SetPreferredAppMode
; (2 = dark, 3 = light), 136 FlushMenuThemes, 133 AllowDarkModeForWindow.
SetControlThemes() {
    dark := theme = "dark"
    try {
        ux := DllCall("LoadLibrary", "str", "uxtheme", "ptr")
        DllCall(DllCall("GetProcAddress", "ptr", ux, "ptr", 135, "ptr"), "int", dark ? 2 : 3)
        DllCall(DllCall("GetProcAddress", "ptr", ux, "ptr", 136, "ptr"))
        allow := DllCall("GetProcAddress", "ptr", ux, "ptr", 133, "ptr")
        DllCall(allow, "ptr", lv.Hwnd, "int", dark)
        DllCall(allow, "ptr", lvHdr, "int", dark)
    }
    DllCall("uxtheme\SetWindowTheme", "ptr", lv.Hwnd, "str", dark ? "DarkMode_Explorer" : "Explorer", "ptr", 0)
    DllCall("uxtheme\SetWindowTheme", "ptr", lvHdr, "str", dark ? "DarkMode_ItemsView" : "ItemsView", "ptr", 0)
    DllCall("uxtheme\SetWindowTheme", "ptr", ctl.Recycle.Hwnd, "str", dark ? "DarkMode_Explorer" : "Explorer", "ptr", 0)
}

LvSubclass(hwnd, msg, wParam, lParam, id, ref) {
    ; WM_NOTIFY from the header, NM_CUSTOMDRAW (-12). NMHDR is 3 pointer-sized
    ; fields; NMCUSTOMDRAW then has dwDrawStage and, a pointer further, the hdc.
    if (msg = 0x4E && NumGet(lParam, 0, "ptr") = lvHdr && NumGet(lParam, 2 * A_PtrSize, "int") = -12) {
        stage := NumGet(lParam, 3 * A_PtrSize, "uint")
        if (stage = 1)                   ; CDDS_PREPAINT
            return 0x20                  ; CDRF_NOTIFYITEMDRAW
        if (stage = 0x10001) {           ; CDDS_ITEMPREPAINT
            rgb := Clr("text")           ; COLORREF is BGR
            bgr := (Integer("0x" SubStr(rgb, 5, 2)) << 16) | (Integer("0x" SubStr(rgb, 3, 2)) << 8) | Integer("0x" SubStr(rgb, 1, 2))
            DllCall("SetTextColor", "ptr", NumGet(lParam, 4 * A_PtrSize, "ptr"), "uint", bgr)
            return 0                     ; CDRF_DEFAULT
        }
    }
    return DllCall("comctl32\DefSubclassProc", "ptr", hwnd, "uint", msg, "ptr", wParam, "ptr", lParam, "ptr")
}

; The "How to use it" section of the README on GitHub, in the default browser.
OpenInstructions() {
    try Run(README_URL)
    catch
        MsgBox("Couldn't open your web browser. The instructions are at:`n" README_URL, APP_NAME, "Iconi")
}

StatusText() {
    if (currentView = "remove") {
        ours := 0
        for c in configs
            ours += c.Ours
        n := configs.Length
        return n " configuration" (n = 1 ? "" : "s") " on this PC · " ours " made by FABconfig"
    }
    if (DB_DIR = "")
        return "No database selected"
    SplitPath(DB_DIR, &folder)
    return "Database: " folder
}

;======================= Layout =====================================
OnResize(guiObj, minMax, w, h) {
    if (minMax = -1)
        return
    Layout(w, h)
}

; Move a control using 100%-scale units; r rounds its corners.
M(ctrl, x, y, w, h, r := 0) {
    ctrl.Move(S(x), S(y), S(w), S(h))
    if r
        RoundCorners(ctrl, S(r))
}

RoundCorners(ctrl, r) {
    ctrl.GetPos(, , &w, &h)
    rgn := DllCall("CreateRoundRectRgn", "int", 0, "int", 0, "int", w + 1, "int", h + 1, "int", r, "int", r, "ptr")
    DllCall("SetWindowRgn", "ptr", ctrl.Hwnd, "ptr", rgn, "int", true)
}

; A card with a 1px border: the border layer and the fill on top of it.
PlaceCard(edge, fill, x, y, w, h, r := 10) {
    M(edge, x,     y,     w,     h,     r)
    M(fill, x + 1, y + 1, w - 2, h - 2, r)
}

PlaceNav(grp, y, SB) {
    M(grp.Bg,    12, y,     SB - 24, 40, 8)
    M(grp.Icon,  22, y + 4, 24,      32)
    M(grp.Label, 54, y + 4, SB - 72, 32)
}

PlaceButton(grp, x, y, w, h, r := 6) {
    if grp.HasProp("Edge")
        PlaceCard(grp.Edge, grp.Bg, x, y, w, h, r)
    else
        M(grp.Bg, x, y, w, h, r)
    if (grp.LabelW = 0) {                ; icon only
        M(grp.Icon,  x + 1, y + 1, w - 2, h - 2)
        M(grp.Label, x, y, 0, 0)
        return
    }
    iw := grp.HasIcon ? 28 : 0           ; icon (20) and the gap after it (8)
    lw := Min(grp.LabelW + 4, w - iw - 16)
    sx := x + (w - (iw + lw)) / 2        ; center icon + label together
    M(grp.Icon,  sx,      y + 1, iw ? 20 : 0, h - 2)
    M(grp.Label, sx + iw, y + 1, lw,          h - 2)
}

PlaceField(f, x, y, w, h := 34) {
    PlaceCard(f.Border, f.Fill, x, y, w, h, 6)
    M(f.Edit, x + 10, y + 7, w - 20, h - 14)
}

Layout(w, h) {
    W := w / SCALE, H := h / SCALE      ; work in 100%-scale units
    SB  := 248                          ; sidebar width
    SBH := H - 30                       ; height above the status bar

    ; ---- Sidebar ----
    M(ctl.Side,     0,  0, SB, SBH)
    M(ctl.SideLine, SB, 0, 1,  SBH)
    M(ctl.Tile,     16, 16, 34, 34, ctl.Tile.Type = "Pic" ? 0 : 8)
    M(ctl.AppName,  60, 16, SB - 72, 34)
    PlaceNav(navMain,   64,  SB)
    PlaceNav(navRemove, 110, SB)
    M(ctl.Div1,    12, 162, SB - 24, 1)
    M(ctl.VerHead, 16, 176, SB - 32, 16)
    M(ctl.VerSub,  16, 194, SB - 32, 18)
    perRow := 3, gap := 6
    chipW := (SB - 32 - (perRow - 1) * gap) / perRow
    for i, chip in chips {
        r := (i - 1) // perRow, c := Mod(i - 1, perRow)
        M(chip, 16 + c * (chipW + gap), 220 + r * 32, chipW, 26, 26)
    }
    M(ctl.Div2, 12, SBH - 60, SB - 24, 1)
    PlaceNav(navExit, SBH - 52, SB)

    ; ---- Top bar ----
    mx := SB + 1, mw := W - mx
    M(ctl.Top,     mx, 0,  mw, 48)
    M(ctl.TopLine, mx, 48, mw, 1)
    M(menuFile.Bg, mx + 12, 9, 48, 30, 6)
    M(menuHelp.Bg, mx + 62, 9, 52, 30, 6)
    PlaceButton(btnTheme, W - 12 - 36, 9, 36, 30)

    ; ---- Status bar ----
    M(ctl.StatusLine, 0,      SBH,     W,       1)
    M(ctl.Status,     0,      SBH + 1, W,       29)
    M(ctl.StatusL,    14,     SBH + 1, W - 170, 29)
    M(ctl.StatusR,    W - 154, SBH + 1, 140,    29)

    pad := 20
    x0  := mx + pad
    cw  := W - x0 - pad                 ; content width
    top := 48 + 18

    ; ---- Main view ----
    bh := 46, hw := 140
    M(ctl.Banner,     x0,      top, cw,               bh, 10)
    M(ctl.BannerIcon, x0 + 12, top, 26,               bh)
    M(ctl.BannerText, x0 + 46, top, cw - 46 - hw - 20, bh)
    PlaceButton(btnHow, x0 + cw - hw - 8, top + 8, hw, 30)

    cy := top + bh + 16
    ch := Max(418, SBH - 18 - cy)       ; fill the window height; 418 fits the fields and button
    PlaceCard(ctl.CardEdge, ctl.Card, x0, cy, cw, ch)
    ix := x0 + 22, iw := cw - 44
    M(ctl.CardTitle, ix, cy + 18, iw, 26)
    y := cy + 56
    M(ctl.NameLbl, ix, y, iw, 18)
    PlaceField(fName, ix, y + 22, iw)
    y += 72
    bw := 118
    M(ctl.LocLbl, ix, y, iw, 18)
    PlaceField(fLoc, ix, y + 22, iw - bw - 8)
    PlaceButton(btnBrowse, ix + iw - bw, y + 22, bw, 34)
    y += 72
    M(ctl.ProjLbl, ix, y, iw, 18)
    PlaceField(fProj, ix, y + 22, iw - bw - 8)
    PlaceButton(btnProj, ix + iw - bw, y + 22, bw, 34)
    y += 72
    M(ctl.DbLbl, ix, y, iw, 18)
    PlaceField(fDb, ix, y + 22, iw - bw - 8)
    PlaceButton(btnDb, ix + iw - bw, y + 22, bw, 34)
    PlaceButton(btnCreate, ix + iw - 230, cy + ch - 20 - 40, 230, 40, 8)

    ; ---- Remove view ----
    M(ctl.RBanner,     x0,      top, cw,      bh, 10)
    M(ctl.RBannerIcon, x0 + 12, top, 26,      bh)
    M(ctl.RBannerText, x0 + 46, top, cw - 60, bh)
    PlaceCard(ctl.RCardEdge, ctl.RCard, x0, cy, cw, ch)
    M(ctl.RCardTitle, ix, cy + 18, iw, 26)
    M(ctl.RHint,      ix, cy + 46, iw, 18)
    by  := cy + ch - 20 - 40             ; button row
    lvY := cy + 74, lvH := by - 48 - lvY
    PlaceCard(ctl.LvEdge, lv, ix, lvY, iw, lvH, 0)
    M(ctl.Empty, ix + 1, lvY + lvH / 2 - 12, iw - 2, 24)
    M(ctl.Recycle,    ix,      by - 36, 18,      24)
    M(ctl.RecycleLbl, ix + 24, by - 36, iw - 24, 24)
    PlaceButton(btnRemove,  ix + iw - 210,            by, 210, 40, 8)
    PlaceButton(btnRefresh, ix + iw - 210 - 10 - 130, by, 130, 40, 8)
    fixed := 190 + 140 + 120             ; Folder takes whatever width is left
    lv.ModifyCol(1, S(190))
    lv.ModifyCol(2, S(Max(140, iw - 2 - fixed - 24)))
    lv.ModifyCol(3, S(140))
    lv.ModifyCol(4, S(120))

    ; ---- Help view ----
    M(ctl.HHead, x0, top,      cw, 30)
    M(ctl.HSub,  x0, top + 32, cw, 20)
    sh := 46, sy := SBH - 18 - sh
    hy := top + 62, hh := sy - 12 - hy
    hw2 := (cw - 12) / 2
    for i, card in helpCards {
        hx := x0 + (i - 1) * (hw2 + 12)
        PlaceCard(card.Edge, card.Bg, hx, hy, hw2, hh)
        M(card.Head, hx + 18, hy + 16, hw2 - 36, 24)
        M(card.Text, hx + 18, hy + 48, hw2 - 36, hh - 60)
    }
    ow := 230
    M(ctl.HStrip,     x0,      sy, cw,                sh, 10)
    M(ctl.HStripText, x0 + 16, sy, cw - 16 - ow - 20, sh)
    PlaceButton(btnOnline, x0 + cw - ow - 8, sy + 8, ow, 30)

    ; ---- About view ----
    M(ctl.AHead, x0, top,      cw, 30)
    M(ctl.ASub,  x0, top + 32, cw, 20)
    ty := top + 66, th := 118
    tw := (cw - 3 * 12) / 4
    for i, st in STEPS {
        tx := x0 + (i - 1) * (tw + 12)
        PlaceCard(st.Edge, st.Bg, tx, ty, tw, th)
        M(st.Num,  tx + 14, ty + 14, 30,      30, 30)
        M(st.Head, tx + 14, ty + 52, tw - 28, 22)
        M(st.Desc, tx + 14, ty + 74, tw - 28, 38)
    }
    ay := ty + th + 14
    ah := Max(200, SBH - 18 - ay)
    PlaceCard(ctl.AEdge, ctl.ACard, x0, ay, cw, ah)
    M(ctl.ABody, x0 + 20, ay + 16,      cw - 40, ah - 16 - 64)
    M(ctl.Badge, x0 + 20, ay + ah - 52, 32,      32, 8)
    M(ctl.ACopy, x0 + 64, ay + ah - 56, cw - 84, 40)
}

;======================= Views and hover ============================
ShowView(name) {
    global currentView := name
    SetHot(0)
    for c in mainCtrls
        c.Visible := (name = "main")
    for c in removeCtrls
        c.Visible := (name = "remove")
    for c in helpCtrls
        c.Visible := (name = "help")
    for c in aboutCtrls
        c.Visible := (name = "about")
    ctl.Empty.Visible := (name = "remove") && (configs.Length = 0)
    SetNavActive(navMain,   name = "main")
    SetNavActive(navRemove, name = "remove")
    ctl.StatusL.Text := StatusText()
    if (name = "main")
        ctl.Name.Focus()
}

OnEscape(*) {
    if (currentView != "main")
        ShowView("main")
    else
        ExitApp()
}

OnMouseMove(wParam, lParam, msg, hwnd) {
    SetHot(hoverMap.Has(hwnd) ? hoverMap[hwnd] : 0)
}

; Polls while something is highlighted, to catch the mouse leaving the window.
CheckHover() {
    MouseGetPos(, , , &h, 2)
    SetHot((h && hoverMap.Has(h)) ? hoverMap[h] : 0)
}

SetHot(id) {
    global hotId
    if (id = hotId)
        return
    if hotId
        Paint(groups[hotId], groups[hotId].Normal)
    hotId := id
    if id {
        Paint(groups[id], groups[id].Hover)
        SetTimer(CheckHover, 50)
    } else {
        SetTimer(CheckHover, 0)
    }
}

OnSetCursor(wParam, lParam, msg, hwnd) {
    if hoverMap.Has(wParam) {
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32649, "ptr"))   ; hand
        return true
    }
}

;======================= Database folder ============================
; A folder counts as a Fabrication database if it has a map.ini or a DATABASE
; folder, and isn't a configuration folder.
IsDatabaseFolder(dir) => (FileExist(dir "\map.ini") || DirExist(dir "\DATABASE")) && !IsConfigFolder(dir)

; A configuration folder's map.ini points Main at a database somewhere else;
; a database's own map.ini points Main at itself (usually "."). The first-line
; marker can't tell them apart: VBS databases have it too.
IsConfigFolder(dir) {
    if !FileExist(dir "\map.ini")
        return false
    main := Trim(IniRead(dir "\map.ini", "PROGRAM PATHS", "Main", ""))
    if (main = "")
        return false
    main := StrReplace(main, "/", "\")
    if !RegExMatch(main, "^([A-Za-z]:|\\\\)")   ; relative to the map.ini's folder
        main := dir "\" main
    return RTrim(FullPath(main), "\") != RTrim(FullPath(dir), "\")
}

; Resolves "." and ".." in a path.
FullPath(p) {
    buf := Buffer(32768 * 2)
    n := DllCall("GetFullPathNameW", "str", p, "uint", 32768, "ptr", buf, "ptr", 0, "uint")
    return n ? StrGet(buf) : p
}

; True if FABconfig wrote this folder's map.ini. Only meaningful for a
; configuration folder, since VBS databases have the same first line.
HasMarker(dir) {
    try {
        f := FileOpen(dir "\map.ini", "r")   ; detects a UTF-8/UTF-16 BOM
        line := f.ReadLine()
        f.Close()
        return InStr(line, MAP_MARKER) = 1
    }
    return false
}

ChooseDatabase(*) {
    start := DB_DIR != "" ? "*" DB_DIR : ""
    prompt := "Select a folder that contains a Fabrication database"
    Loop {
        sel := DirSelect(start, 0, prompt)
        if (sel = "")                  ; cancelled
            return false
        sel := RTrim(sel, "\")
        if IsDatabaseFolder(sel) {
            SetDatabase(sel)
            return true
        }
        if IsConfigFolder(sel)
            why := "This is a Fabrication configuration folder, not a database. Its map.ini points to a database somewhere else:`n"
        else
            why := "This folder doesn't look like a Fabrication database (it has no map.ini or DATABASE folder):`n"
        if MsgBox(why sel "`n`nChoose a different folder?", APP_NAME, "RetryCancel Icon!") != "Retry"
            return false
        start := "*" sel
    }
}

SetDatabase(dir) {
    global DB_DIR := dir, DB_PATH := StrReplace(dir, "\", "/")
    global DB_NAME := Trim(IniRead(dir "\map.ini", "COMPANY-INFO", "DBNAME", ""))
    fDb.Edit.Text := dir
    ctl.StatusL.Text := StatusText()
    ; Fill in the name from the database, unless the user already typed one.
    if (Trim(ctl.Name.Value) = "" && DB_NAME != "") {
        ctl.Name.Value := DB_NAME
        OnNameChange()
    }
}

;======================= Inputs =====================================
; Keep the location in step with the name until the user picks their own.
OnNameChange(*) {
    global settingLoc
    if locTouched
        return
    name := Trim(ctl.Name.Value)
    settingLoc := true
    ctl.Loc.Value := CONFIG_ROOT "\" name   ; just the root while the name is blank
    settingLoc := false
}

OnLocChange(*) {
    global locTouched
    if !settingLoc
        locTouched := true
}

BrowseProject(*) {
    start := ctl.Proj.Value != "" ? "*" ctl.Proj.Value : ""
    sel := DirSelect(start, 3, "Select the folder for ESTmep or CAMduct projects.")
    if (sel != "")
        ctl.Proj.Value := RTrim(sel, "\")
}

BrowseLocation(*) {
    global locTouched
    start := ctl.Loc.Value != "" ? "*" ctl.Loc.Value : ""
    sel := DirSelect(start, 3, "Select the folder for this configuration.")
    if (sel = "")
        return
    locTouched := true
    ctl.Loc.Value := sel
}

;======================= Remove configurations =====================
; (This part was FABclean.) Lists the configurations under
; HKCU\Software\Autodesk\Fabrication <year>\Configuration, one row per name and
; folder. Only folders registered as configurations are ever touched: VBS
; databases' own map.ini files start with the same marker line, so the marker
; alone doesn't tell a configuration from a database.
FindConfigs() {
    found := Map()
    try {
        Loop Reg, "HKCU\Software\Autodesk", "K" {
            if !RegExMatch(A_LoopRegName, "^Fabrication (\d{4})$", &m)
                continue
            year := m[1]
            cfgRoot := "HKCU\Software\Autodesk\" A_LoopRegName "\Configuration"
            Loop Reg, cfgRoot, "K" {
                name := A_LoopRegName
                path := ""
                try path := RTrim(RegRead(cfgRoot "\" name, "Path"), "\")
                id := StrLower(name "|" path)
                if !found.Has(id)
                    found[id] := {Name: name, Path: path, Years: [], Keys: [], Ours: path != "" && HasMarker(path)}
                found[id].Years.Push(year)
                found[id].Keys.Push(cfgRoot "\" name)
            }
        }
    }
    return found
}

; Nothing is ticked for the user: every row starts unticked.
RefreshConfigs() {
    global configs := []
    lv.Delete()
    for id, c in FindConfigs() {
        configs.Push(c)
        lv.Add("", c.Name, c.Path != "" ? c.Path : "(no folder)", YearsText(c.Years)
            , c.Ours ? "FABconfig" : "Set up by hand")
    }
    ctl.Empty.Visible := (configs.Length = 0) && (currentView = "remove")
    ctl.StatusL.Text := StatusText()
}

; The years in order, with runs shortened: "2019, 2022–2028". The registry
; lists them in no particular order.
YearsText(y) {
    nums := StrSplit(Sort(JoinList(y, "`n"), "N U"), "`n")
    out := [], i := 1
    while (i <= nums.Length) {
        j := i
        while (j < nums.Length && nums[j + 1] = nums[j] + 1)
            j++
        out.Push(j > i ? nums[i] "–" nums[j] : nums[i])
        i := j + 1
    }
    return JoinList(out)
}

RemoveChecked(*) {
    picked := []
    keepPaths := Map()          ; folders still used by configurations being kept
    for i, c in configs {
        if (lv.GetNext(i - 1, "Checked") = i)
            picked.Push(c)
        else if (c.Path != "")
            keepPaths[StrLower(c.Path)] := true
    }
    if !picked.Length {
        MsgBox("Tick the configurations you want to remove.", APP_NAME, "Iconi")
        return
    }

    recycle := ctl.Recycle.Value
    msg := "Remove " (picked.Length = 1 ? "this configuration" : "these " picked.Length " configurations") "?`n"
    notOurs := 0
    for c in picked {
        msg .= "`n•  " c.Name "   (Fabrication " YearsText(c.Years) ")"
        if recycle && FolderCanGo(c, keepPaths) {
            msg .= "`n     Folder to Recycle Bin: " c.Path
            extra := ExtraItems(c.Path)
            if extra
                msg .= "`n     It also holds " extra " other item" (extra = 1 ? "" : "s") " (projects, backups, etc.)"
        }
        if !c.Ours
            notOurs++
    }
    if notOurs
        msg .= "`n`n" notOurs " of these " (notOurs = 1 ? "was" : "were") " set up by hand, not by FABconfig."
    if MsgBox(msg, APP_NAME, "YesNo Icon! Default2") != "Yes"
        return

    problems := ""
    done := 0
    for c in picked {
        ok := true
        for key in c.Keys {
            try RegDeleteKey(key)
            catch {
                ok := false
                problems .= "`n•  " c.Name ": couldn't remove " key
            }
        }
        if recycle && c.Path != "" && DirExist(c.Path) {
            if !FolderCanGo(c, keepPaths) {
                problems .= "`n•  " c.Name ": folder kept, because another configuration uses it or it isn't a safe folder to remove"
            } else {
                try FileRecycle(c.Path)
                catch {
                    ok := false
                    problems .= "`n•  " c.Name ": couldn't move " c.Path " to the Recycle Bin (is a file in it open?)"
                }
            }
        }
        done += ok
    }
    try DirDelete(CONFIG_ROOT)   ; tidy up the default folder, only if it's now empty

    RefreshConfigs()
    if (problems = "")
        MsgBox("Removed " done " configuration" (done = 1 ? "." : "s."), APP_NAME, "Iconi")
    else
        MsgBox("Removed " done " of " picked.Length ".`n`nSome things need attention:" problems, APP_NAME, "Icon!")
}

; Only recycle a real configuration folder: not a drive or share root, not
; this program's folder or the database, and not a folder another
; configuration still uses.
FolderCanGo(c, keepPaths) {
    p := c.Path
    if (p = "" || !DirExist(p))
        return false
    if RegExMatch(p, "^[A-Za-z]:$") || RegExMatch(p, "^\\\\[^\\]+\\[^\\]+$")
        return false
    if InStr(A_ScriptDir "\", p "\") = 1
        return false
    if (DB_DIR != "" && InStr(DB_DIR "\", p "\") = 1)
        return false
    if IsDatabaseFolder(p)
        return false
    return !keepPaths.Has(StrLower(p))
}

ExtraItems(path) {
    n := 0
    Loop Files path "\*", "FD" {
        if !(A_LoopFileName = "map.ini" || A_LoopFileName = "config.png")
            n++
    }
    return n
}

;======================= Save =======================================
SaveConfig(*) {
    name := Trim(ctl.Name.Value)
    dir  := RTrim(Trim(ctl.Loc.Value), "\")
    proj := RTrim(Trim(ctl.Proj.Value), "\")

    ; ---- Validate ----
    if (DB_DIR = "") {
        MsgBox("Choose the Fabrication database folder first.", APP_NAME, "Iconi")
        ShowView("main")
        ChooseDatabase()
        return
    }
    if (name = "")
        return Fail(ctl.Name, "Enter a configuration name.")
    if RegExMatch(name, '[\\/:*?"<>|]')
        return Fail(ctl.Name, "The configuration name can't contain any of these characters:`n\ / : * ? `" < > |")
    if (dir = "")
        return Fail(ctl.Loc, "Choose a configuration location.")
    if !RegExMatch(dir, "^([A-Za-z]:|\\\\)")
        return Fail(ctl.Loc, "The configuration location must be a full path, like`n" CONFIG_ROOT "\" name)
    if (dir = DB_DIR) || InStr(DB_DIR "\", dir "\") = 1
        return Fail(ctl.Loc, "The configuration location can't be the database folder or a folder that contains it.")
    if InStr(dir "\", DB_DIR "\") = 1
        return Fail(ctl.Loc, "The configuration location can't be inside the database folder. Choose a folder outside it, like`n" CONFIG_ROOT "\" name)
    if (proj != "") {
        if !RegExMatch(proj, "^([A-Za-z]:|\\\\)")
            return Fail(ctl.Proj, "The project location must be a full path, like`nC:\Fabrication Projects`n`nLeave it blank to keep projects in the configuration location.")
        if (proj = DB_DIR) || InStr(proj "\", DB_DIR "\") = 1
            return Fail(ctl.Proj, "The project location can't be the database folder or inside it. (Tools that mirror the database, such as robocopy /MIR, would delete it.)")
    }

    ; ---- Confirm before overwriting an existing configuration ----
    years := FabYears()
    found := FindConfig(name, years)
    if found.Years.Length {
        msg := 'A configuration named "' name '" already exists.`n`n'
            . "Registered with: Fabrication " JoinList(found.Years) "`n"
            . "Location:`n" JoinList(found.Paths, "`n") "`n"
        for p in found.Paths
            if FileExist(p "\map.ini") && !HasMarker(p) {
                msg .= "`nIt wasn't made by FABconfig, so it may have been set up by hand.`n"
                break
            }
        if (found.Paths.Length > 1 || found.Paths[1] != dir)
            msg .= "`nIt will point to the new location instead:`n" dir "`nThe old folder is left as it is.`n"
        else if FileExist(dir "\map.ini")
            msg .= "`nThe current map.ini will be kept as map.ini.bak.`n"
        if MsgBox(msg "`nOverwrite it?", APP_NAME, "YesNo Icon! Default2") != "Yes"
            return
    } else if FileExist(dir "\map.ini") {
        if MsgBox("This folder already has a map.ini:`n" dir
                . "`n`nOverwrite it? The current one will be kept as map.ini.bak.", APP_NAME, "YesNo Icon! Default2") != "Yes"
            return
    }

    ; ---- Create folder and files ----
    try {
        DirCreate(dir)
        ; Only the files we replace need to be writable.
        try FileSetAttrib("-R", dir "\config.png")
        try FileSetAttrib("-R", dir "\map.ini")
        try FileSetAttrib("-R", dir "\map.ini.bak")
        if FileExist(DB_DIR "\config.png")
            FileCopy(DB_DIR "\config.png", dir "\config.png", 1)
        ; Keep the previous map.ini (one level of backup).
        if FileExist(dir "\map.ini")
            FileMove(dir "\map.ini", dir "\map.ini.bak", 1)
        FileAppend(MapIniText(proj), dir "\map.ini", "CP0 `n")
        if (proj != "")
            DirCreate(proj)   ; so ESTmep and CAMduct find it
    } catch as err {
        MsgBox("Couldn't write the configuration files in`n" dir "`n`n" err.Message, APP_NAME, "Icon!")
        return
    }

    ; ---- Register with Fabrication ----
    ; Every year in the range, plus any other installed year it was already
    ; registered with, so an overwrite doesn't leave old entries behind.
    try {
        for year in years
            RegWrite(dir, "REG_SZ", RegKey(year, name), "Path")
    } catch as err {
        MsgBox("The files were created, but registering the configuration failed:`n`n" err.Message, APP_NAME, "Icon!")
        return
    }

    done := found.Years.Length ? "updated" : "added"
    MsgBox('Configuration "' name '" ' done '.`n`nIt will appear in the configuration list the next time you start Fabrication.'
        , APP_NAME, "Iconi")
    ExitApp()
}

; The Fabrication years to check and register: the YEAR_FROM-YEAR_TO range
; plus any other "Fabrication <year>" key already in the registry.
; Map keys are integers, so a for-loop returns them in order.
FabYears() {
    years := Map()
    Loop (YEAR_TO - YEAR_FROM + 1)
        years[YEAR_FROM + A_Index - 1] := true
    try {
        Loop Reg, "HKCU\Software\Autodesk", "K"
            if RegExMatch(A_LoopRegName, "^Fabrication (\d{4})$", &m)
                years[Integer(m[1])] := true
    }
    return years
}

; Which of those years have a configuration with this name, and the
; (distinct) folders they point to.
FindConfig(name, years) {
    found := {Years: [], Paths: []}
    seen := Map()
    seen.CaseSense := "Off"
    for year in years {
        p := RTrim(RegRead(RegKey(year, name), "Path", ""), "\")
        if (p = "")
            continue
        found.Years.Push(year)
        if !seen.Has(p) {
            seen[p] := true
            found.Paths.Push(p)
        }
    }
    return found
}

JoinList(items, sep := ", ") {
    out := ""
    for i, item in items
        out .= (i > 1 ? sep : "") item
    return out
}

Fail(edt, message) {
    MsgBox(message, APP_NAME, "Iconi")
    ShowView("main")
    edt.Focus()
}

RegKey(year, name) => "HKCU\Software\Autodesk\Fabrication " year "\Configuration\" name

; proj: the project folder the user chose, or "" for ./projects (a
; "projects" folder inside the configuration folder).
MapIniText(proj := "") {
    text := "
    (
# Created by Virtual Building Supply, LLC

[PROGRAM PATHS]
DXF=.
Blocks=.
Backup=.
Common={1}
Database={1}/database
Download=.
Images={1}/images
Items={1}/items
Main={1}
Profiles={1}/profiles
Project={2}
Reports={1}/reports
Scripts={1}/scripts
Textures=.

    )"
    return Format(text, DB_PATH, proj != "" ? StrReplace(proj, "\", "/") : "./projects")
}
