#RequireAdmin
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5 + put file SciTEUser.properties in your UserProfile e.g. C:\Users\User-10

 Author:        WIMB  -  June 08, 2020

 Program:       VHD_WIMBOOT_x64.exe - Version 2.9 in rule 157

 Script Function:

 Credits and Thanks to:
	Microsoft for making WIMBOOT - https://msdn.microsoft.com/en-us/library/dn631793.aspx and https://docs.microsoft.com/en-us/windows/win32/w8cookbook/windows-image-file-boot--wimboot-
	synchronicity aka Eric Biggers for making wimlib - https://wimlib.net/
	schtrom for making SVBus Virtual SCSI Host Adapter for GRUB4DOS - http://reboot.pro/topic/21787-svbus-virtual-scsi-host-adapter-for-grub4dos/
	alacran for support and info - http://reboot.pro/topic/21957-making-the-smallest-win10-install-wimboot-mode-on-512-mb-vhd/
		and http://reboot.pro/topic/21972-reducing-wimboot-source-wim-file-using-lzx-compression-and-vhd-using-gzip-or-lz4-compression-to-save-room-and-also-load-faster-on-ram/
	JFX for making WinNTSetup to Install Windows 2k/XP/2003/Vista/7/8/10 x86/x64 - https://msfn.org/board/topic/149612-winntsetup-v394/
	Uwe Sieber for making ListUsbDrives - http://www.uwe-sieber.de/english.html
	Pauly for making BOOTICE - available via http://reboot.pro/files/file/592-bootice-v1332/
                               and https://sites.google.com/site/gbrtools/home/software/bootice-portable/bootice-downloads
	chenall, yaya, tinybit and Bean for making Grub4dos - http://grub4dos.chenall.net/categories/downloads/

	Thanks to karyonix, alacran, Wonko the Sane, tinybit, yaya, chenall, cdob, JFX, steve6375, ReTokener, synchronicity, schtrom and Microsoft
	Development is described here - http://reboot.pro/topic/18182-uefi-multi-make-multi-boot-usb-drive/page-5

	The program is released "as is" and is free for redistribution, use or changes as long as original author,
	credits part and link to the reboot.pro support forum are clearly mentioned
	VHD_WIMBOOT - http://reboot.pro/topic/21977-vhd-wimboot-apply-and-capture-of-wim-files-for-os-in-vhd/

	Author does not take any responsibility for use or misuse of the program.

#ce ----------------------------------------------------------------------------

#include <guiconstants.au3>
#include <ProgressConstants.au3>
#include <GuiConstantsEx.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#Include <GuiStatusBar.au3>
#include <Array.au3>
#Include <String.au3>
#include <Process.au3>
#include <Date.au3>
#include <Constants.au3>
#include <WinAPIDlg.au3>

Opt('MustDeclareVars', 1)
Opt("GuiOnEventMode", 1)
Opt("TrayIconHide", 1)

; Declaration GUI variables
Global $hGuiParent, $ProgressAll, $hStatus, $EXIT, $DISK_TYPE, $WIMBOOT
Global $APPLY, $CAPTURE, $WIM_INFO, $VHD_INFO, $Update_WIMBOOT, $Make_Boot, $LZX, $VHD_TYPE, $VHDX, $ComboSize, $wimlib_dism
Global $WIM_FileSelect, $WIM_File, $WIM_Size_Label, $VHD_File, $VHD_FileSelect, $VHD_Size_Label
Global $TargetSel, $Target, $TargetSize, $TargetFree,  $WinDrv, $WinDrvSel, $WinDrvSize, $WinDrvFree
; Setting Other variables
Global $wimfile="", $WIM_Size=0, $vhdfile="", $VHDSize=0, $wimfolder = "", $vhdfolder = "", $VHDSpaceAvail=0, $VHD_Overflow=0
Global $TargetDrive="", $TargetSpaceAvail=0, $FSvar_TargetDrive="", $DriveType="Fixed", $Firmware = "UEFI", $PartStyle = "MBR"
Global $WinDrvDrive="", $WinDrvSpaceAvail=0, $FSvar_WinDrvDrive="", $DriveSysType="Fixed", $WIM_Path = ""

Global $inst_disk="", $inst_part="", $sys_disk="", $sys_part="", $usbsys=0, $usbfix=0

Global $driver_flag=0, $vhdmp=0, $SysWOW64=0, $WinFol="\Windows", $winload_flag=0, $PE_flag = 0
Global $bcdedit="", $winload = "winload.exe", $bcd_guid_outfile = "makebt\bs_temp\bcd_boot_vhd.txt", $store = "", $DistLang = "en-US", $WinLang = "en-US", $bcdboot_flag = 0
Global $tmpdrive = "", $PSize = "1.5 GB", $vhd_size="1500", $vhd_name = "W10x64_US_", $vhdfile_name ="W10x64_US_X.vhd", $vhdfile_name_only = ""

Global $str = "", $bt_files[12] = ["\makebt\grldr", "\makebt\menu.lst", "\makebt\menu_Linux.lst", "\makebt\menu_Win_ISO.lst", "\makebt\grldr.mbr", "\makebt\listusbdrives\ListUsbDrives.exe", _
"\makebt\WimBootCompress.ini", "\wimlib_x64\wimlib-imagex.exe", "\wimlib_x64\wiminfo.cmd", "\wimlib_x86\wimlib-imagex.exe", "\wimlib_x86\wiminfo.cmd", "\makebt\grub.exe"]

Global $config_file_wimboot=@ScriptDir & "\makebt\WimBootCompress.ini"

Global $OS_drive = StringLeft(@WindowsDir, 2), $ProgDrive = StringLeft(@ScriptDir, 2)

;~ 	If @OSArch <> "X86" Then
;~ 	   MsgBox(48, "ERROR - Environment", "In x64 environment use VHD_WIMBOOT_x64.exe ")
;~ 	   Exit
;~ 	EndIf

If @OSVersion = "WIN_VISTA" Or @OSVersion = "WIN_2003" Or @OSVersion = "WIN_XP" Or @OSVersion = "WIN_XPe" Or @OSVersion = "WIN_2000" Then
	MsgBox(48, "WARNING - OS Version is Not Valid ", "Use Windows 7/8/10 OS")
	Exit
EndIf


For $str In $bt_files
	If Not FileExists(@ScriptDir & $str) Then
		MsgBox(48, "ERROR - Missing File", "File " & $str & " NOT Found ")
		Exit
	EndIf
Next

If Not FileExists(@ScriptDir & "\makebt\wim_info") Then DirCreate(@ScriptDir & "\makebt\wim_info")

If Not FileExists(@ScriptDir & "\makebt\vhd_temp") Then DirCreate(@ScriptDir & "\makebt\vhd_temp")

SystemFileRedirect("On")
If StringLeft(@SystemDir, 1) = "X" Then
	$PE_flag = 1
	If Not FileExists(@WindowsDir & "\System32\drivers\wofadk.sys") And Not FileExists(@WindowsDir & "\System32\drivers\wof.sys") Then
		MsgBox(48, "ERROR - WOF Driver Missing", "wofadk.sys Or wof.sys driver is needed for WIMBOOT" & @CRLF _
		& @CRLF & "Please use Windows 10 Or 8.1 x64 OS with wof.sys driver")
		Exit
	EndIf
Else
	$PE_flag = 0
EndIf

If @OSVersion = "WIN_7" Then
	MsgBox(48, "WARNING - Windows 7 - Limitations", "Windows 7 Boot Manager cannot be used for VHD WIMBOOT" & @CRLF _
	& @CRLF & "Replace Boot and bootmgr in Boot Partition of Windows 7" & @CRLF _
	& @CRLF & "VHDX Files Not Compatible with Windows 7 Operating System" & @CRLF _
	& @CRLF & "In Windows 7 wofadk.sys driver is needed for WIMBOOT" & @CRLF _
	& @CRLF & "Better is use Windows 10 Or 8.1 x64 OS with wof.sys driver")
	If Not FileExists(@WindowsDir & "\System32\drivers\wofadk.sys") Then
		MsgBox(48, "ERROR - WOF Driver Missing", "In Windows 7 wofadk.sys driver is needed for WIMBOOT" & @CRLF _
		& @CRLF & "WinNTSetup will Install wofadk.sys driver in Windows 7" & @CRLF _
		& @CRLF & "Please use Windows 10 Or 8.1 x64 OS with wof.sys driver")
		Exit
	Else
		MsgBox(48, "wofadk.sys Driver Found - OK", "Windows 7 - wofadk.sys Driver Found - OK for WIMBOOT")
	EndIf
EndIf

If @OSVersion = "WIN_8" Then
	If Not FileExists(@WindowsDir & "\System32\drivers\wofadk.sys") And Not FileExists(@WindowsDir & "\System32\drivers\wof.sys") Then
		MsgBox(48, "ERROR - WOF Driver Missing", "wofadk.sys Or wof.sys driver is needed for WIMBOOT" & @CRLF _
		& @CRLF & "WinNTSetup will Install wofadk.sys driver in Windows 8" & @CRLF _
		& @CRLF & "Please use Windows 10 Or 8.1 x64 OS with wof.sys driver")
		Exit
	EndIf
EndIf

If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Then
	If Not FileExists(@WindowsDir & "\System32\drivers\wof.sys") Then
		MsgBox(48, "ERROR - WOF Driver Missing", "wof.sys driver is needed for WIMBOOT" & @CRLF _
		& @CRLF & "Please use Windows 10 Or 8.1 x64 OS with wof.sys driver")
		Exit
	EndIf
EndIf

If Not FileExists(@WindowsDir & "\System32\drivers\wofadk.sys") And Not FileExists(@WindowsDir & "\System32\drivers\wof.sys") Then
	MsgBox(48, "ERROR - WOF Driver Missing", "wofadk.sys Or wof.sys driver is needed for WIMBOOT" & @CRLF _
	& @CRLF & "Please use Windows 10 Or 8.1 x64 OS with wof.sys driver")
	Exit
EndIf

SystemFileRedirect("Off")

; Creating GUI and controls
$hGuiParent = GUICreate(" VHD_WIMBOOT x64 - APPLY WIM to VHD file ", 400, 430, -1, -1, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
GUISetOnEvent($GUI_EVENT_CLOSE, "_Quit")

GUICtrlCreateGroup("System Files - Version 2.9  -   OS = " & @OSVersion & " " & @OSArch & "  " & $Firmware, 18, 10, 364, 235)

GUICtrlCreateLabel( "  WIM File", 32, 29)
$WIM_Size_Label = GUICtrlCreateLabel( "", 130, 29, 60, 15, $ES_READONLY)
$WIM_File = GUICtrlCreateInput($WIM_FileSelect, 32, 45, 185, 20, $ES_READONLY)
$WIM_FileSelect = GUICtrlCreateButton("...", 223, 46, 26, 18)
GUICtrlSetTip($WIM_FileSelect, " Select WIM File for APPLY to VHD File ")
GUICtrlSetOnEvent($WIM_FileSelect, "_wim_fsel")

GUICtrlCreateLabel( "  VHD File", 32, 158)
$VHD_Size_Label = GUICtrlCreateLabel( "", 130, 158, 60, 15, $ES_READONLY)
$VHD_File = GUICtrlCreateInput($VHD_FileSelect, 32, 174, 185, 20, $ES_READONLY)
$VHD_FileSelect = GUICtrlCreateButton("...", 223, 175, 26, 18)
GUICtrlSetTip($VHD_FileSelect, " Select VHD File for Capture or Apply of WIM File ")
GUICtrlSetOnEvent($VHD_FileSelect, "_vhd_fsel")

$APPLY = GUICtrlCreateButton("APPLY", 285, 40, 70, 30)
GUICtrlSetOnEvent($APPLY, "_APPLY_WIM_ToVHD")
GUICtrlSetTip($APPLY, " Apply WIM Image File to VHD File ")

$CAPTURE = GUICtrlCreateButton("CAPTURE", 285, 83, 70, 30)
GUICtrlSetOnEvent($CAPTURE, "_CAPTURE_VHD_ToWIM")
GUICtrlSetTip($CAPTURE, " Capture WIM Image File from VHD File " & @CRLF _
& " Switch Windows Defender Off for Faster Capture ")

$WIM_INFO = GUICtrlCreateButton("WIM Info", 32, 80, 70, 27)
GUICtrlSetOnEvent($WIM_INFO, "_WIM_INFO")
GUICtrlSetTip($WIM_INFO, " Displays Info from WIM Image File ")

$VHD_INFO = GUICtrlCreateButton("VHD Info", 32, 120, 70, 27)
GUICtrlSetOnEvent($VHD_INFO, "_VHD_INFO")
GUICtrlSetTip($VHD_INFO, " Displays Info of WIM File connected to VHD File ")

$Update_WIMBOOT = GUICtrlCreateButton("Upd WimBoot", 120, 80, 90, 27)
GUICtrlSetOnEvent($Update_WIMBOOT, "_Update_WIMBOOT")
GUICtrlSetTip($Update_WIMBOOT, " Update WIMBootEntry in VHD File for New Location of WIM File ")

$WIMBOOT = GUICtrlCreateCheckbox("", 120, 128, 17, 17)
GUICtrlCreateLabel( "WimBoot Mode", 144, 130)
GUICtrlSetTip($WIMBOOT, " Apply in WimBoot Mode ")

$LZX = GUICtrlCreateCheckbox("", 266, 128, 17, 17)
GUICtrlCreateLabel( "LZX Compress", 290, 130)
GUICtrlSetTip($LZX, " Capture WIM File with LZX Compression ")

GUICtrlCreateGroup("Target", 18, 252, 364, 89)

GUICtrlCreateLabel( "Boot Drive", 32, 273)
$Target = GUICtrlCreateInput($TargetSel, 110, 270, 95, 20, $ES_READONLY)
$TargetSel = GUICtrlCreateButton("...", 211, 271, 26, 18)
GUICtrlSetTip(-1, " Select your Boot Drive - Active for Boot Files - UEFI needs FAT32 " & @CRLF _
& " Boot entries are made by Apply and Make Boot Button " & @CRLF _
& " in Grub4dos and Boot Manager Menu On Boot Drive for VHD on System Drive ")
GUICtrlSetOnEvent($TargetSel, "_target_drive")
$TargetSize = GUICtrlCreateLabel( "", 253, 264, 100, 15, $ES_READONLY)
$TargetFree = GUICtrlCreateLabel( "", 253, 281, 100, 15, $ES_READONLY)

GUICtrlCreateLabel( "System Drive ", 32, 315)
$WinDrv = GUICtrlCreateInput("", 110, 312, 95, 20, $ES_READONLY)
$WinDrvSel = GUICtrlCreateButton("...", 211, 313, 26, 18)
GUICtrlSetTip(-1, " Select your System Drive - NTFS needed for VHD WIMBOOT " & @CRLF _
& " System Drive is NTFS Partition for VHD + WIM Operating System Files " & @CRLF _
& " Select your Folder max 8 chars for WIM Files e.g. Wimboot on System Drive ")

GUICtrlSetOnEvent($WinDrvSel, "_WinDrv_drive")
$WinDrvSize = GUICtrlCreateLabel( "", 253, 306, 100, 15, $ES_READONLY)
$WinDrvFree = GUICtrlCreateLabel( "", 253, 323, 100, 15, $ES_READONLY)

GUICtrlCreateLabel( "VHD Size", 290, 158)
$ComboSize = GUICtrlCreateCombo("", 285, 174, 70, 24, $CBS_DROPDOWNLIST)
GUICtrlSetTip(-1, " Create New VHD File on NTFS System Drive " & @CRLF _
& " FILEDISK 25 GB - Free Space for New Drivers and Windows Update " & @CRLF _
& " RAMDISK 3.9 GB - Preferred is Half of RAM Size - No Update ")
GUICtrlSetData($ComboSize,"1.0 GB|1.5 GB|2.0 GB|2.5 GB|3.0 GB|3.5 GB|3.9 GB|5.0 GB|6.0 GB|7.0 GB|10.0 GB|15.0 GB|25.0 GB|50.0 GB|100.0 GB", "25.0 GB")

$VHD_TYPE = GUICtrlCreateCombo("", 285, 210, 0, 24, $CBS_DROPDOWNLIST)
GUICtrlSetTip($VHD_TYPE, " Select VHD Type Fixed Or Expandable " & @CRLF _
& " Fixed preferred to Prevent Fragmentation of FILEDISK " & @CRLF _
& " Expandable preferred for Fast Loading into RAMDISK  " & @CRLF _
& " Expandable is Created Faster ")
GUICtrlSetData($VHD_TYPE,"FIXED|Expand", "FIXED")

$VHDX = GUICtrlCreateCombo("", 207, 210, 60, 24, $CBS_DROPDOWNLIST)
GUICtrlSetTip($VHDX, " Select VHD Or VHDX File Type" & @CRLF _
& " VHDX can be used Only as FILEDISK " & @CRLF _
& " VHDX Not Compatible with Windows 7 Operating System " & @CRLF _
& " VHDX Not Compatible with Grub4dos booting from RAMDISK ")
GUICtrlSetData($VHDX,"VHD|VHDX", "VHD")
GUICtrlSetOnEvent($VHDX, "_prevhd")

$DISK_TYPE = GUICtrlCreateCombo("", 114, 210, 75, 24, $CBS_DROPDOWNLIST)
GUICtrlSetData($DISK_TYPE,"FILEDISK|RAMDISK", "FILEDISK")
GUICtrlCreateLabel( "Preset", 75, 212, 38, 15)
GUICtrlSetTip($DISK_TYPE, " Preset for Creating New VHD Files " & @CRLF _
& " Select FILEDISK Or RAMDISK " & @CRLF _
& " FILEDISK booting with Boot Manager Menu and MS Driver " & @CRLF _
& " RAMDISK booting with Grub4dos Menu and SVBus Driver ")
GUICtrlSetOnEvent($DISK_TYPE, "_preset")

$EXIT = GUICtrlCreateButton("EXIT", 320, 360, 60, 30)
GUICtrlSetOnEvent($EXIT, "_Quit")

$Make_Boot = GUICtrlCreateButton("Make Boot", 235, 360, 70, 30)
GUICtrlSetTip($Make_Boot, " Make entries in Grub4dos and Boot Manager Menu " & @CRLF _
& " On Boot Drive for VHD File on NTFS System Drive ")
GUICtrlSetState($Make_Boot, $GUI_DISABLE)
GUICtrlSetOnEvent($Make_Boot, "_Make_Boot")

$ProgressAll = GUICtrlCreateProgress(16, 368, 203, 16, $PBS_SMOOTH)

$hStatus = _GUICtrlStatusBar_Create($hGuiParent, -1, "", $SBARS_TOOLTIPS)
Global $aParts[3] = [310, 350, -1]
_GUICtrlStatusBar_SetParts($hStatus, $aParts)

_GUICtrlStatusBar_SetText($hStatus," Select Wimboot Folder on System Drive", 0)

DisableMenus(1)

GUICtrlSetState($WIMBOOT, $GUI_CHECKED + $GUI_DISABLE)
GUICtrlSetState($LZX, $GUI_UNCHECKED + $GUI_DISABLE)
GUICtrlSetState($Update_WIMBOOT, $GUI_DISABLE)
GUICtrlSetState($WIM_INFO, $GUI_DISABLE)
GUICtrlSetState($VHD_INFO, $GUI_DISABLE)
GUICtrlSetState($ComboSize, $GUI_DISABLE)
GUICtrlSetState($VHD_TYPE, $GUI_DISABLE)
GUICtrlSetState($VHDX, $GUI_DISABLE)
GUICtrlSetState($DISK_TYPE, $GUI_DISABLE)
GUICtrlSetState($WIM_FileSelect, $GUI_DISABLE)
GUICtrlSetState($VHD_FileSelect, $GUI_DISABLE)
GUICtrlSetState($TargetSel, $GUI_DISABLE)
GUICtrlSetState($WinDrvSel, $GUI_ENABLE + $GUI_FOCUS)

_Mount_EFI()

GUISetState(@SW_SHOW)

;===================================================================================================
While 1
	CheckGo()
	Sleep(1000)
WEnd   ;==> Loop
;===================================================================================================
Func CheckGo()
 	If $wimfile = "" And $vhdfile <> "" And $WIM_Path <> "" And FileExists($vhdfile) Then
 		GUICtrlSetState($CAPTURE, $GUI_ENABLE)
	Else
 		GUICtrlSetState($CAPTURE, $GUI_DISABLE)
	EndIf
 	If $wimfile <> "" And $WIM_Path <> "" Then
 		GUICtrlSetState($APPLY, $GUI_ENABLE)
		GUICtrlSetState($WIMBOOT, $GUI_ENABLE)
	Else
  		GUICtrlSetState($APPLY, $GUI_DISABLE)
		GUICtrlSetState($WIMBOOT, $GUI_CHECKED + $GUI_DISABLE)
	EndIf
 	If $TargetDrive <> "" And $vhdfile <> "" And $WIM_Path <> "" And FileExists($vhdfile) Then
		GUICtrlSetState($Make_Boot, $GUI_ENABLE)
	Else
		GUICtrlSetState($Make_Boot, $GUI_DISABLE)
	EndIf
EndFunc ;==> _CheckGo
;===================================================================================================
Func _preset()
	If GUICtrlRead($DISK_TYPE) = "FILEDISK" Then
		GUICtrlSetData($ComboSize,"25.0 GB")
		GUICtrlSetData($VHD_TYPE,"FIXED")
		GUICtrlSetData($VHDX,"VHD")
	Else
		GUICtrlSetData($ComboSize,"3.9 GB")
		GUICtrlSetData($VHD_TYPE,"Expand")
		GUICtrlSetData($VHDX,"VHD")
	EndIf
EndFunc   ;==> _preset
;===================================================================================================
Func _prevhd()
	If GUICtrlRead($VHDX) = "VHDX" Then
		GUICtrlSetData($DISK_TYPE,"FILEDISK")
		GUICtrlSetData($ComboSize,"25.0 GB")
		GUICtrlSetData($VHD_TYPE,"FIXED")
	Else
	EndIf
EndFunc   ;==> _preset
;===================================================================================================
Func _Mount_EFI()
	Local $TempDrives[4] = ["Z:", "Y:", "S:", "T:"], $AllDrives, $efi_drive = "Z:", $efi_temp_drive, $efi_valid = 0, $index_alldrives, $firm_val=0

	SystemFileRedirect("On")
	$Firmware = _WinAPI_GetFirmwareEnvironmentVariable()
	If $Firmware = "UEFI" Then
		$AllDrives = DriveGetDrive( "all" )

		;  _ArrayDisplay($AllDrives)

		FOR $efi_temp_drive IN $TempDrives
			If Not FileExists($efi_temp_drive & "\nul") Then
				$efi_valid = 1
				For $index_alldrives = 1 to $AllDrives[0]
					If $efi_temp_drive = $AllDrives[$index_alldrives] Then
						$efi_valid = 0
					;	MsgBox(48,"Invalid Drive " & $i, "Invalid Drive " & $AllDrives[$i])
					EndIf
				Next
				If $efi_valid Then
					$efi_drive = $efi_temp_drive
					ExitLoop
				EndIf
			Else
				$efi_valid = 0
			EndIf
		NEXT

		If $efi_valid Then
			$firm_val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\mountvol.exe " & $efi_drive & " /s", @ScriptDir, @SW_HIDE)
	;~ 			If $firm_val <> 0 Then
	;~ 				MsgBox(48, " Error Mounting EFI as Drive " & $efi_drive, " MountVol Error = " & $firm_val & @CRLF & @CRLF _
	;~ 				& " EFI Drive was Mounted already ")
	;~ 			EndIf
		Else
			MsgBox(48, " Unable to Mount EFI Drive ", " No Free Drive Letter Z Y S T " & @CRLF & @CRLF _
			& " Unable to Mount EFI Drive ", 3)
		EndIf
	EndIf
	SystemFileRedirect("Off")
EndFunc ;==> _Mount_EFI
;===================================================================================================
Func _Update_WIMBOOT()
	Local $val=0, $linesplit[20], $file, $line, $AutoPlay_Data="", $index_found = 0, $count = 0, $wim_found = ""

	DisableMenus(1)

	If $wimfile <> "" And $vhdfile <> "" And $WIM_Path <> "" And FileExists($vhdfile) Then

		SystemFileRedirect("On")

		If Not FileExists(@WindowsDir & "\system32\diskpart.exe") Then
			SystemFileRedirect("Off")
			MsgBox(48, "ERROR - DiskPart Not Found ", " system32\diskpart.exe needed to Create VHD Drive " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 10 PE ")
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			Return
		EndIf

		If FileExists(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt")

		RunWait(@ComSpec & " /c reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay" & " > makebt\vhd_temp\Reg_DisableAutoPlay.txt", @ScriptDir, @SW_HIDE)

		$file = FileOpen(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt", 0)
		While 1
			$line = FileReadLine($file)
			If @error = -1 Then ExitLoop
			If $line <> "" Then
				$line = StringStripWS($line, 7)
				$linesplit = StringSplit($line, " ")
				; _ArrayDisplay($linesplit)
				If $linesplit[1] = "DisableAutoplay" Then
					$AutoPlay_Data = $linesplit[3]
				EndIf
			EndIf
		Wend
		FileClose($file)

		; MsgBox(48, "Info AutoPlay ", "  " & @CRLF & @CRLF & " AutoPlay_Data = " & $AutoPlay_Data, 0)

		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 1 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Disabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 1 ", 0)
		EndIf

		; Mount Existing vhdfile as $tmpdrive
		_Mount_VHD()

		; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
		EndIf

		; In case _Mount_VHD failure return
		If $tmpdrive = "" Then
			SystemFileRedirect("Off")
			MsgBox(48, " STOP - VHD Drive Not Found", " Attach / Detach VHD - DiskPart Error " & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
			GUICtrlSetData($ProgressAll, 0)
			_GUICtrlStatusBar_SetText($hStatus," Select Exit Or Select VHD ", 0)
			DisableMenus(0)
			Return
		EndIf

		If Not FileExists($tmpdrive & "\Windows\system32\winload.exe") Then
			_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
			RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
			SystemFileRedirect("Off")
			MsgBox(48, " STOP - VHD Invalid", " VHD Invalid - winload.exe Missing " & @CRLF & @CRLF & " Invalid VHD " & $vhdfile, 0)
			GUICtrlSetData($ProgressAll, 0)
			_GUICtrlStatusBar_SetText($hStatus," Select Exit Or Select VHD ", 0)
			DisableMenus(0)
			Return
		EndIf

		If FileExists(@ScriptDir & "\makebt\wim_info\Get-WIMBootEntry_dism.txt") Then
			FileCopy(@ScriptDir & "\makebt\wim_info\Get-WIMBootEntry_dism.txt", @ScriptDir & "\makebt\wim_info\Get-WIMBootEntry_dism_bak.txt", 1)
			FileDelete(@ScriptDir & "\makebt\wim_info\Get-WIMBootEntry_dism.txt")
		EndIf

		If FileExists(@WindowsDir & "\System32\Dism.exe") Then
			_GUICtrlStatusBar_SetText($hStatus," Get-WIMBootEntry by Dism ", 0)
			$val = RunWait(@ComSpec & " /c Dism.exe /Get-WIMBootEntry /Path:" & $tmpdrive & "\ > makebt\wim_info\Get-WIMBootEntry_dism.txt", @ScriptDir, @SW_HIDE)
			; MsgBox(0, " Dism - Get-WIMBootEntry", " Dism - Get-WIMBootEntry - Return Code = " & $val, 0)
		EndIf
		$file = FileOpen(@ScriptDir & "\makebt\wim_info\Get-WIMBootEntry_dism.txt", 0)
		If $file <> -1 Then
			$count = 0
			$index_found = 0
			While 1
				$line = FileReadLine($file)
				If @error = -1 Then ExitLoop
				If $line <> "" Then
					$count = $count + 1
					$linesplit = StringSplit($line, ":")
					$linesplit[1] = StringStripWS($linesplit[1], 3)
					If $linesplit[1] = "Data Source ID" And $linesplit[0] = 2 Then
						$linesplit[2] = StringStripWS($linesplit[2], 3)
						$index_found = $linesplit[2]
						; MsgBox(0, "Data Source ID - Found", " Data Source ID = " & $linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Image File" Then
						If $linesplit[0] = 3 Then
							$linesplit[2] = StringStripWS($linesplit[2], 3)
							$linesplit[3] = StringStripWS($linesplit[3], 3)
							$wim_found = $linesplit[2] & ":" & $linesplit[3]
							; MsgBox(0, "Image File Found - OK", " Image File = " & $wim_found, 0)
						EndIf
						If $linesplit[0] = 2 Then
							$linesplit[2] = StringStripWS($linesplit[2], 3)
							$wim_found = $linesplit[2]
							; MsgBox(0, "Image File Found - OK", " Image File = " & $wim_found, 0)
						EndIf
					EndIf
				EndIf
			Wend
			FileClose($file)
		EndIf
		; MsgBox(0, "WIM Image File", " ID = " & $index_found & "  WIM Image File = " & $wim_found, 0)

		If FileExists(@WindowsDir & "\System32\Dism.exe") And $wim_found <> "" Then
			_GUICtrlStatusBar_SetText($hStatus," Update-WIMBootEntry by Dism ", 0)
			$val = RunWait(@ComSpec & " /c Dism.exe /Update-WIMBootEntry /Path:" & $tmpdrive & "\  /DataSourceID:" & $index_found & " /ImageFile:" & $wimfile, @ScriptDir, @SW_HIDE)
			sleep(1000)
			RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
			If $val = 0 Then
				MsgBox(0, "Update-WIMBootEntry - OK ", " Data Source ID = " & $index_found & @CRLF & @CRLF & " WIM File = " & $wimfile & @CRLF & @CRLF _
				& " VHD File = " & $vhdfile & @CRLF & @CRLF & " Old WIMBootEntry = " & $wim_found & @CRLF & @CRLF & " WimBoot Update OK - Return Code = " & $val , 0)
			Else
				MsgBox(48, "Update-WIMBootEntry - Failed ", " Data Source ID = " & $index_found & @CRLF & @CRLF & " WIM File = " & $wimfile & @CRLF & @CRLF _
				& " VHD File = " & $vhdfile & @CRLF & @CRLF & " Old WIMBootEntry = " & $wim_found & @CRLF & @CRLF & " WimBoot Update Failed - Return Code = " & $val , 0)
			EndIf
		Else
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
			MsgBox(48, "Update-WIMBootEntry - Failed ", " Data Source ID = " & $index_found & @CRLF & @CRLF & " WIM File = " & $wimfile & @CRLF & @CRLF _
			& " VHD File = " & $vhdfile & @CRLF & @CRLF & " No Update - WIMBootEntry Not Found", 0)
		EndIf

		SystemFileRedirect("Off")

		_GUICtrlStatusBar_SetText($hStatus," Make Boot can make Entries in Boot Menu ", 0)
	Else
		MsgBox(0, "Update-WIMBootEntry - Not Possible ", " WIM Image File = " & $wimfile & @CRLF & @CRLF _
			& " VHD File = " & $vhdfile, 5)
	EndIf
	DisableMenus(0)
EndFunc ;==> _Update_WIMBOOT
;===================================================================================================
Func _WIM_INFO()
	If $wimfile <> "" And $WIM_Path <> "" Then
		DisableMenus(1)
		ShellExecute("notepad.exe", @ScriptDir & "\makebt\wim_info\wim_info.txt", @ScriptDir)
		MsgBox(0,"Timeout", "", 0.3)
		DisableMenus(0)
	EndIf
EndFunc ;==> _WIM_INFO
;===================================================================================================
Func _VHD_INFO()
	Local $val=0, $linesplit[20], $file, $line, $AutoPlay_Data=""

	If $vhdfile <> "" And FileExists($vhdfile) And $WIM_Path <> "" Then

		DisableMenus(1)

		SystemFileRedirect("On")

		If Not FileExists(@WindowsDir & "\system32\diskpart.exe") Then
			SystemFileRedirect("Off")
			MsgBox(48, "ERROR - DiskPart Not Found ", " system32\diskpart.exe needed to Mount VHD Drive " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 10 PE ")
			DisableMenus(0)
			Return
		EndIf

		If FileExists(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt")

		RunWait(@ComSpec & " /c reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay" & " > makebt\vhd_temp\Reg_DisableAutoPlay.txt", @ScriptDir, @SW_HIDE)

		$file = FileOpen(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt", 0)
		While 1
			$line = FileReadLine($file)
			If @error = -1 Then ExitLoop
			If $line <> "" Then
				$line = StringStripWS($line, 7)
				$linesplit = StringSplit($line, " ")
				; _ArrayDisplay($linesplit)
				If $linesplit[1] = "DisableAutoplay" Then
					$AutoPlay_Data = $linesplit[3]
				EndIf
			EndIf
		Wend
		FileClose($file)

		; MsgBox(48, "Info AutoPlay ", "  " & @CRLF & @CRLF & " AutoPlay_Data = " & $AutoPlay_Data, 0)

		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 1 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Disabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 1 ", 0)
		EndIf

		_Mount_VHD()

		; In case _Mount_VHD failure return
		If $tmpdrive = "" Then
			; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
			If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
				RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
				; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
			EndIf
			SystemFileRedirect("Off")
			MsgBox(48, " STOP - VHD Drive Not Found", " Attach / Detach VHD - DiskPart Error " & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
			DisableMenus(0)
			If $wimfile <> "" Then
				_GUICtrlStatusBar_SetText($hStatus," Select APPLY of WIM File to VHD Or Upd WimBoot", 0)
			Else
				_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY to VHD Or Select CAPTURE ", 0)
			EndIf
			Return
		EndIf

		If FileExists(@ScriptDir & "\makebt\wim_info\vhd_info.txt") Then
			FileCopy(@ScriptDir & "\makebt\wim_info\vhd_info.txt", @ScriptDir & "\makebt\wim_info\vhd_info_bak.txt", 1)
			FileDelete(@ScriptDir & "\makebt\wim_info\vhd_info.txt")
		EndIf

		FileWriteLine(@ScriptDir & "\makebt\wim_info\vhd_info.txt", "fsutil wim enumwims " & $tmpdrive & "  gives:")
		FileWriteLine(@ScriptDir & "\makebt\wim_info\vhd_info.txt", "")
		FileWriteLine(@ScriptDir & "\makebt\wim_info\vhd_info.txt", "VHD File  " & $vhdfile & "  Mounted as drive " & $tmpdrive & "  is connected to WIM File:")
		FileWriteLine(@ScriptDir & "\makebt\wim_info\vhd_info.txt", "")
		RunWait(@ComSpec & " /c fsutil wim enumwims " & $tmpdrive & " >> makebt\wim_info\vhd_info.txt", @ScriptDir, @SW_HIDE)

		sleep(1000)

		_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
		If $val <> 0 Then
			MsgBox(48, " Error DiskPart", " Detach Dest VHD - DiskPart Error = " & $val, 0)
		EndIf

		SystemFileRedirect("Off")

		sleep(1000)

		If $wimfile <> "" Then
			_GUICtrlStatusBar_SetText($hStatus," Select APPLY of WIM File to VHD Or Upd WimBoot", 0)
		Else
			_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY to VHD Or Select CAPTURE ", 0)
		EndIf

		If FileExists(@ScriptDir & "\makebt\wim_info\vhd_info.txt") Then
			ShellExecute("notepad.exe", @ScriptDir & "\makebt\wim_info\vhd_info.txt", @ScriptDir)
		Else
			MsgBox(48, " Error VHD Info", " File makebt\wim_info\vhd_info.txt Not Found ", 0)
		EndIf

		DisableMenus(0)
	EndIf
EndFunc ;==> _VHD_INFO
;===================================================================================================
Func _Quit()
	Local $ikey
	DisableMenus(1)
	If @GUI_WinHandle = $hGuiParent Then
		$ikey = MsgBox(48+4+256, " STOP Program ", " STOP Program ? ")
		If $ikey = 6 Then
			Exit
		Else
		DisableMenus(0)
			Return
		EndIf
	Else
		GUIDelete(@GUI_WinHandle)
	EndIf
	DisableMenus(0)
EndFunc   ;==> _Quit
;===================================================================================================
Func SystemFileRedirect($Wow64Number)
	If @OSArch = "X64" Then
		Local $WOW64_CHECK = DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "ptr*", 0)
		If Not @error Then
			If $Wow64Number = "On" And $WOW64_CHECK[1] <> 1 Then
				DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "int", 1)
			ElseIf $Wow64Number = "Off" And $WOW64_CHECK[1] <> 0 Then
				DllCall("kernel32.dll", "int", "Wow64EnableWow64FsRedirection", "int", 1)
			EndIf
		EndIf
	EndIf
EndFunc   ;==> SystemFileRedirect
;===================================================================================================
Func _GetDrivePartitionStyle($sDrive = "C")
    Local $tDriveLayout = DllStructCreate('dword PartitionStyle;' & _
            'dword PartitionCount;' & _
            'byte union[40];' & _
            'byte PartitionEntry[8192]')
    Local $hDrive = DllCall("kernel32.dll", "handle", "CreateFileW", _
            "wstr", "\\.\" & $sDrive & ":", _
            "dword", 0, _
            "dword", 0, _
            "ptr", 0, _
            "dword", 3, _ ; OPEN_EXISTING
            "dword", 0, _
            "ptr", 0)
    If @error Or $hDrive[0] = Ptr(-1) Then Return SetError(@error, @extended, 0) ; INVALID_HANDLE_VALUE
    DllCall("kernel32.dll", "int", "DeviceIoControl", _
            "hwnd", $hDrive[0], _
            "dword", 0x00070050, _
            "ptr", 0, _
            "dword", 0, _
            "ptr", DllStructGetPtr($tDriveLayout), _
            "dword", DllStructGetSize($tDriveLayout), _
            "dword*", 0, _
            "ptr", 0)
    DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hDrive[0])
    Switch DllStructGetData($tDriveLayout, "PartitionStyle")
        Case 0
            Return "MBR"
        Case 1
            Return "GPT"
        Case 2
            Return "RAW"
        Case Else
            Return "UNKNOWN"
    EndSwitch
EndFunc   ;==>_GetDrivePartitionStyle
;===================================================================================================
Func _WinAPI_GetFirmwareEnvironmentVariable()
    DllCall("kernel32.dll", "dword", _
            "GetFirmwareEnvironmentVariableW", "wstr", "", _
            "wstr", "{00000000-0000-0000-0000-000000000000}", "wstr", "", "dword", 4096)
    Local $iError = DllCall("kernel32.dll", "dword", "GetLastError")
    Switch $iError[0]
        Case 1
            Return "LEGACY"
        Case 998
            Return "UEFI"
        Case Else
            Return "UEFI"
    EndSwitch
EndFunc   ;==>_WinAPI_GetFirmwareEnvironmentVariable
;===================================================================================================
Func _wim_fsel()
	Local $pos, $posfol, $WinName, $Architecture = "x64", $Language = "US", $WinVersion = "10", $valid = 0, $WIMBoot_compatible = "no"
	Local $linesplit[20], $file, $line, $index_found = 0, $count = 0, $WinSplit[20], $count_lang, $LangSplit[20]

	DisableMenus(1)
	GUICtrlSetData($WIM_Size_Label, "")
	GUICtrlSetData($WIM_File, "")
	$wimfile = ""
	$wimfolder = ""
	If $vhdfile = "" Then
		_GUICtrlStatusBar_SetText($hStatus," Select WIM Or VHD File on System Drive ", 0)
	Else
		_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY to VHD Or Select CAPTURE ", 0)
	EndIf

	; _GUICtrlStatusBar_SetText($hStatus," Select WIM File on System Drive for APPLY to VHD ", 0)

	; $wimfile = FileOpenDialog("Select WIM File for APPLY to VHD ", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "WIM Image Files ( *.wim; )")
	$wimfile = FileOpenDialog("Select WIM File on System Drive for APPLY to VHD ", $WIM_Path & "\", "WIM Image Files ( *.wim; )")
	If @error Then
		$wimfile = ""
		$wimfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If StringLeft($wimfile, 3) <> StringLeft($WIM_Path, 3) Then
		MsgBox(48,"ERROR - WIM File Not Valid", "WIM File Selection Invalid" & @CRLF & @CRLF & "Selected Image = " & $wimfile & @CRLF & @CRLF _
		& "Select WIM File on System Drive " & $WinDrvDrive)
		$wimfile = ""
		$wimfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If StringRight($wimfile, 4) <> ".wim" Then
		MsgBox(48,"ERROR - WIM File Not Valid", "WIM File Selection Invalid" & @CRLF & @CRLF & "Selected Image = " & $wimfile & @CRLF & @CRLF _
		& "Select WIM File on System Drive " & $WinDrvDrive)
		$wimfile = ""
		$wimfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If Not FileExists($wimfile) Then
		MsgBox(48,"ERROR - WIM File Not Valid", "WIM File does Not Exist" & @CRLF & @CRLF & "Selected Image = " & $wimfile & @CRLF & @CRLF _
		& "Select WIM File on System Drive " & $WinDrvDrive)
		$wimfile = ""
		$wimfolder = ""
		DisableMenus(0)
		Return
	EndIf

	$pos = StringLen($wimfile)
	If $pos  > 41 Then
		MsgBox(48,"ERROR - WIM File Not Valid", "WIM FileName more than 25 Chars " & @CRLF & @CRLF & "Selected WIM File = " & $wimfile & @CRLF & @CRLF _
		& "Select WIM File on System Drive " & $WinDrvDrive)
		$wimfile = ""
		$wimfolder = ""
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($wimfile, " ", 0, -1)
	If $pos Then
		MsgBox(48,"ERROR - WIM Image Path Invalid", "WIM Image Path Invalid - Space Found" & @CRLF & @CRLF & "Selected Image = " & $wimfile & @CRLF & @CRLF _
		& "Solution - Use simple WIM Path without Spaces ")
		$wimfile = ""
		$wimfolder = ""
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($wimfile, "\", 0, -1)
	If $pos <> 3 Then
		$posfol = StringInStr($wimfile, "\", 0, -2)
		If $posfol <> 3 Or $pos > 12 Then
			MsgBox(48,"ERROR - WIM File Selection Not Valid", "WIM Not in root Or rootfolder max 8 chars" & @CRLF & @CRLF & "Selected WIM File = " & $wimfile & @CRLF & @CRLF _
			& "Select WIM in folder max 8 chars or in root of System Drive " & $WinDrvDrive)
			$wimfile = ""
			$wimfolder = ""
			DisableMenus(0)
			Return
		Else
			$wimfolder = StringMid($wimfile, 4, $pos - $posfol - 1)
;~ 			MsgBox(48,"WIM File in Folder Selected", "WIM File in Folder Selected" & @CRLF & @CRLF & "Selected WIM File = " & $wimfile & @CRLF & @CRLF _
;~ 			& "WIM File in Folder " &  $wimfolder & " on System Drive " & $WinDrvDrive)
			If $vhdfile <> "" And $vhdfolder <> "" And $wimfolder <> $vhdfolder Then
				MsgBox(48,"WARNING - WIM and VHD File Not in same Folder", "Selected WIM File = " & $wimfile & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
				& "You may want VHD + WIM in same folder on System Drive " & $WinDrvDrive)
			EndIf
		EndIf
	EndIf

	If $wimfile <> "" Then
		If FileExists(@ScriptDir & "\makebt\wim_info\wim_info.txt") Then
			FileCopy(@ScriptDir & "\makebt\wim_info\wim_info.txt", @ScriptDir & "\makebt\wim_info\wim_info_bak.txt", 1)
			FileDelete(@ScriptDir & "\makebt\wim_info\wim_info.txt")
		EndIf
;~ 		If FileExists(@ScriptDir & "\makebt\wim_info\wiminfo_dism.txt") Then
;~ 			FileCopy(@ScriptDir & "\makebt\wim_info\wiminfo_dism.txt", @ScriptDir & "\makebt\wim_info\wiminfo_dism_bak.txt", 1)
;~ 			FileDelete(@ScriptDir & "\makebt\wim_info\wiminfo_dism.txt")
;~ 		EndIf

;~ 		If GUICtrlRead($wimlib_dism) = "Dism" Then
;~ 			If FileExists(@WindowsDir & "\System32\Dism.exe") Then
;~ 				_GUICtrlStatusBar_SetText($hStatus," WIM Info by Dism ", 0)
;~ 				RunWait(@ComSpec & " /c Dism.exe /Get-ImageInfo /ImageFile:" & '"' & $wimfile & '"' & " /Index:1 > makebt\wim_info\wiminfo_dism.txt", @ScriptDir, @SW_HIDE)
;~ 				; Dism /Get-ImageInfo /ImageFile:<path_to_image.wim> [{/Index:<Image_index> | /Name:<Image_name>}]
;~ 			EndIf
;~ 			$file = FileOpen(@ScriptDir & "\makebt\wim_info\wiminfo_dism.txt", 0)
;~ 			If $file <> -1 Then
;~ 				$count = 0
;~ 				$index_found = 0
;~ 				While 1
;~ 					$line = FileReadLine($file)
;~ 					If @error = -1 Then ExitLoop
;~ 					If $line <> "" Then
;~ 						$count = $count + 1
;~ 						$linesplit = StringSplit($line, ":")
;~ 						$linesplit[1] = StringStripWS($linesplit[1], 3)
;~ 						If $linesplit[1] = "Index" And $linesplit[0] = 2 Then
;~ 							$linesplit[2] = StringStripWS($linesplit[2], 3)
;~ 							If $linesplit[2] = "1" Then
;~ 								$index_found = 1
;~ 								; MsgBox(0, "Index 1 Found - OK", " Index = " & $linesplit[2], 3)
;~ 							Else
;~ 								$index_found = 0
;~ 							EndIf
;~ 						EndIf
;~ 						If $index_found = 1 Then
;~ 							If $linesplit[1] = "Display Name" And $linesplit[0] = 2 Then
;~ 								$WinName = StringStripWS($linesplit[2], 3)
;~ 							EndIf
;~ 							If $linesplit[1] = "Architecture" And $linesplit[0] = 2 Then
;~ 								$Architecture = "x" & StringRight(StringStripWS($linesplit[2], 3), 2)
;~ 							EndIf
;~ 							If $linesplit[1] = "Languages" Then
;~ 								$count_lang = $count
;~ 							EndIf
;~ 							If $count = $count_lang + 1 Then
;~ 								$LangSplit = StringSplit($line, " ")
;~ 								$Language = StringRight(StringStripWS($LangSplit[1], 3), 2)
;~ 							EndIf
;~ 						EndIf
;~ 					EndIf
;~ 				Wend
;~ 				FileClose($file)
;~ 			EndIf
;~ 			$WinSplit = StringSplit($WinName, " ")
;~ 			If $WinSplit[0] = 3 Then $WinVersion = $WinSplit[2]
;~ 			$vhd_name = "W" & $WinVersion & $Architecture & "_" & $Language & "_"
;~ 			; MsgBox(0, "VHD Name", " VHD Name = " & $vhd_name, 0)
;~ 		Else
			; _GUICtrlStatusBar_SetText($hStatus," WIM Info by wimlib ", 0)
			If @OSArch = "X86" Then
				RunWait(@ComSpec & " /c wimlib_x86\wiminfo.cmd " & '"' & $wimfile & '"' & " > makebt\wim_info\wim_info.txt", @ScriptDir, @SW_HIDE)
			Else
				RunWait(@ComSpec & " /c wimlib_x64\wiminfo.cmd " & '"' & $wimfile & '"' & " > makebt\wim_info\wim_info.txt", @ScriptDir, @SW_HIDE)
			EndIf

			$file = FileOpen(@ScriptDir & "\makebt\wim_info\wim_info.txt", 0)
			If $file <> -1 Then
				$count = 0
				$index_found = 0
				While 1
					$line = FileReadLine($file)
					If @error = -1 Then ExitLoop
					If $line <> "" Then
						$count = $count + 1
						$linesplit = StringSplit($line, ":")
						$linesplit[1] = StringStripWS($linesplit[1], 3)
						If $linesplit[1] = "Index" And $linesplit[0] = 2 Then
							$linesplit[2] = StringStripWS($linesplit[2], 3)
							If $linesplit[2] = "1" Then
								$index_found = 1
								; MsgBox(0, "Index 1 Found - OK", " Index = " & $linesplit[2], 3)
							Else
								$index_found = 0
								$valid = 0
							EndIf
						EndIf
						If $index_found = 1 Then
							If $linesplit[1] = "Display Name" And $linesplit[0] = 2 Then
								$WinName = StringStripWS($linesplit[2], 3)
							EndIf
							If $linesplit[1] = "Architecture" And $linesplit[0] = 2 Then
								$Architecture = "x" & StringRight(StringStripWS($linesplit[2], 3), 2)
							EndIf
							If $linesplit[1] = "Languages" Then
								$Language = StringRight(StringStripWS($linesplit[2], 3), 2)
							EndIf
;~ 							If $linesplit[1] = "WIMBoot compatible" Then
;~ 								$WIMBoot_compatible = StringStripWS($linesplit[2], 3)
;~ 								If $WIMBoot_compatible = "yes" Then $valid = 1
;~ 							EndIf
							$valid = 1
						EndIf
					EndIf
				Wend
				FileClose($file)
			EndIf
			$WinSplit = StringSplit($WinName, " ")
			If $WinSplit[0] = 3 Then $WinVersion = $WinSplit[2]
			If $WinSplit[0] = 2 Then $WinVersion = $WinSplit[2]
			; remove 8.1 dot
			$WinSplit = StringSplit($WinVersion, ".")
			If $WinSplit[0] = 2 Then $WinVersion = $WinSplit[1] & $WinSplit[2]
			$vhd_name = "W" & $WinVersion & $Architecture & "_" & $Language & "_"
			; MsgBox(0, "VHD Name", " VHD Name = " & $vhd_name, 0)
		; EndIf
	EndIf
	If $valid = 0 Then
		MsgBox(48,"ERROR - WIM File Not Valid", "WIM File Not WIMBOOT Compatible " & @CRLF & @CRLF & "Selected Image = " & $wimfile & @CRLF & @CRLF _
		& "First Capture WIM File from VHD ")
		$wimfile = ""
		$wimfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If $vhdfile <> "" Then
		_GUICtrlStatusBar_SetText($hStatus," Select APPLY of WIM File to VHD Or Upd WimBoot", 0)
	Else
		_GUICtrlStatusBar_SetText($hStatus," Select APPLY of WIM File to VHD ", 0)
	EndIf

	$WIM_Size = FileGetSize($wimfile)
	$WIM_Size = Round($WIM_Size / 1024 / 1024)
	GUICtrlSetData($WIM_Size_Label, Round($WIM_Size / 1024, 1) & " GB")

	GUICtrlSetData($WIM_File, $wimfile)
	DisableMenus(0)
EndFunc   ;==> _wim_fsel
;===================================================================================================
Func _vhd_fsel()
	Local $len, $pos, $posdot, $posfol, $vhd_fext = "", $vhd_fname = "", $vhdtemp_name = "", $vhd_path = ""

	DisableMenus(1)
	GUICtrlSetData($VHD_Size_Label, "")
	GUICtrlSetData($VHD_File, "")
	$vhdfile = ""
	$vhdfolder = ""
	$vhdfile_name = ""
	$vhdfile_name_only = ""
	If $wimfile = "" Then
		_GUICtrlStatusBar_SetText($hStatus," Select WIM Or VHD File on System Drive ", 0)
	Else
		_GUICtrlStatusBar_SetText($hStatus," Select VHD Or Select APPLY of WIM File to VHD ", 0)
	EndIf

	; _GUICtrlStatusBar_SetText($hStatus," Select VHD File on System Drive ", 0)

	; $vhdfile = FileOpenDialog("Select VHD File for CAPTURE ", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "VHD Files ( *.vhd; )")

	; WIN_7 Not Compatible with .vhdx
	If @OSVersion = "WIN_7" Then
		$vhdfile = FileOpenDialog("Select VHD File for APPLY Or CAPTURE of WIM File ", StringLeft($WIM_Path, 3), "VHD Files ( *.vhd; )")
	Else
		$vhdfile = FileOpenDialog("Select VHD File for APPLY Or CAPTURE of WIM File ", StringLeft($WIM_Path, 3), "VHD Files ( *.vhdx; *.vhd; )")
	EndIf
	If @error Then
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf

	$pos = StringLen($vhdfile)
	If $pos  > 32 Then
		MsgBox(48,"ERROR - VHD File Not Valid", "VHD FileName more than 25 Chars " & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
		& "Select VHD File on System Drive " & $WinDrvDrive)
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If StringLeft($vhdfile, 3) <> StringLeft($WIM_Path, 3) Then
		MsgBox(48,"ERROR - VHD File Not Valid", "VHD File Selection Invalid" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
		& "Select VHD File on System Drive " & $WinDrvDrive)
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If @OSVersion = "WIN_7" And StringRight($vhdfile, 4) <> ".vhd" Then
		MsgBox(48,"ERROR - Selected File Not Valid", " In Windows 7 only VHD File Type allowed" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
		& "Select VHD File on System Drive " & $WinDrvDrive)
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If StringRight($vhdfile, 4) = ".vhd" Or StringRight($vhdfile, 5) = ".vhdx" Then
		; OK
	Else
		MsgBox(48,"ERROR - VHD File Not Valid", "VHD File Selection Invalid" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
		& "Select VHD File on System Drive " & $WinDrvDrive)
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($vhdfile, " ", 0, -1)
	If $pos Then
		MsgBox(48,"ERROR - VHD File Not Valid", "Space Found in VHD FileName" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
		& "Select VHD File in on System Drive " & $WinDrvDrive)
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf

	$len = StringLen($vhdfile)
	$pos = StringInStr($vhdfile, "\", 0, -1)
	$vhdtemp_name = StringRight($vhdfile, $len-$pos)
	$vhd_path = StringLeft($vhdfile, $pos-1)
	; MsgBox(0, "VHD Path and Name", "VHD Path = " & $vhd_path & @CRLF & @CRLF & " VHD Name = " & $vhdtemp_name)
	$len = StringLen($vhdtemp_name)
	$pos = StringInStr($vhdtemp_name, ".", 0, 1)
	; $vhd_fext = StringRight($vhdtemp_name, $len-$pos)
	$vhd_fname = StringLeft($vhdtemp_name, $pos-1)
	; If StringRegExp($vhd_fname, "[^A-Z0-9a-z-_]") Or StringRegExp($vhd_fext, "[^A-Za-z]") Then
	If StringRegExp($vhd_fname, "[^A-Z0-9a-z-_]") Then
		MsgBox(48,"ERROR - VHD File Not Valid", "Only Chars 0-9 A-Z a-z - _ allowed in FileName" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
		& "Select VHD File on System Drive " & $WinDrvDrive)
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf
	If StringLen($vhd_path) > 3 And StringRegExp(StringMid($vhd_path, 4), "[^A-Z0-9a-z-_]") Or StringLen($vhd_path) > 11 Then
		MsgBox(48,"ERROR - Folder Name Not Valid", "Only Root Folder Max 8 chars allowed" & @CRLF & @CRLF _
		& "Only Chars 0-9 A-Z a-z - _ allowed in Folder Name" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
		& "Solution - Select VHD in Root Or simple Root Folder Max 8 chars ")
		$vhdfile = ""
		$vhdfolder = ""
		DisableMenus(0)
		Return
	EndIf

	If Not FileExists($vhdfile) Then
		If GUICtrlRead($VHDX) = "VHD" Then
			$vhdfile = $vhd_path & "\" & $vhd_fname & ".vhd"
		Else
			$vhdfile = $vhd_path & "\" & $vhd_fname & ".vhdx"
		EndIf
	EndIf

;~ 		$pos = StringInStr($vhdfile, ".", 0, -2)
;~ 		If $pos <> 0 Then
;~ 			MsgBox(48,"ERROR - VHD File Not Valid", "Dot Found in VHD FileName " & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
;~ 			& "Select VHD File on System Drive " & $WinDrvDrive)
;~ 			$vhdfile = ""
;~ 			$vhdfolder = ""
;~ 			DisableMenus(0)
;~ 			Return
;~ 		EndIf

	$pos = StringInStr($vhdfile, "\", 0, -1)
	If $pos <> 3 Then
		$posfol = StringInStr($vhdfile, "\", 0, -2)
		If $posfol <> 3 Or $pos > 12 Then
			MsgBox(48,"ERROR - VHD File Selection Not Valid", "VHD Not in root Or rootfolder max 8 chars" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
			& "Select VHD in folder max 8 chars Or in root of System Drive " & $WinDrvDrive)
			$vhdfile = ""
			$vhdfolder = ""
			DisableMenus(0)
			Return
		Else
			$vhdfolder = StringMid($vhdfile, 4, $pos - $posfol - 1)
			$vhdfile_name = StringMid($vhdfile, $posfol + 1)
			$vhdfile_name_only = StringMid($vhdfile, $pos + 1)
			If Not FileExists($WinDrvDrive & "\" & $vhdfolder) Then DirCreate($WinDrvDrive & "\" & $vhdfolder)
;~ 			MsgBox(48,"VHD File in Folder Selected", "VHD File in Folder Selected" & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
;~ 			& "Selected VHD FileName = " & $vhdfile_name & @CRLF & @CRLF _
;~ 			& "VHD File in Folder " &  $vhdfolder & " on System Drive " & $WinDrvDrive)
			If $wimfile <> "" And $wimfolder <> $vhdfolder Then
				MsgBox(48,"WARNING - WIM and VHD File Not in same Folder", "Selected WIM File = " & $wimfile & @CRLF & @CRLF & "Selected VHD File = " & $vhdfile & @CRLF & @CRLF _
				& "You may want VHD + WIM in same folder on System Drive " & $WinDrvDrive)
			EndIf
		EndIf
	Else
		$vhdfile_name = StringMid($vhdfile, 4)
		$vhdfile_name_only = StringMid($vhdfile, $pos + 1)
	EndIf

	If $wimfile <> "" Then
		_GUICtrlStatusBar_SetText($hStatus," Select APPLY of WIM File to VHD Or Upd WimBoot", 0)
	Else
		_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY to VHD Or Select CAPTURE ", 0)
	EndIf

	$VHDSize = FileGetSize($vhdfile)
	$VHDSize = Round($VHDSize / 1024 / 1024)
	GUICtrlSetData($VHD_Size_Label, Round($VHDSize / 1024, 1) & " GB")
	$PSize = Round($VHDSize / 1024, 1) & " GB"

	GUICtrlSetData($VHD_File, $vhdfile)
	DisableMenus(0)
EndFunc   ;==> _vhd_fsel
;===================================================================================================
Func _target_drive()
	Local $TargetSelect, $Tdrive, $FSvar, $valid = 0, $ValidDrives, $RemDrives
	Local $NoDrive[3] = ["A:", "B:", "X:"], $FileSys[2] = ["NTFS", "FAT32"]

	Local $pos, $fs_ok=0, $ikey

	DisableMenus(1)
	$ValidDrives = DriveGetDrive( "FIXED" )
	_ArrayPush($ValidDrives, "")
	_ArrayPop($ValidDrives)
	$RemDrives = DriveGetDrive( "REMOVABLE" )
	_ArrayPush($RemDrives, "")
	_ArrayPop($RemDrives)
	_ArrayConcatenate($ValidDrives, $RemDrives)
;	; _ArrayDisplay($ValidDrives)

	$TargetDrive = ""
	GUICtrlSetData($Target, "")
	GUICtrlSetData($TargetSize, "")
	GUICtrlSetData($TargetFree, "")

	$TargetSelect = FileSelectFolder("Select your Boot Drive - Active Drive for Boot Files ", "")
	If @error Then
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($TargetSelect, "\", 0, -1)
	If $pos = 0 Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - No Backslash Found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect)
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($TargetSelect, " ", 0, -1)
	If $pos Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - Space Found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect & @CRLF & @CRLF _
		& "Solution - Use simple Path without Spaces ")
		 DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($TargetSelect, ":", 0, 1)
	If $pos <> 2 Then
		MsgBox(48,"ERROR - Path Invalid", "Drive Invalid - : Not found" & @CRLF & @CRLF & "Selected Path = " & $TargetSelect)
		DisableMenus(0)
		Return
	EndIf

	$Tdrive = StringLeft($TargetSelect, 2)

	FOR $d IN $ValidDrives
		If $d = $Tdrive Then
			$valid = 1
			ExitLoop
		EndIf
	NEXT
	FOR $d IN $NoDrive
		If $d = $Tdrive Then
			$valid = 0
			MsgBox(48, "ERROR - Drive NOT Valid ", "Drive NOT Valid as Boot Drive for VHD file ", 3)
			DisableMenus(0)
			GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
			Return
		EndIf
	NEXT

	If $valid And DriveStatus($Tdrive) <> "READY" Then
		$valid = 0
		MsgBox(48, "ERROR - Drive NOT Ready", "Drive NOT READY", 3)
		DisableMenus(0)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		Return
	EndIf
	If $valid Then
		$FSvar = DriveGetFileSystem( $Tdrive )
		FOR $d IN $FileSys
			If $d = $FSvar Then
				$fs_ok = 1
				ExitLoop
			Else
				$fs_ok = 0
			EndIf
		NEXT
		IF Not $fs_ok Then
			MsgBox(48, "WARNING - Invalid FileSystem", "NTFS Or FAT32 FileSystem NOT Found" & @CRLF _
			& @CRLF & "Continue and First Format Boot Drive ", 3)
			 DisableMenus(0)
			Return
		EndIf
	EndIf

	$PartStyle = _GetDrivePartitionStyle(StringLeft($Tdrive, 1))

	$DriveType=DriveGetType($Tdrive)

	If $DriveType="Removable" Or $DriveType="Fixed" Then
		; OK
	Else
		MsgBox(48, "ERROR - Boot Drive NOT Valid", "Target Boot Drive = " & $Tdrive & " Not Valid " & @CRLF & @CRLF & _
		" Only Removable Or Fixed Drive allowed ", 0)
		DisableMenus(0)
		Return
	EndIf

	If $valid Then
		$TargetDrive = $Tdrive

		_ListUsbDrives()

		If $usbfix = 0 Then
			$ikey = MsgBox(48+4+256, "WARNING - Boot Drive is NOT USB", "Boot Drive is NOT USB Drive" & @CRLF & @CRLF & _
			"Target Boot Drive = " & $TargetDrive & "   HDD = " & $inst_disk & "   PART = " & $inst_part & @CRLF & @CRLF _
			& "Modify the Booting of your Computer ? " & @CRLF & @CRLF _
			& "Are You Sure ? - This is an Internal Harddisk ! ")
			If $ikey <> 6 Then
				$TargetDrive = ""
				DisableMenus(0)
				Return
			EndIf
		EndIf

		GUICtrlSetData($Target, $TargetDrive)
		$DriveType=DriveGetType($TargetDrive)
		$TargetSpaceAvail = Round(DriveSpaceFree($TargetDrive))
		$FSvar_TargetDrive = DriveGetFileSystem($TargetDrive)

		GUICtrlSetData($TargetSize, $FSvar_TargetDrive & "     " & Round(DriveSpaceTotal($TargetDrive) / 1024, 1) & " GB")
		GUICtrlSetData($TargetFree, "FREE  = " & Round(DriveSpaceFree($TargetDrive) / 1024, 1) & " GB")
		If $FSvar <> "FAT32" Then
			MsgBox(48, "WARNING - Boot Drive OK for BIOS ", "Boot Drive has " & $FSvar & " - OK for BIOS only " & @CRLF _
			& @CRLF & "UEFI Firmware needs FAT32 Boot Drive")
		EndIf
	Else
		$TargetDrive = ""
		GUICtrlSetData($Target, "")
		GUICtrlSetData($TargetSize, "")
		GUICtrlSetData($TargetFree, "")
		MsgBox(48, "ERROR - Drive NOT Valid", "Drive NOT Valid as Boot Drive for VHD file ", 3)
		DisableMenus(0)
		GUICtrlSetState($TargetSel, $GUI_ENABLE + $GUI_FOCUS)
		Return
	EndIf
	DisableMenus(0)
EndFunc   ;==> _target_drive
;===================================================================================================
Func _WinDrv_drive()
	Local $WinDrvSelect, $Tdrive, $FSvar, $valid = 0, $ValidDrives, $RemDrives
	Local $NoDrive[3] = ["A:", "B:", "X:"], $FileSys[1] = ["NTFS"]
	Local $pos

	DisableMenus(1)
	$WIM_Path = ""
	$ValidDrives = DriveGetDrive( "FIXED" )
	_ArrayPush($ValidDrives, "")
	_ArrayPop($ValidDrives)
	$RemDrives = DriveGetDrive( "REMOVABLE" )
	_ArrayPush($RemDrives, "")
	_ArrayPop($RemDrives)
	_ArrayConcatenate($ValidDrives, $RemDrives)
	; _ArrayDisplay($ValidDrives)

	$WinDrvDrive = ""
	GUICtrlSetData($WinDrv, "")
	GUICtrlSetData($WinDrvSize, "")
	GUICtrlSetData($WinDrvFree, "")
	_GUICtrlStatusBar_SetText($hStatus," Select Wimboot Folder on System Drive", 0)

	$WinDrvSelect = FileSelectFolder("Select Wimboot Folder on System Drive ", "")
	If @error Then
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($WinDrvSelect, "\", 0, -1)
	If $pos = 0 Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - No Backslash Found" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect)
		DisableMenus(0)
		Return
	EndIf

	If StringLen($WinDrvSelect) > 3 And StringRegExp(StringMid($WinDrvSelect, 4), "[^A-Z0-9a-z-_]") Or StringLen($WinDrvSelect) > 11 Then
		MsgBox(48,"ERROR - Folder Name Not Valid", "Only Root Folder Max 8 chars allowed" & @CRLF & @CRLF _
		& "Only Chars 0-9 A-Z a-z - _ allowed in Folder Name" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect & @CRLF & @CRLF _
		& "Solution -Select simple Root Folder Max 8 chars ")
		DisableMenus(0)
		Return
	EndIf

;~ 		$pos = StringInStr($WinDrvSelect, " ", 0, -1)
;~ 		If $pos Then
;~ 			MsgBox(48,"ERROR - Path Invalid", "Path Invalid - Space Found" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect & @CRLF & @CRLF _
;~ 			& "Solution - Use simple Path without Spaces ")
;~ 			DisableMenus(0)
;~ 			Return
;~ 		EndIf

;~ 		$pos = StringInStr($WinDrvSelect, ".", 0, -1)
;~ 		If $pos Then
;~ 			MsgBox(48,"ERROR - Path Invalid", "Path Invalid - Dot Found" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect & @CRLF & @CRLF _
;~ 			& "Solution - Use simple Path without Dot ")
;~ 			DisableMenus(0)
;~ 			Return
;~ 		EndIf

	$pos = StringInStr($WinDrvSelect, ":", 0, 1)
	If $pos <> 2 Then
		MsgBox(48,"ERROR - Path Invalid", "Drive Invalid - : Not found" & @CRLF & @CRLF & "Selected Path = " & $WinDrvSelect)
		DisableMenus(0)
		Return
	EndIf

	If $wimfile <> "" And StringLeft($wimfile, 3) <> StringLeft($WinDrvSelect, 3) Then
		MsgBox(48,"ERROR - System Drive Not Valid", "WIM File Not on System Drive" & @CRLF & @CRLF & "Selected WIM = " & $wimfile & @CRLF & @CRLF _
		& "Selected System Drive Path = " & $WinDrvSelect)
		DisableMenus(0)
		Return
	EndIf

	If $vhdfile <> "" And StringLeft($vhdfile, 3) <> StringLeft($WinDrvSelect, 3) Then
		MsgBox(48,"ERROR - System Drive Not Valid", "VHD File Not on System Drive" & @CRLF & @CRLF & "Selected VHD = " & $vhdfile & @CRLF & @CRLF _
		& "Selected System Drive Path = " & $WinDrvSelect)
		DisableMenus(0)
		Return
	EndIf

	$Tdrive = StringLeft($WinDrvSelect, 2)
	FOR $d IN $ValidDrives
		If $d = $Tdrive Then
			$valid = 1
			ExitLoop
		EndIf
	NEXT
	FOR $d IN $NoDrive
		If $d = $Tdrive Then
			$valid = 0
			MsgBox(48, "ERROR - Drive NOT Valid", " Drive A: B: and X: ", 3)
			DisableMenus(0)
			Return
		EndIf
	NEXT
	If $valid And DriveStatus($Tdrive) <> "READY" Then
		$valid = 0
		MsgBox(48, "ERROR - Drive NOT Ready", "Drive NOT READY", 3)
		DisableMenus(0)
		Return
	EndIf
	If $valid Then
		$FSvar = DriveGetFileSystem( $Tdrive )
		FOR $d IN $FileSys
			If $d = $FSvar Then
				$valid = 1
				ExitLoop
			Else
				$valid = 0
			EndIf
		NEXT
		IF Not $valid Then
			MsgBox(48, "ERROR - Invalid FileSystem", " NTFS FileSystem NOT Found ", 3)
			DisableMenus(0)
			Return
		EndIf
	EndIf

	$DriveSysType=DriveGetType($Tdrive)

	If $DriveSysType="Removable" Or $DriveSysType="Fixed" Then
	Else
		MsgBox(48, "ERROR - Target System Drive NOT Valid", "Target System Drive = " & $Tdrive & " Not Valid " & @CRLF & @CRLF & _
		" Only Removable Or Fixed Drive allowed ", 0)
		DisableMenus(0)
		Return
	EndIf

	If $valid Then
		$WinDrvDrive = StringLeft($WinDrvSelect, 2)

		$WIM_Path = $WinDrvSelect

		If StringLen($WIM_Path) < 12 Then
			If StringLen($WIM_Path) = 3 Then
				If Not FileExists($WinDrvDrive & "\Wimboot") Then DirCreate($WinDrvDrive & "\Wimboot")
				$WIM_Path = $WinDrvDrive & "\Wimboot"
			Else
				$pos = StringInStr(StringMid($WIM_Path, 4), "\", 0, -1)
				If $pos <> 0 Then
					If Not FileExists($WinDrvDrive & "\Wimboot") Then DirCreate($WinDrvDrive & "\Wimboot")
					$WIM_Path = $WinDrvDrive & "\Wimboot"
					MsgBox(48, "WARNING - Nested Folder", " Select Root Folder Max 8 chars ", 3)
				EndIf
			EndIf
		Else
			If Not FileExists($WinDrvDrive & "\Wimboot") Then DirCreate($WinDrvDrive & "\Wimboot")
			$WIM_Path = $WinDrvDrive & "\Wimboot"
			MsgBox(48, "WARNING - Path Invalid", "Select Root Folder Max 8 chars ", 3)
		EndIf

		$FSvar_WinDrvDrive = DriveGetFileSystem($WinDrvDrive)

		$DriveSysType=DriveGetType($WinDrvDrive)

		GUICtrlSetData($WinDrv, $WIM_Path)
		$WinDrvSpaceAvail = Round(DriveSpaceFree($WinDrvDrive))
		GUICtrlSetData($WinDrvSize, $FSvar_WinDrvDrive & "     " & Round(DriveSpaceTotal($WinDrvDrive) / 1024, 1) & " GB")
		GUICtrlSetData($WinDrvFree, "FREE  = " & Round(DriveSpaceFree($WinDrvDrive) / 1024, 1) & " GB")
		_GUICtrlStatusBar_SetText($hStatus," Select WIM Or VHD File on System Drive ", 0)
	EndIf
	DisableMenus(0)
EndFunc   ;==> _WinDrv_drive
;===================================================================================================
Func _APPLY_WIM_ToVHD()
	Local $i=0, $d, $ikey

	Local $linesplit[20], $file, $line, $AutoPlay_Data=""

	Local $val=0, $valid = 0, $AllDrives

	Local $TempDrives[8] = ["V:", "T:", "S:", "Q:", "P:", "O:", "Y:", "W:"]

	DisableMenus(1)

	If $vhdfile <> "" And FileExists($vhdfile) Then
		$vhd_size = $VHDSize
	Else
		$PSize = GUICtrlRead($ComboSize)
		If $PSize = "1.0 GB" Then
			$vhd_size="1000"
		ElseIf $PSize = "1.5 GB" Then
			$vhd_size="1500"
		ElseIf $PSize = "2.0 GB" Then
			$vhd_size="2000"
		ElseIf $PSize = "2.5 GB" Then
			$vhd_size="2500"
		ElseIf $PSize = "3.0 GB" Then
			$vhd_size="3000"
		ElseIf $PSize = "3.5 GB" Then
			$vhd_size="3500"
		ElseIf $PSize = "3.9 GB" Then
			$vhd_size="3900"
		ElseIf $PSize = "5.0 GB" Then
			$vhd_size="5000"
		ElseIf $PSize = "6.0 GB" Then
			$vhd_size="6000"
		ElseIf $PSize = "7.0 GB" Then
			$vhd_size="7000"
		ElseIf $PSize = "10.0 GB" Then
			$vhd_size="10000"
		ElseIf $PSize = "15.0 GB" Then
			$vhd_size="15000"
		ElseIf $PSize = "25.0 GB" Then
			$vhd_size="25000"
		ElseIf $PSize = "50.0 GB" Then
			$vhd_size="50000"
		ElseIf $PSize = "100.0 GB" Then
			$vhd_size="100000"
		Else
			$PSize = "3.9 GB"
			$vhd_size="3900"
		EndIf
	EndIf

	If GUICtrlRead($WIMBOOT) = $GUI_UNCHECKED And $vhd_size < 25000 Then
		MsgBox(48, " STOP - VHD Size too Small fo Full Apply ", " VHD Size less than 25 GB " & @CRLF & @CRLF & " Increase VHD Size Or Select WimBoot Mode ", 0)
		GUICtrlSetData($ProgressAll, 0)
		_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY Or Select Exit ", 0)
		DisableMenus(0)
		Return
	EndIf

	If $TargetDrive = "" Then
		$ikey = MsgBox(48+4+256, " Boot Drive Not Selected ", " Continue without making Boot entries ? ")
		If $ikey = 6 Then
		Else
			DisableMenus(0)
			Return
		EndIf
	EndIf

	If FileExists(@ScriptDir & "\makebt\bs_temp") Then DirRemove(@ScriptDir & "\makebt\bs_temp",1)
	If Not FileExists(@ScriptDir & "\makebt\bs_temp") Then DirCreate(@ScriptDir & "\makebt\bs_temp")

	SystemFileRedirect("On")

	If Not FileExists(@WindowsDir & "\system32\diskpart.exe") Then
		SystemFileRedirect("Off")
		MsgBox(48, "ERROR - DiskPart Not Found ", " system32\diskpart.exe needed to Create VHD Drive " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 10 PE ")
		DisableMenus(0)
		Return
	EndIf

	If FileExists(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt")

	RunWait(@ComSpec & " /c reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay" & " > makebt\vhd_temp\Reg_DisableAutoPlay.txt", @ScriptDir, @SW_HIDE)

	$file = FileOpen(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt", 0)
	While 1
		$line = FileReadLine($file)
		If @error = -1 Then ExitLoop
		If $line <> "" Then
			$line = StringStripWS($line, 7)
			$linesplit = StringSplit($line, " ")
			; _ArrayDisplay($linesplit)
			If $linesplit[1] = "DisableAutoplay" Then
				$AutoPlay_Data = $linesplit[3]
			EndIf
		EndIf
	Wend
	FileClose($file)

	; MsgBox(48, "Info AutoPlay ", "  " & @CRLF & @CRLF & " AutoPlay_Data = " & $AutoPlay_Data, 0)

	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 1 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Disabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 1 ", 0)
	EndIf

	; Mount Existing vhdfile as $tmpdrive
	If $vhdfile <> "" And FileExists($vhdfile) Then
		_Mount_VHD()

		; In case _Mount_VHD failure return
		If $tmpdrive = "" Then
			; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
			If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
				RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
				; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
			EndIf
			SystemFileRedirect("Off")
			MsgBox(48, " STOP - VHD Drive Not Found", " Attach / Detach VHD - DiskPart Error " & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
			GUICtrlSetData($ProgressAll, 0)
			_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY Or Select Exit ", 0)
			DisableMenus(0)
			Return
		EndIf

		$val = _WinAPI_FormatDriveDlg($tmpdrive, $SHFMT_OPT_QUICKFORMAT)
		If $val <> 0 Then
			; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
			If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
				RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
				; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
			EndIf
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
			SystemFileRedirect("Off")
			MsgBox(48, " STOP - VHD Format Cancelled", " VHD Format Cancelled - Error = " & $val, 0)
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			Return
		EndIf

	Else
		; Create VHD File
		GUICtrlSetData($ProgressAll, 10)

		If FileExists(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt")
		If FileExists(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt")
		If FileExists(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt")

		$PSize = GUICtrlRead($ComboSize)
		If $PSize = "1.0 GB" Then
			$vhd_size="1000"
		ElseIf $PSize = "1.5 GB" Then
			$vhd_size="1500"
		ElseIf $PSize = "2.0 GB" Then
			$vhd_size="2000"
		ElseIf $PSize = "2.5 GB" Then
			$vhd_size="2500"
		ElseIf $PSize = "3.0 GB" Then
			$vhd_size="3000"
		ElseIf $PSize = "3.5 GB" Then
			$vhd_size="3500"
		ElseIf $PSize = "3.9 GB" Then
			$vhd_size="3900"
		ElseIf $PSize = "5.0 GB" Then
			$vhd_size="5000"
		ElseIf $PSize = "6.0 GB" Then
			$vhd_size="6000"
		ElseIf $PSize = "7.0 GB" Then
			$vhd_size="7000"
		ElseIf $PSize = "10.0 GB" Then
			$vhd_size="10000"
		ElseIf $PSize = "15.0 GB" Then
			$vhd_size="15000"
		ElseIf $PSize = "25.0 GB" Then
			$vhd_size="25000"
		ElseIf $PSize = "50.0 GB" Then
			$vhd_size="50000"
		ElseIf $PSize = "100.0 GB" Then
			$vhd_size="100000"
		Else
			$PSize = "3.9 GB"
			$vhd_size="3900"
		EndIf

		If $WinDrvSpaceAvail < $vhd_size + 2000 Then
			; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
			If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
				RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
				; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
			EndIf
			SystemFileRedirect("Off")
			MsgBox(48, "ERROR - Not enough Space on Target System Drive ", " ERROR - Not enough Space on Target System Drive " & @CRLF & @CRLF _
			& " Free Space = " & Round($WinDrvSpaceAvail / 1024, 1) & " GB " & @CRLF & @CRLF & " New VHD Size = " & $PSize, 0)
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			Return
		EndIf
		If $vhdfile = "" Then
			For $i = 1 To 9
				If GUICtrlRead($VHDX) = "VHD" Then
					If Not FileExists($WinDrvDrive & "\" & $vhd_name & $i & ".vhd") Then
						$vhdfile_name = $vhd_name & $i & ".vhd"
						$vhdfile_name_only = $vhdfile_name
						ExitLoop
					EndIf
					If $i = 9 Then
						; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
						If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
							RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
							; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
						EndIf
						SystemFileRedirect("Off")
						MsgBox(48, "Error - Too many " & $vhd_name & "X.vhd VHD Files ", " Max X = 9 on Drive " & $WinDrvDrive & @CRLF & @CRLF _
						&  " Remove or Rename some VHD Files on Drive " & $WinDrvDrive)
						GUICtrlSetData($ProgressAll, 0)
						DisableMenus(0)
						Return
					EndIf
				Else
					If Not FileExists($WinDrvDrive & "\" & $vhd_name & $i & ".vhdx") Then
						$vhdfile_name = $vhd_name & $i & ".vhdx"
						$vhdfile_name_only = $vhdfile_name
						ExitLoop
					EndIf
					If $i = 9 Then
						; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
						If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
							RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
							; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
						EndIf
						SystemFileRedirect("Off")
						MsgBox(48, "Error - Too many " & $vhd_name & "X.vhdx VHDX Files ", " Max X = 9 on Drive " & $WinDrvDrive & @CRLF & @CRLF _
						&  " Remove or Rename some VHD Files on Drive " & $WinDrvDrive)
						GUICtrlSetData($ProgressAll, 0)
						DisableMenus(0)
						Return
					EndIf
				EndIf
			Next
		EndIf

		; _GUICtrlStatusBar_SetText($hStatus," Search Free Drive Letter for VHD ", 0)
		GUICtrlSetData($ProgressAll, 15)

		$AllDrives = DriveGetDrive( "all" )

		;  _ArrayDisplay($AllDrives)

		FOR $d IN $TempDrives
			If Not FileExists($d & "\nul") Then
				$valid = 1
				For $i = 1 to $AllDrives[0]
					If $d = $AllDrives[$i] Then
						$valid = 0
					;	MsgBox(48,"Invalid Drive " & $i, "Invalid Drive " & $AllDrives[$i])
					EndIf
				Next
				If $valid Then
					$tmpdrive = $d
					ExitLoop
				EndIf
			Else
				$valid = 0
			EndIf
		NEXT

		IF $tmpdrive = "" Or Not $valid Then
			; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
			If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
				RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
				; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
			EndIf
			SystemFileRedirect("Off")
			MsgBox(48, "ERROR - VHD Drive Not available", "No Free Drive Letter for VHD Drive " _
			& @CRLF & @CRLF & "Please Reboot Computer and try again ")
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			Return
		EndIf

		_GUICtrlStatusBar_SetText($hStatus," Create Target " & $WinDrvDrive & "\" & $vhdfile_name & " - wait ....", 0)
		GUICtrlSetData($ProgressAll, 20)
		If GUICtrlRead($VHD_TYPE) = "Expand" Then
			FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","create vdisk file=" & '"' & $WinDrvDrive & "\" & $vhdfile_name & '"' & " maximum=" & $vhd_size & " type=expandable")
		Else
			FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","create vdisk file=" & '"' & $WinDrvDrive & "\" & $vhdfile_name & '"' & " maximum=" & $vhd_size & " type=fixed")
		EndIf
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","select vdisk file=" & '"' & $WinDrvDrive & "\" & $vhdfile_name & '"')
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","attach vdisk")
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","create partition primary")
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","active")
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","FORMAT FS=NTFS LABEL=" & '"' & $vhdfile_name & '"' & " QUICK")
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","assign letter=" & StringLeft($tmpdrive, 1))
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt","exit")

		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt","select vdisk file=" & '"' & $WinDrvDrive & "\" & $vhdfile_name & '"')
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt","detach vdisk")
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt","exit")

		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\make_vhd.txt", @ScriptDir)
		If $val <> 0 Then
			; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
			If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
				RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
				; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
			EndIf
			SystemFileRedirect("Off")
			MsgBox(48, " STOP - Error DiskPart", " Create Dest VHD - DiskPart Error = " & $val, 0)
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			Return
		EndIf
	EndIf

	GUICtrlSetData($ProgressAll, 20)
	sleep(2000)
	; MsgBox(48, "VHD Mounted ", "  " & @CRLF & @CRLF & " VHD Drive = " & $tmpdrive, 0)

	If $wimfile <> "" Then
;~ 		If GUICtrlRead($wimlib_dism) = "Dism" Then

;~ 			If FileExists(@WindowsDir & "\System32\Dism.exe") Then
;~ 				_GUICtrlStatusBar_SetText($hStatus," APPLY to VHD by Dism - wait .... ", 0)
;~ 				$val = ShellExecuteWait('"' & @WindowsDir & "\System32\Dism.exe" & '"', "/Apply-Image /ImageFile:" & '"' & $wimfile & '"' & " /ApplyDir:" & '"' & $tmpdrive & '"' & " /Index:1 /WIMBoot", "", "open")

			; EndIf
; 		Else
			_GUICtrlStatusBar_SetText($hStatus," APPLY WIM to " & $vhdfile_name & " by wimlib - wait .... ", 0)
			If @OSArch = "X86" Then
				If GUICtrlRead($WIMBOOT) = $GUI_CHECKED Then
					$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x86\wimlib-imagex.exe" & '"', "apply " & '"' & $wimfile & '"' & " " & $tmpdrive & "\ --wimboot", "", "open")
				Else
					$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x86\wimlib-imagex.exe" & '"', "apply " & '"' & $wimfile & '"' & " " & $tmpdrive & "\", "", "open")
				EndIf
			Else
				If GUICtrlRead($WIMBOOT) = $GUI_CHECKED Then
					$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x64\wimlib-imagex.exe" & '"', "apply " & '"' & $wimfile & '"' & " " & $tmpdrive & "\ --wimboot", "", "open")
				Else
					$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x64\wimlib-imagex.exe" & '"', "apply " & '"' & $wimfile & '"' & " " & $tmpdrive & "\", "", "open")
				EndIf
			EndIf
; 		EndIf
	EndIf


	GUICtrlSetData($ProgressAll, 30)

	sleep(2000)

	$VHDSpaceAvail = Round(DriveSpaceFree($tmpdrive))
	If $VHDSpaceAvail < 300 Then
		$VHD_Overflow = 1
	EndIf

	If FileExists($tmpdrive & $WinFol & "\system32\drivers\svbusx86.sys") Or FileExists($tmpdrive & $WinFol & "\system32\drivers\svbusx64.sys") Then
		If StringRight($vhdfile_name, 4) = ".vhd"  Then
			$driver_flag = 3
		Else
			$driver_flag = 0
		EndIf
;~ 	ElseIf FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") Then
;~ 		$driver_flag = 1
;~ 	ElseIf FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Then
;~ 		$driver_flag = 2
	Else
		$driver_flag = 0
	EndIf

	If FileExists($tmpdrive & $WinFol & "\system32\drivers\vhdmp.sys") Then
		$vhdmp=1
	EndIf

	If FileExists($tmpdrive & $WinFol & "\SysWOW64") Then
		$SysWOW64=1
	EndIf

	If FileExists($tmpdrive & "\Windows\system32\winload.exe") Then
		$winload_flag = 1
	EndIf

	_DetectLang()

	GUICtrlSetData($ProgressAll, 45)

	; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
	EndIf


	GUICtrlSetData($ProgressAll, 50)

	If $winload_flag = 1 Then
		_BCD_Inside_VHD()
	EndIf

	If $TargetDrive = "" Then
		_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
		GUICtrlSetData($ProgressAll, 70)
		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
		If $val <> 0 Then
			MsgBox(48, " Error DiskPart", " Detach Dest VHD - DiskPart Error = " & $val, 0)
		EndIf

		SystemFileRedirect("Off")

		sleep(2000)
		GUICtrlSetData($ProgressAll, 100)
		_GUICtrlStatusBar_SetText($hStatus," End of Program ", 0)

	 	If $VHD_Overflow = 0 And $winload_flag = 1 Then
	 		MsgBox(64, " END OF PROGRAM - OK ", " End of Program  - OK " & @CRLF _
	 		& @CRLF & $vhdfile_name & " is on System Drive " & $WinDrvDrive)
	 	Else
			If $VHD_Overflow = 1 Then
				MsgBox(48, "OVERFLOW - Not enough Space in VHD Drive ", " OVERFLOW - Not enough Space in " & $vhdfile_name & @CRLF _
				& @CRLF & " Free Space = " & $VHDSpaceAvail & " MB " & @CRLF _
				& @CRLF & $vhdfile_name & " is on System Drive " & $WinDrvDrive, 0)
			EndIf
			If $winload_flag = 0 Then
				MsgBox(64, " END OF PROGRAM - VHD Invalid ", " End of Program  - winload.exe Missing " & @CRLF _
				& @CRLF & "Boot files NOT created on Boot Drive " & $TargetDrive & @CRLF _
				& @CRLF & $vhdfile_name & " is on System Drive " & $WinDrvDrive)
			EndIf
		EndIf
		Exit
	EndIf

	If $TargetDrive <> "" And $VHD_Overflow = 0 And $winload_flag = 1 Then
		_Boot_Entries()
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
	GUICtrlSetData($ProgressAll, 70)
	$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
	If $val <> 0 Then
		MsgBox(48, " Error DiskPart", " Detach VHD - DiskPart Error = " & $val, 0)
	EndIf

	SystemFileRedirect("Off")

	sleep(2000)
	GUICtrlSetData($ProgressAll, 100)
	_GUICtrlStatusBar_SetText($hStatus," End of Program ", 0)

	If $VHD_Overflow = 0 And $winload_flag = 1 Then
		MsgBox(64, " END OF PROGRAM - OK ", " End of Program  - OK " & @CRLF _
		& @CRLF & "Boot files created on Boot Drive " & $TargetDrive & @CRLF _
		& @CRLF & $vhdfile_name & " is on System Drive " & $WinDrvDrive)
	Else
		If $VHD_Overflow = 1 Then
			MsgBox(48, "OVERFLOW - Not enough Space in VHD Drive ", " OVERFLOW - Not enough Space in " & $vhdfile_name & @CRLF _
			& @CRLF & " Free Space = " & $VHDSpaceAvail & " MB " & @CRLF _
			& @CRLF & $vhdfile_name & " is on System Drive " & $WinDrvDrive, 0)
		EndIf
		If $winload_flag = 0 Then
			MsgBox(64, " END OF PROGRAM - VHD Invalid ", " End of Program  - winload.exe Missing " & @CRLF _
			& @CRLF & "Boot files NOT created on Boot Drive " & $TargetDrive & @CRLF _
			& @CRLF & $vhdfile_name & " is on System Drive " & $WinDrvDrive)
		EndIf
	EndIf
	Exit
EndFunc   ;==> _APPLY_WIM_ToVHD
;===================================================================================================
Func _CAPTURE_VHD_ToWIM()

	Local $val=0, $i=0, $capt_nr=1, $capt_name="W10x64_US_"
	Local $linesplit[20], $file, $line, $AutoPlay_Data=""

	DisableMenus(1)

	SystemFileRedirect("On")

	If Not FileExists(@WindowsDir & "\system32\diskpart.exe") Then
		SystemFileRedirect("Off")
		MsgBox(48, "ERROR - DiskPart Not Found ", " system32\diskpart.exe needed to Create VHD Drive " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 10 PE ")
		DisableMenus(0)
		Return
	EndIf

	If FileExists(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt")

	RunWait(@ComSpec & " /c reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay" & " > makebt\vhd_temp\Reg_DisableAutoPlay.txt", @ScriptDir, @SW_HIDE)

	$file = FileOpen(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt", 0)
	While 1
		$line = FileReadLine($file)
		If @error = -1 Then ExitLoop
		If $line <> "" Then
			$line = StringStripWS($line, 7)
			$linesplit = StringSplit($line, " ")
			; _ArrayDisplay($linesplit)
			If $linesplit[1] = "DisableAutoplay" Then
				$AutoPlay_Data = $linesplit[3]
			EndIf
		EndIf
	Wend
	FileClose($file)

	; MsgBox(48, "Info AutoPlay ", "  " & @CRLF & @CRLF & " AutoPlay_Data = " & $AutoPlay_Data, 0)

	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 1 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Disabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 1 ", 0)
	EndIf
	If FileExists(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt")
	If FileExists(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt")
	If FileExists(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt")


	; Mount Existing vhdfile as $tmpdrive
	_Mount_VHD()

	; In case _Mount_VHD failure return
	If $tmpdrive = "" Then
		; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
		EndIf
		SystemFileRedirect("Off")
		MsgBox(48, " STOP - VHD Drive Not Found", " Attach / Detach VHD - DiskPart Error " & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
		_GUICtrlStatusBar_SetText($hStatus," Select Exit Or Select CAPTURE ", 0)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		Return
	EndIf

	If Not FileExists($tmpdrive & "\Windows\system32\winload.exe") Then
		; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
		EndIf
		_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
		GUICtrlSetData($ProgressAll, 70)
		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
		SystemFileRedirect("Off")
		MsgBox(48, " STOP - VHD Invalid", " VHD Invalid - winload.exe Missing " & @CRLF & @CRLF & " Invalid VHD " & $vhdfile, 0)
		_GUICtrlStatusBar_SetText($hStatus," Select Exit Or Select VHD ", 0)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		Return
	EndIf

	; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
	EndIf

	_DetectLang()

	If FileExists($tmpdrive & "\Windows\System32\config\DRIVERS") Then
		If FileExists($tmpdrive & "\Windows\SystemApps") Then
			$capt_name = "W10"
		Else
			$capt_name = "W8"
		EndIf
	Else
		$capt_name = "W7"
	EndIf

	If FileExists($tmpdrive & "\Windows\SysWOW64") Then
		$capt_name = $capt_name & "x64_" & StringRight($DistLang, 2) & "_"
	Else
		$capt_name = $capt_name & "x86_" & StringRight($DistLang, 2) & "_"
	EndIf

	For $i = 1 To 9
		If Not FileExists($WIM_Path & "\" & $capt_name & $i & ".wim") Then
			$capt_nr = $i
			ExitLoop
		EndIf
		If $i = 9 Then
			_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
			GUICtrlSetData($ProgressAll, 70)
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
;~ 			If $val <> 0 Then
;~ 				MsgBox(48, " Error DiskPart", " Detach Dest VHD - DiskPart Error = " & $val, 0)
;~ 			EndIf
			SystemFileRedirect("Off")
			MsgBox(48, "Error - Too many " & $capt_name & "X.wim Files in "& $WIM_Path, " Max X = 9 on Drive " & $WIM_Path & @CRLF & @CRLF _
			&  " Remove or Rename some WIM Files in " & $WIM_Path, 0)
			_GUICtrlStatusBar_SetText($hStatus," Select Exit Or Select CAPTURE ", 0)
			GUICtrlSetData($ProgressAll, 0)
			DisableMenus(0)
			Return
		EndIf
	Next
	$WinDrvSpaceAvail = Round(DriveSpaceFree($WinDrvDrive))
	If $WinDrvSpaceAvail < 15000 Then
		_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
		GUICtrlSetData($ProgressAll, 70)
		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
		SystemFileRedirect("Off")
		MsgBox(48, "Error - Not enough FREE Space ", " Not enough FREE Space on Drive " & $WinDrvDrive & @CRLF & @CRLF _
		&  " FREE Space is " & $WinDrvSpaceAvail & " MB", 0)
		_GUICtrlStatusBar_SetText($hStatus," Select Exit Or Select CAPTURE ", 0)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		Return
	EndIf

	GUICtrlSetData($ProgressAll, 30)
;~ 		If GUICtrlRead($wimlib_dism) = "Dism" Then
;~ 			_GUICtrlStatusBar_SetText($hStatus," Dism is used for CAPTURE of Drive " & $tmpdrive & " - wait .... ", 0)
;~ 			$val = ShellExecuteWait('"' & @WindowsDir & "\System32\Dism.exe" & '"', "/Capture-Image /ImageFile:" & '"' & $WIM_Path & "\" & $capt_name & $capt_nr & ".wim" & '"' & " /CaptureDir:" & '"' & $tmpdrive & '"' & " /Name:" & $capt_name & $capt_nr & ".wim /ConfigFile:" & '"' & $config_file_wimboot & '"' & " /WIMBoot /CheckIntegrity", "", "open")
;~ 			If $val <> 0 Then
;~ 				MsgBox(48, "WARNING - Dism CAPTURE", "Dism CAPTURE return with error code : " & $val, 0)
;~ 			EndIf
;~ 		Else
		_GUICtrlStatusBar_SetText($hStatus," wimlib is used for CAPTURE of Drive " & $tmpdrive & " - wait .... ", 0)
		If @OSArch = "X86" Then
			If GUICtrlRead($LZX) = $GUI_CHECKED Then
				$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x86\wimlib-imagex.exe" & '"', "capture " & $tmpdrive & "\ " & '"' & $WIM_Path & "\" & $capt_name & $capt_nr & ".wim" & '"' & " " & '"' & $vhdfile_name_only & '"' & " --config=" & '"' & $config_file_wimboot & '"' & " --include-integrity --wimboot --compress=LZX --chunk-size=32K", "", "open")
			Else
				$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x86\wimlib-imagex.exe" & '"', "capture " & $tmpdrive & "\ " & '"' & $WIM_Path & "\" & $capt_name & $capt_nr & ".wim" & '"' & " " & '"' & $vhdfile_name_only & '"' & " --config=" & '"' & $config_file_wimboot & '"' & " --include-integrity --wimboot", "", "open")
			EndIf
		Else
			If GUICtrlRead($LZX) = $GUI_CHECKED Then
				$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x64\wimlib-imagex.exe" & '"', "capture " & $tmpdrive & "\ " & '"' & $WIM_Path & "\" & $capt_name & $capt_nr & ".wim" & '"' & " " & '"' & $vhdfile_name_only & '"' & " --config=" & '"' & $config_file_wimboot & '"' & " --include-integrity --wimboot --compress=LZX --chunk-size=32K", "", "open")
			Else
				$val = ShellExecuteWait('"' & @ScriptDir & "\wimlib_x64\wimlib-imagex.exe" & '"', "capture " & $tmpdrive & "\ " & '"' & $WIM_Path & "\" & $capt_name & $capt_nr & ".wim" & '"' & " " & '"' & $vhdfile_name_only & '"' & " --config=" & '"' & $config_file_wimboot & '"' & " --include-integrity --wimboot", "", "open")
			EndIf
		EndIf
	; EndIf

	If $vhdfile <> "" And $tmpdrive <> "" Then
		_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
		GUICtrlSetData($ProgressAll, 70)
		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
		If $val <> 0 Then
			MsgBox(48, " Error DiskPart", " Detach Dest VHD - DiskPart Error = " & $val, 0)
		EndIf
	EndIf

	SystemFileRedirect("Off")

	sleep(2000)

	GUICtrlSetData($ProgressAll, 100)
	_GUICtrlStatusBar_SetText($hStatus," End of Capture ", 0)
	MsgBox(64, " END OF CAPTURE - OK ", " End of Capture  - OK " & @CRLF _
	& @CRLF & "CAPTURE of VHD Source File " & $vhdfile & @CRLF _
	& @CRLF & $capt_name & $capt_nr & ".wim WIM File in Folder " & $WIM_Path)

	_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY Or Select Exit ", 0)
	GUICtrlSetData($ProgressAll, 0)
	DisableMenus(0)
	Return

EndFunc   ;==> _CAPTURE_VHD_ToWIM
;===================================================================================================
Func _Mount_VHD()
	Local $val=0, $vhd_found=0, $vhd_drive="", $any_drive="", $count_mp=0
	Local $linesplit[20], $file, $line, $count = 0, $i, $d
	Local $NoVirtDrives, $FixedDrives

	$tmpdrive = ""

	If FileExists(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt")
	If FileExists(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\make_vhd.txt")
	If FileExists(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt")

	_GUICtrlStatusBar_SetText($hStatus," Source VHD will be Attached - wait .... ", 0)
	$NoVirtDrives = DriveGetDrive( "FIXED" )
	; _ArrayDisplay($NoVirtDrives)
	sleep(1000)
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt","select vdisk file=" & '"' & $vhdfile & '"')
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt","attach vdisk")
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\attach_vhd.txt","exit")
	; Find Drive Letter

	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt","select vdisk file=" & '"' & $vhdfile & '"')
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt","detach vdisk")
	FileWriteLine(@ScriptDir & "\makebt\vhd_temp\detach_vhd.txt","exit")

	$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\attach_vhd.txt", @ScriptDir, @SW_HIDE)
	If $val <> 0 Then
		; MsgBox(48, " STOP - Error DiskPart", " Attach VHD - DiskPart Error = " & $val & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
		Return
;~ 		sleep(3000)
;~ 		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
;~ 		If $val <> 0 Then
;~ 			; SystemFileRedirect("Off")
;~ 			MsgBox(48, " STOP - Error DiskPart", " Attach / Detach VHD - DiskPart Error = " & $val & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
;~ 			; Exit
;~ 			$tmpdrive = ""
;~ 			; GUICtrlSetData($ProgressAll, 0)
;~ 			; DisableMenus(0)
;~ 			Return
;~ 		Else
;~ 			sleep(1000)
;~ 			$NoVirtDrives = DriveGetDrive( "FIXED" )
;~ 			sleep(1000)
;~ 			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\attach_vhd.txt", @ScriptDir, @SW_HIDE)
;~ 			If $val <> 0 Then
;~ 				;SystemFileRedirect("Off")
;~ 				MsgBox(48, " STOP - Error DiskPart", " Attach VHD - DiskPart Error = " & $val & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
;~ 				; Exit
;~ 				$tmpdrive = ""
;~ 				; GUICtrlSetData($ProgressAll, 0)
;~ 				; DisableMenus(0)
;~ 				Return
;~ 			EndIf
;~ 		EndIf
	EndIf

	_GUICtrlStatusBar_SetText($hStatus," Source VHD Attached - wait .... ", 0)

	If FileExists(@ScriptDir & "\makebt\wim_info\vhdlist.txt") Then
		FileCopy(@ScriptDir & "\makebt\wim_info\vhdlist.txt", @ScriptDir & "\makebt\wim_info\vhdlist_bak.txt", 1)
		FileDelete(@ScriptDir & "\makebt\wim_info\vhdlist.txt")
	EndIf

	sleep(2000)
	$FixedDrives = DriveGetDrive( "FIXED" )
	; _ArrayDisplay($FixedDrives)

	RunWait(@ComSpec & " /c makebt\listusbdrives\ListUsbDrives.exe -a > makebt\wim_info\vhdlist.txt", @ScriptDir, @SW_HIDE)

	$file = FileOpen(@ScriptDir & "\makebt\wim_info\vhdlist.txt", 0)
	If $file <> -1 Then
		$count = 0
		$count_mp = 0
		$any_drive = ""
		$vhd_found = 0
		$vhd_drive = ""
		While 1
			$line = FileReadLine($file)
			If @error = -1 Then ExitLoop
			If $line <> "" Then
				$count = $count + 1
				$linesplit = StringSplit($line, "=")
				$linesplit[1] = StringStripWS($linesplit[1], 3)
				If $linesplit[1] = "MountPoint" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					$any_drive = $linesplit[2]
					$count_mp = $count
				EndIf
				If $linesplit[1] = "Bus Type" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					If $linesplit[2] = "BusType15" And StringLen($any_drive) = 3 Then
						For $i = 1 to $FixedDrives[0]
							For $d = 1 to $NoVirtDrives[0]
								If $FixedDrives[$i] = $NoVirtDrives[$d] Then
									ContinueLoop 2
								EndIf
							Next
							If $FixedDrives[$i]=StringLeft($any_drive, 2) Then
								$vhd_found = $vhd_found + 1
								$vhd_drive = StringLeft($any_drive, 2)
								; MsgBox(0, "VHD Drive Found", " VHD Drive = " & $vhd_drive, 0)
								ExitLoop
							EndIf
						Next
					EndIf
				EndIf
			EndIf
		Wend
		FileClose($file)
	EndIf

	$tmpdrive = $vhd_drive
	; MsgBox(0, "VHD Drive - OK",  " VHD Drive = " & $vhd_drive, 0)

EndFunc   ;==> _Mount_VHD
;===================================================================================================
Func _BCD_Inside_Entry()

	Local $file, $line, $pos1, $pos2, $guid

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /create /d " & '"' & $vhdfile_name_only & '"' & " /application osloader > " & $bcd_guid_outfile, @ScriptDir, @SW_HIDE)
	$file = FileOpen(@ScriptDir & "\" & $bcd_guid_outfile, 0)
	$line = FileReadLine($file)
	FileClose($file)
	$pos1 = StringInStr($line, "{")
	$pos2 = StringInStr($line, "}")
	If $pos2-$pos1=37 Then
		$guid = StringMid($line, $pos1, $pos2-$pos1+1)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " device boot", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " path \Windows\system32\" & $winload, $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " osdevice boot", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " systemroot \Windows", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " locale " & $DistLang, $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " nx OptIn", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /displayorder " & $guid & " /addfirst", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /default " & $guid, $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " detecthal on", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " bootmenupolicy legacy", $tmpdrive & "\", @SW_HIDE)
		; If $SysWOW64=1 Then
		If $SysWOW64=1 And StringRight($vhdfile_name, 4) = ".vhd" And $PartStyle = "MBR" Or $driver_flag = 3 Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " testsigning on", $tmpdrive & "\", @SW_HIDE)
		EndIf
		; EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} nointegritychecks on", $tmpdrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 1", $tmpdrive & "\", @SW_HIDE)
		; to get PE ProgressBar and Win 8 Boot Manager Menu displayed and waiting for User Selection
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /bootems {emssettings} ON", $tmpdrive & "\", @SW_HIDE)
	EndIf
EndFunc ;==>  _BCD_Inside_Entry
;===================================================================================================
Func _BCD_Inside_VHD()

	Local $val=0

	If FileExists(@WindowsDir & "\system32\bcdboot.exe") And Not FileExists($tmpdrive & "\Boot\BCD") Then
		; in win8 x64 OS then Win8x64 bcdboot with option /f ALL must be used, otherwise entry is not made
		If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
			_GUICtrlStatusBar_SetText($hStatus," UEFI x64 - Make Boot Manager Inside VHD - wait .... ", 0)
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $tmpdrive & " /f ALL", @ScriptDir, @SW_HIDE)
		Else
			_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager Inside VHD - wait .... ", 0)
			$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $tmpdrive, @ScriptDir, @SW_HIDE)
		EndIf
		Sleep(2000)
	EndIf
	If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($tmpdrive & "\Boot\BCD") Then
		_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager entry Inside VHD", 0)
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
		$store = $tmpdrive & "\Boot\BCD"
		$winload = "winload.exe"
		$bcd_guid_outfile = "makebt\bs_temp\bcd_boot_vhd.txt"

		_BCD_Inside_Entry()

		Sleep(2000)
		FileSetAttrib($tmpdrive & "\Boot", "-RSH", 1)
		FileSetAttrib($tmpdrive & "\bootmgr", "-RSH")
	EndIf
	If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($tmpdrive & "\efi\Microsoft\Boot\BCD") Then
		_GUICtrlStatusBar_SetText($hStatus," Make Boot Manager entry Inside VHD", 0)
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
		$store = $tmpdrive & "\efi\Microsoft\Boot\BCD"
		$winload = "winload.efi"
		$bcd_guid_outfile = "makebt\bs_temp\bcd_efi_vhd.txt"

		_BCD_Inside_Entry()

	EndIf
EndFunc ;==>  _BCD_Inside_VHD
;===================================================================================================
Func _BCD_BootDrive_VHD_Entry()

	Local $file, $line, $pos1, $pos2, $guid

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /create /d " & '"' & $vhdfile_name & '"' & " /application osloader > " & $bcd_guid_outfile, @ScriptDir, @SW_HIDE)
	$file = FileOpen(@ScriptDir & "\" & $bcd_guid_outfile, 0)
	$line = FileReadLine($file)
	FileClose($file)
	$pos1 = StringInStr($line, "{")
	$pos2 = StringInStr($line, "}")
	If $pos2-$pos1=37 Then
		$guid = StringMid($line, $pos1, $pos2-$pos1+1)
		If $PartStyle = "GPT" Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " device vhd=[" & $WinDrvDrive & "]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " osdevice vhd=[" & $WinDrvDrive & "]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
		Else
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " device vhd=[locate]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " osdevice vhd=[locate]\" & $vhdfile_name, $TargetDrive & "\", @SW_HIDE)
		EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " path \Windows\system32\" & $winload, $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " systemroot \Windows", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " locale " & $DistLang, $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " nx OptIn", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /displayorder " & $guid & " /addfirst", $TargetDrive & "\", @SW_HIDE)
		If $bcdboot_flag = 1 Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /default " & $guid, $TargetDrive & "\", @SW_HIDE)
		EndIf
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " detecthal on", $TargetDrive & "\", @SW_HIDE)
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set " & $guid & " bootmenupolicy legacy", $TargetDrive & "\", @SW_HIDE)
		; If $SysWOW64=1 Then
		If $SysWOW64=1 And StringRight($vhdfile_name, 4) = ".vhd" And $PartStyle = "MBR" Or $driver_flag = 3 Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " testsigning on", $TargetDrive & "\", @SW_HIDE)
		EndIf
		; EndIf
		If $OS_drive <> $TargetDrive Then
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set {bootmgr} nointegritychecks on", $TargetDrive & "\", @SW_HIDE)
		EndIf
		; to get PE ProgressBar and Win 8 Boot Manager Menu displayed and waiting for User Selection
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /bootems {emssettings} ON", $TargetDrive & "\", @SW_HIDE)
	EndIf

EndFunc ;==>  _BCD_BootDrive_VHD_Entry
;===================================================================================================
Func _ListUsbDrives()
	Local $linesplit[20], $file, $line, $pos1, $pos2

	Local $mptarget=0, $mpsystem=0, $count = 0

	If FileExists(@ScriptDir & "\makebt\wim_info\usblist.txt") Then
		FileCopy(@ScriptDir & "\makebt\wim_info\usblist.txt", @ScriptDir & "\makebt\wim_info\usblist_bak.txt", 1)
		FileDelete(@ScriptDir & "\makebt\wim_info\usblist.txt")
	EndIf

	RunWait(@ComSpec & " /c makebt\listusbdrives\ListUsbDrives.exe -a > makebt\wim_info\usblist.txt", @ScriptDir, @SW_HIDE)

	$inst_disk=""
	$inst_part=""
	$sys_disk=""
	$sys_part=""
	$usbfix=0
	$usbsys=0
	$file = FileOpen(@ScriptDir & "\makebt\wim_info\usblist.txt", 0)
	If $file <> -1 Then
		$count = 0
		$mptarget = 0
		$mpsystem = 0
		While 1
			$line = FileReadLine($file)
			If @error = -1 Then ExitLoop
			If $line <> "" Then
				$count = $count + 1
				$linesplit = StringSplit($line, "=")
				$linesplit[1] = StringStripWS($linesplit[1], 3)
				If $linesplit[1] = "MountPoint" And $linesplit[0] = 2 Then
					$linesplit[2] = StringStripWS($linesplit[2], 3)
					If $linesplit[2] = $TargetDrive & "\" Then
						$mptarget = 1
						; MsgBox(0, "TargetDrive Found - OK", " TargetDrive = " & $linesplit[2], 3)
					Else
						$mptarget = 0
					EndIf
					If $linesplit[2] = $WinDrvDrive & "\" Then
						$mpsystem = 1
						; MsgBox(0, "WinDrvDrive Found - OK", " WinDrvDrive = " & $linesplit[2], 3)
					Else
						$mpsystem = 0
					EndIf
				EndIf
				If $mptarget = 1 Then
					If $linesplit[1] = "Bus Type" And $linesplit[0] = 2 Then
						$linesplit[2] = StringStripWS($linesplit[2], 3)
						If $linesplit[2] = "USB" Then
							$usbfix = 1
						Else
							If $linesplit[2] = "ATA" Then
								$usbfix = 0
							EndIf
						EndIf
						;	MsgBox(0, "TargetDrive USB or HDD ?", " Bus Type = " & $linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Device Number" And $linesplit[0] = 2 Then
						$inst_disk = StringStripWS($linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Partition Number" Then
						$inst_part = StringLeft(StringStripWS($linesplit[2], 3), 1)
					EndIf
				EndIf
				If $mpsystem = 1 Then
					If $linesplit[1] = "Bus Type" And $linesplit[0] = 2 Then
						$linesplit[2] = StringStripWS($linesplit[2], 3)
						If $linesplit[2] = "USB" Then
							$usbsys = 1
						Else
							If $linesplit[2] = "ATA" Then
								$usbsys = 0
							EndIf
						EndIf
						;	MsgBox(0, "SystemDrive USB or HDD ?", " Bus Type = " & $linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Device Number" And $linesplit[0] = 2 Then
						$sys_disk = StringStripWS($linesplit[2], 3)
					EndIf
					If $linesplit[1] = "Partition Number" Then
						$sys_part = StringLeft(StringStripWS($linesplit[2], 3), 1)
					EndIf
				EndIf
			EndIf
		Wend
		FileClose($file)
	EndIf

EndFunc ;==>  _ListUsbDrives
;===================================================================================================
Func _Boot_Entries()
	Local $i=0, $d

	Local $file, $line, $pos1, $pos2

	Local $val=0, $valid = 0, $guid, $entry_image_file=""

	; Make Boot Manager entry and Grub4dos entries on TargetDrive

	; GUICtrlSetData($ProgressAll, 20)
	; _GUICtrlStatusBar_SetText($hStatus," List USB Drives - wait ...", 0)

	$DriveType=DriveGetType($TargetDrive)

	_ListUsbDrives()

	; Set Active TargetDrive only for USB Fixed Disk with MBR Partition - BIOS mode booting requires Active Drive
	If $usbfix And $DriveType <> "Removable" And $inst_disk <> "" And $inst_part <> "" And $PartStyle = "MBR" Then
		; MsgBox(0, "MBR Disk and Partition", " Disk = " & $inst_disk & @CRLF & " Part = " & $inst_part, 3)

		If FileExists(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt")

		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","select disk " & $inst_disk)
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","select partition " & $inst_part)
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","active")
		FileWriteLine(@ScriptDir & "\makebt\vhd_temp\set_usb_active.txt","exit")

		$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\set_usb_active.txt", @ScriptDir, @SW_HIDE)
	EndIf

	_WinLang()

	GUICtrlSetData($ProgressAll, 65)

	If $PartStyle = "MBR" Then
		If Not FileExists($TargetDrive & "\grldr") Then
			FileCopy(@ScriptDir & "\makebt\grldr", $TargetDrive & "\", 1)
			FileCopy(@ScriptDir & "\makebt\grub.exe", $TargetDrive & "\", 1)
		EndIf
		If Not FileExists($TargetDrive & "\menu.lst") Then
			FileCopy(@ScriptDir & "\makebt\menu.lst", $TargetDrive & "\", 1)
			FileCopy(@ScriptDir & "\makebt\menu_Linux.lst", $TargetDrive & "\", 1)
			FileCopy(@ScriptDir & "\makebt\menu_Win_ISO.lst", $TargetDrive & "\", 1)
		EndIf
	EndIf

	; Grub4dos Menu entry in case of SVBus driver and VHD - Grub4dos does Not work with VHDX
	If $driver_flag = 3 And StringRight($vhdfile_name, 4) = ".vhd" And $PartStyle = "MBR" Then
		_GUICtrlStatusBar_SetText($hStatus," Making Grub4dos Menu on Target Boot Drive " & $TargetDrive, 0)
		If $vhdfolder = "" Then
			$entry_image_file= $vhdfile_name
		Else
			$entry_image_file= $vhdfolder & "/" & $vhdfile_name_only
		EndIf

		If $DriveSysType="Removable" Or $usbsys Then
;~ 				If $FSvar_WinDrvDrive="NTFS" Then
;~ 					FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,0)/" & $entry_image_file & "] (hd0,0)/" & $entry_image_file & " - SVBus  FILEDISK - " & $PSize & " - map as (hd-1) for WIMBOOT")
;~ 					; FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "map (hd0,0)/" & $entry_image_file & " (hd-1)")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
;~ 				EndIf
			FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,0)/" & $entry_image_file & "] (hd0,0)/" & $entry_image_file & " - SVBus  RAMDISK  - " & $PSize & " - map as (hd-1) for WIMBOOT")
			FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem (hd0,0)/" & $entry_image_file & " (hd-1)")
			FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
			FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
;~ 				If $FSvar_WinDrvDrive="NTFS" Then
;~ 					FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,1)/" & $entry_image_file & "] (hd0,1)/" & $entry_image_file & " - SVBus  FILEDISK - " & $PSize & " - map as (hd-1) for WIMBOOT")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "map (hd0,1)/" & $entry_image_file & " (hd-1)")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
;~ 				EndIf
			FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "iftitle [if exist (hd0,1)/" & $entry_image_file & "] (hd0,1)/" & $entry_image_file & " - SVBus  RAMDISK  - " & $PSize & " - map as (hd-1) for WIMBOOT")
			; FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem (hd0,1)/" & $entry_image_file & " (hd-1)")
			FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
			FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
		Else
;~ 				If $FSvar_WinDrvDrive="NTFS" Then
;~ 					FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - SVBus  FILEDISK - " & $PSize & " - map as (hd) for WIMBOOT")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "map /" & $entry_image_file & " (hd)")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
;~ 					FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
;~ 				EndIf
			FileWriteLine($TargetDrive & "\menu.lst",@CRLF & "title " & $entry_image_file & " - SVBus  RAMDISK  - " & $PSize & " - map as (hd) for WIMBOOT")
			FileWriteLine($TargetDrive & "\menu.lst", "find --set-root --ignore-floppies /" & $entry_image_file)
			FileWriteLine($TargetDrive & "\menu.lst", "map --top --mem /" & $entry_image_file & " (hd)")
			FileWriteLine($TargetDrive & "\menu.lst", "map --hook")
			FileWriteLine($TargetDrive & "\menu.lst", "root (hd-1,0)")
			FileWriteLine($TargetDrive & "\menu.lst", "chainloader /bootmgr")
		EndIf
	EndIf

	Sleep(2000)

	; in Win 8/10 x64 OS then bcdboot with option /f ALL must be used, otherwise entry is not made
	; Create Windows BootManager Menu on USB if BCD Not exist
	If $DriveType="Removable" Or $usbfix Then
		If FileExists(@WindowsDir & "\system32\bcdboot.exe") And Not FileExists($TargetDrive & "\Boot\BCD") And $PartStyle = "MBR" Then
			$bcdboot_flag = 1
			If $PE_flag = 1 Then
				If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
					_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
				Else
					_GUICtrlStatusBar_SetText($hStatus," Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $TargetDrive, @ScriptDir, @SW_HIDE)
				EndIf
			Else
				If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
					_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive & " /f ALL", @ScriptDir, @SW_HIDE)
				Else
					_GUICtrlStatusBar_SetText($hStatus," Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
					$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive, @ScriptDir, @SW_HIDE)
				EndIf
			EndIf
			sleep(2000)
		EndIf
	Else
		If FileExists(@WindowsDir & "\system32\bcdedit.exe") And $PartStyle = "MBR" Then
			$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

			If Not FileExists($TargetDrive & "\Boot\BCD") And FileExists(@WindowsDir & "\Boot") Then
				DirCopy(@WindowsDir & "\Boot\PCAT", $TargetDrive & "\Boot", 1)
				DirCopy(@WindowsDir & "\Boot\Fonts", $TargetDrive & "\Boot\Fonts", 1)
				DirCopy(@WindowsDir & "\Boot\Resources", $TargetDrive & "\Boot\Resources", 1)
				If Not FileExists($TargetDrive & "\Boot\boot.sdi") And FileExists(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi") Then
					FileCopy(@WindowsDir & "\Boot\DVD\PCAT\boot.sdi", $TargetDrive & "\Boot\", 1)
				EndIf
				FileMove($TargetDrive & "\Boot\bootmgr", $TargetDrive & "\bootmgr", 1)
				FileMove($TargetDrive & "\Boot\bootnxt", $TargetDrive & "\BOOTNXT", 1)

				$store = $TargetDrive & "\Boot\BCD"
				RunWait(@ComSpec & " /c " & $bcdedit & " /createstore " & $store, $TargetDrive & "\", @SW_HIDE)
				sleep(1000)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {bootmgr}", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} description " & '"' & "Windows Boot Manager" & '"', $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} device boot", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} inherit {globalsettings}", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} timeout 20", $TargetDrive & "\", @SW_HIDE)
				RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /set {bootmgr} toolsdisplayorder {memdiag}", $TargetDrive & "\", @SW_HIDE)

				_mem_boot_menu()

				$bcdboot_flag = 1
			EndIf
		EndIf
	EndIf

	If FileExists(@WindowsDir & "\system32\bcdboot.exe") And Not FileExists($TargetDrive & "\efi\Microsoft\Boot\BCD") And $PartStyle = "GPT" Then
		$bcdboot_flag = 1
		If $PE_flag = 1 Then
			If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
				_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
				$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & $tmpdrive & $WinFol & " /l " & $DistLang & " /s " & $TargetDrive & " /f UEFI", @ScriptDir, @SW_HIDE)
			Else
				MsgBox(48,"WARNING - Win 8/10 x64 OS Needed", "EFI BCD Missing on Boot Drive " & $TargetDrive & @CRLF & @CRLF & "Win 8/10 x64 OS needed to Make EFI BCD", 5)
			EndIf
		Else
			If @OSVersion = "WIN_10" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_8" And @OSArch <> "X86" Then
				_GUICtrlStatusBar_SetText($hStatus," UEFI x64 OS - Add VHD to BCD on Boot Drive " & $TargetDrive, 0)
				$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\bcdboot.exe " & @WindowsDir & " /l " & $WinLang & " /s " & $TargetDrive & " /f UEFI", @ScriptDir, @SW_HIDE)
			Else
				MsgBox(48,"WARNING - Win 8/10 x64 OS Needed", "EFI BCD Missing on Boot Drive " & $TargetDrive & @CRLF & @CRLF & "Win 8/10 x64 OS needed to Make EFI BCD", 5)
			EndIf
		EndIf
		sleep(2000)
	EndIf

	If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($TargetDrive & "\Boot\BCD") Then
		_GUICtrlStatusBar_SetText($hStatus," Add VHD entry to BCD on Boot Drive " & $TargetDrive, 0)
		If Not FileExists($TargetDrive & "\Boot\bootvhd.dll") And FileExists(@WindowsDir & "\Boot\PCAT\bootvhd.dll") Then
			FileCopy(@WindowsDir & "\Boot\PCAT\bootvhd.dll", $TargetDrive & "\Boot\", 1)
		EndIf
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
		$store = $TargetDrive & "\Boot\BCD"
		$winload = "winload.exe"
		$bcd_guid_outfile = "makebt\bs_temp\bcd_boot_usb.txt"

		_BCD_BootDrive_VHD_Entry()

		sleep(2000)
		FileSetAttrib($TargetDrive & "\Boot", "-RSH", 1)
		FileSetAttrib($TargetDrive & "\bootmgr", "-RSH")
	EndIf
	If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($TargetDrive & "\efi\Microsoft\Boot\BCD") Then
		_GUICtrlStatusBar_SetText($hStatus," Add VHD entry to BCD on Boot Drive " & $TargetDrive, 0)
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"
		$store = $TargetDrive & "\efi\Microsoft\Boot\BCD"
		$winload = "winload.efi"
		$bcd_guid_outfile = "makebt\bs_temp\bcd_efi_usb.txt"

		_BCD_BootDrive_VHD_Entry()

	EndIf

	; Make Grub4dos entry in BootManager Menu
	If FileExists(@WindowsDir & "\system32\bcdedit.exe") And FileExists($TargetDrive & "\Boot\BCD") And Not FileExists($TargetDrive & "\grldr.mbr") Then
		; MsgBox(48, "Grub4dos Driver Info ", "  " & @CRLF & @CRLF & " Driver Flag = " & $driver_flag, 0)
		$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

		FileCopy(@ScriptDir & "\makebt\grldr.mbr", $TargetDrive & "\", 1)
		$store = $TargetDrive & "\Boot\BCD"
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /create /d " & '"' & "Grub4dos Menu" & '"' & " /application bootsector > makebt\bs_temp\bcd_g4d.txt", @ScriptDir, @SW_HIDE)
		$file = FileOpen(@ScriptDir & "\makebt\bs_temp\bcd_g4d.txt", 0)
		$line = FileReadLine($file)
		FileClose($file)
		$pos1 = StringInStr($line, "{")
		$pos2 = StringInStr($line, "}")
		If $pos2-$pos1=37 Then
			$guid = StringMid($line, $pos1, $pos2-$pos1+1)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " device boot", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /set " & $guid & " path \grldr.mbr", $TargetDrive & "\", @SW_HIDE)
			RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
			& $store & " /displayorder " & $guid & " /addfirst", $TargetDrive & "\", @SW_HIDE)
		EndIf
	EndIf
EndFunc ;==> _Boot_Entries
;===================================================================================================
Func _Make_Boot()

	Local $val=0, $linesplit[20], $file, $line, $AutoPlay_Data=""

	DisableMenus(1)

	If FileExists(@ScriptDir & "\makebt\bs_temp") Then DirRemove(@ScriptDir & "\makebt\bs_temp",1)
	If Not FileExists(@ScriptDir & "\makebt\bs_temp") Then DirCreate(@ScriptDir & "\makebt\bs_temp")

	SystemFileRedirect("On")

	If Not FileExists(@WindowsDir & "\system32\diskpart.exe") Then
		SystemFileRedirect("Off")
		MsgBox(48, "ERROR - DiskPart Not Found ", " system32\diskpart.exe needed to Mount VHD Drive " & @CRLF & @CRLF & " Boot with Windows 7/8/10 or 10 PE ")
		DisableMenus(0)
		Return
	EndIf

	If FileExists(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt") Then FileDelete(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt")

	RunWait(@ComSpec & " /c reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay" & " > makebt\vhd_temp\Reg_DisableAutoPlay.txt", @ScriptDir, @SW_HIDE)

	$file = FileOpen(@ScriptDir & "\makebt\vhd_temp\Reg_DisableAutoPlay.txt", 0)
	While 1
		$line = FileReadLine($file)
		If @error = -1 Then ExitLoop
		If $line <> "" Then
			$line = StringStripWS($line, 7)
			$linesplit = StringSplit($line, " ")
			; _ArrayDisplay($linesplit)
			If $linesplit[1] = "DisableAutoplay" Then
				$AutoPlay_Data = $linesplit[3]
			EndIf
		EndIf
	Wend
	FileClose($file)

	; MsgBox(48, "Info AutoPlay ", "  " & @CRLF & @CRLF & " AutoPlay_Data = " & $AutoPlay_Data, 0)

	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 1 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Disabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 1 ", 0)
	EndIf

	_Mount_VHD()

	; In case _Mount_VHD failure return
	If $tmpdrive = "" Then
		; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
		If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
			RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
			; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
		EndIf
		SystemFileRedirect("Off")
		MsgBox(48, " STOP - VHD Drive Not Found", " Attach / Detach VHD - DiskPart Error " & @CRLF & @CRLF & "Please Unmount VHD Drive of " & $vhdfile, 0)
		GUICtrlSetData($ProgressAll, 0)
		_GUICtrlStatusBar_SetText($hStatus," Select WIM File for APPLY Or Select Exit ", 0)
		DisableMenus(0)
		Return
	EndIf

	If FileExists($tmpdrive & $WinFol & "\system32\drivers\svbusx86.sys") Or FileExists($tmpdrive & $WinFol & "\system32\drivers\svbusx64.sys") Then
		If StringRight($vhdfile_name, 4) = ".vhd"  Then
			$driver_flag = 3
		Else
			$driver_flag = 0
		EndIf
;~ 	ElseIf FileExists($tmpdrive & $WinFol & "\system32\drivers\wvblk32.sys") Then
;~ 		$driver_flag = 1
;~ 	ElseIf FileExists($tmpdrive & $WinFol & "\system32\drivers\firadisk.sys") Then
;~ 		$driver_flag = 2
	Else
		$driver_flag = 0
	EndIf

	If FileExists($tmpdrive & $WinFol & "\system32\drivers\vhdmp.sys") Then
		$vhdmp=1
	EndIf

	If FileExists($tmpdrive & $WinFol & "\SysWOW64") Then
		$SysWOW64=1
	EndIf

	If FileExists($tmpdrive & "\Windows\system32\winload.exe") Then
		$winload_flag = 1
	EndIf

	_DetectLang()

	GUICtrlSetData($ProgressAll, 45)

	If $winload_flag = 1 Then
		_BCD_Inside_VHD()
		_Boot_Entries()
	EndIf

	; Reset Disable AutoPlay to Original value 0 = Enable AutoPlay
	If $AutoPlay_Data = "0x0" Or $AutoPlay_Data = "" Then
		RunWait(@ComSpec & " /c reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /v DisableAutoplay /t REG_DWORD /d 0 /f", @ScriptDir, @SW_HIDE)
		; MsgBox(48, "Info AutoPlay Enabled ", "  " & @CRLF & @CRLF & " Disable AutoPlay_Data = 0 ", 0)
	EndIf

	GUICtrlSetData($ProgressAll, 50)

	_GUICtrlStatusBar_SetText($hStatus," Detach VHD " & $vhdfile_name, 0)
	GUICtrlSetData($ProgressAll, 70)
	$val = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\diskpart.exe /s  makebt\vhd_temp\detach_vhd.txt", @ScriptDir, @SW_HIDE)
	If $val <> 0 Then
		MsgBox(48, " Error DiskPart", " Detach Dest VHD - DiskPart Error = " & $val, 0)
	EndIf

	SystemFileRedirect("Off")

	sleep(2000)
	GUICtrlSetData($ProgressAll, 100)
	_GUICtrlStatusBar_SetText($hStatus," End of Program ", 0)

	If $winload_flag = 1 Then
		MsgBox(64, " END OF PROGRAM - OK ", " End of Program  - OK " & @CRLF _
		& @CRLF & "Boot files created on Boot Drive " & $TargetDrive & @CRLF _
		& @CRLF & $vhdfile_name & " is on System Drive " & $WinDrvDrive)
		Exit
	Else
		MsgBox(48, " STOP - VHD Invalid", " VHD Invalid - winload.exe Missing " & @CRLF & @CRLF & " Invalid VHD " & $vhdfile, 0)
		_GUICtrlStatusBar_SetText($hStatus," Select Exit Or Select VHD ", 0)
		GUICtrlSetData($ProgressAll, 0)
		DisableMenus(0)
		Return
	EndIf
EndFunc ;==> _Make_Boot
;===================================================================================================
Func _mem_boot_menu()

	$bcdedit = @WindowsDir & "\system32\bcdedit.exe"

	RunWait(@ComSpec & " /c " & $bcdedit & " /store " & $store & " /create {memdiag}", @ScriptDir, @SW_HIDE)
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} DESCRIPTION " & '"' & "Windows Memory Diagnostic" & '"', $TargetDrive & "\", @SW_HIDE)
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} device boot", $TargetDrive & "\", @SW_HIDE)
	If $store = $TargetDrive & "\Boot\BCD" Then
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set {memdiag} path \Boot\memtest.exe", $TargetDrive & "\", @SW_HIDE)
	Else
		RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
		& $store & " /set {memdiag} path \EFI\Microsoft\Boot\memtest.efi", $TargetDrive & "\", @SW_HIDE)
	EndIf
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} inherit {globalsettings}", $TargetDrive & "\", @SW_HIDE)
	RunWait(@ComSpec & " /c " & $bcdedit & " /store " _
	& $store & " /set {memdiag} badmemoryaccess Yes", $TargetDrive & "\", @SW_HIDE)

EndFunc   ;==> _win_boot_menu
;===================================================================================================
Func DisableMenus($endis)
	If $endis = 0 Then
		$endis = $GUI_ENABLE
	Else
		$endis = $GUI_DISABLE
	EndIf

	GUICtrlSetState($EXIT, $endis)

  	If $wimfile <> "" Then
		GUICtrlSetState($WIM_INFO, $endis)
	Else
		GUICtrlSetState($WIM_INFO, $GUI_DISABLE)
	EndIf
  	If $vhdfile <> "" And FileExists($vhdfile) Then
		GUICtrlSetState($VHD_INFO, $endis)
	Else
		GUICtrlSetState($VHD_INFO, $GUI_DISABLE)
	EndIf

 	If $wimfile <> "" And $vhdfile <> "" And FileExists($vhdfile) And $WIM_Path <> "" Then
		GUICtrlSetState($Update_WIMBOOT, $endis)
	Else
		GUICtrlSetState($Update_WIMBOOT, $GUI_DISABLE)
	EndIf

 	If $wimfile = "" And $vhdfile <> "" And $WIM_Path <> "" And FileExists($vhdfile) Then
		GUICtrlSetState($LZX, $endis)
	Else
		GUICtrlSetState($LZX, $GUI_UNCHECKED + $GUI_DISABLE)
	EndIf

	If $wimfile <> "" Or $vhdfile <> "" Then
		GUICtrlSetState($WinDrvSel, $GUI_DISABLE)
	Else
		GUICtrlSetState($WinDrvSel, $endis)
	EndIf
	GUICtrlSetState($WinDrv, $endis)

	If $WinDrvDrive = "" Then
		GUICtrlSetState($WIM_FileSelect, $GUI_DISABLE)
		GUICtrlSetState($WIM_File, $GUI_DISABLE)
		GUICtrlSetState($VHD_FileSelect, $GUI_DISABLE)
		GUICtrlSetState($VHD_File, $GUI_DISABLE)
 		GUICtrlSetState($ComboSize, $GUI_DISABLE)
		GUICtrlSetState($VHD_TYPE, $GUI_DISABLE)
		GUICtrlSetState($VHDX, $GUI_DISABLE)
		GUICtrlSetState($DISK_TYPE, $GUI_DISABLE)
		GUICtrlSetState($TargetSel, $GUI_DISABLE)
		GUICtrlSetState($Target, $GUI_DISABLE)
		GUICtrlSetState($LZX, $GUI_DISABLE)
	Else
		GUICtrlSetState($WIM_FileSelect, $endis)
		GUICtrlSetState($WIM_File, $endis)
		GUICtrlSetState($ComboSize, $endis)
		GUICtrlSetState($VHD_TYPE, $endis)
		If @OSVersion = "WIN_7" Then
			GUICtrlSetState($VHDX, $GUI_DISABLE)
		Else
			GUICtrlSetState($VHDX, $endis)
		EndIf
		GUICtrlSetState($DISK_TYPE, $endis)
		GUICtrlSetState($VHD_FileSelect, $endis)
		GUICtrlSetState($VHD_File, $endis)
		GUICtrlSetState($TargetSel, $endis)
		GUICtrlSetState($Target, $endis)
	EndIf

	GUICtrlSetState($WIMBOOT, $GUI_DISABLE)
	GUICtrlSetState($Make_Boot, $GUI_DISABLE)
	GUICtrlSetState($APPLY, $GUI_DISABLE)
	GUICtrlSetState($CAPTURE, $GUI_DISABLE)
EndFunc ;==>DisableMenus
;===================================================================================================
Func _DetectLang()
	If FileExists($tmpdrive & "\Windows\System32\en-US\ieframe.dll.mui") Then $DistLang = "en-US"
	If FileExists($tmpdrive & "\Windows\System32\ar-SA\ieframe.dll.mui") Then $DistLang = "ar-SA"
	If FileExists($tmpdrive & "\Windows\System32\bg-BG\ieframe.dll.mui") Then $DistLang = "bg-BG"
	If FileExists($tmpdrive & "\Windows\System32\cs-CZ\ieframe.dll.mui") Then $DistLang = "cs-CZ"
	If FileExists($tmpdrive & "\Windows\System32\da-DK\ieframe.dll.mui") Then $DistLang = "da-DK"
	If FileExists($tmpdrive & "\Windows\System32\de-DE\ieframe.dll.mui") Then $DistLang = "de-DE"
	If FileExists($tmpdrive & "\Windows\System32\el-GR\ieframe.dll.mui") Then $DistLang = "el-GR"
	If FileExists($tmpdrive & "\Windows\System32\es-ES\ieframe.dll.mui") Then $DistLang = "es-ES"
	If FileExists($tmpdrive & "\Windows\System32\es-MX\ieframe.dll.mui") Then $DistLang = "es-MX"
	If FileExists($tmpdrive & "\Windows\System32\et-EE\ieframe.dll.mui") Then $DistLang = "et-EE"
	If FileExists($tmpdrive & "\Windows\System32\fi-FI\ieframe.dll.mui") Then $DistLang = "fi-FI"
	If FileExists($tmpdrive & "\Windows\System32\fr-FR\ieframe.dll.mui") Then $DistLang = "fr-FR"
	If FileExists($tmpdrive & "\Windows\System32\he-IL\ieframe.dll.mui") Then $DistLang = "he-IL"
	If FileExists($tmpdrive & "\Windows\System32\hr-HR\ieframe.dll.mui") Then $DistLang = "hr-HR"
	If FileExists($tmpdrive & "\Windows\System32\hu-HU\ieframe.dll.mui") Then $DistLang = "hu-HU"
	If FileExists($tmpdrive & "\Windows\System32\it-IT\ieframe.dll.mui") Then $DistLang = "it-IT"
	If FileExists($tmpdrive & "\Windows\System32\ja-JP\ieframe.dll.mui") Then $DistLang = "ja-JP"
	If FileExists($tmpdrive & "\Windows\System32\ko-KR\ieframe.dll.mui") Then $DistLang = "ko-KR"
	If FileExists($tmpdrive & "\Windows\System32\lt-LT\ieframe.dll.mui") Then $DistLang = "lt-LT"
	If FileExists($tmpdrive & "\Windows\System32\lv-LV\ieframe.dll.mui") Then $DistLang = "lv-LV"
	If FileExists($tmpdrive & "\Windows\System32\nb-NO\ieframe.dll.mui") Then $DistLang = "nb-NO"
	If FileExists($tmpdrive & "\Windows\System32\nl-NL\ieframe.dll.mui") Then $DistLang = "nl-NL"
	If FileExists($tmpdrive & "\Windows\System32\pl-PL\ieframe.dll.mui") Then $DistLang = "pl-PL"
	If FileExists($tmpdrive & "\Windows\System32\pt-BR\ieframe.dll.mui") Then $DistLang = "pt-BR"
	If FileExists($tmpdrive & "\Windows\System32\pt-PT\ieframe.dll.mui") Then $DistLang = "pt-PT"
	If FileExists($tmpdrive & "\Windows\System32\ro-RO\ieframe.dll.mui") Then $DistLang = "ro-RO"
	If FileExists($tmpdrive & "\Windows\System32\ru-RU\ieframe.dll.mui") Then $DistLang = "ru-RU"
	If FileExists($tmpdrive & "\Windows\System32\sk-SK\ieframe.dll.mui") Then $DistLang = "sk-SK"
	If FileExists($tmpdrive & "\Windows\System32\sl-SI\ieframe.dll.mui") Then $DistLang = "sl-SI"
	If FileExists($tmpdrive & "\Windows\System32\sr-Latn-CS\ieframe.dll.mui") Then $DistLang = "sr-Latn-CS"
	If FileExists($tmpdrive & "\Windows\System32\sv-SE\ieframe.dll.mui") Then $DistLang = "sv-SE"
	If FileExists($tmpdrive & "\Windows\System32\th-TH\ieframe.dll.mui") Then $DistLang = "th-TH"
	If FileExists($tmpdrive & "\Windows\System32\tr-TR\ieframe.dll.mui") Then $DistLang = "tr-TR"
	If FileExists($tmpdrive & "\Windows\System32\uk-UA\ieframe.dll.mui") Then $DistLang = "uk-UA"
	If FileExists($tmpdrive & "\Windows\System32\zh-CN\ieframe.dll.mui") Then $DistLang = "zh-CN"
	If FileExists($tmpdrive & "\Windows\System32\zh-HK\ieframe.dll.mui") Then $DistLang = "zh-HK"
	If FileExists($tmpdrive & "\Windows\System32\zh-TW\ieframe.dll.mui") Then $DistLang = "zh-TW"
EndFunc   ;==> _DetectLang
;===================================================================================================
Func _WinLang()
	If FileExists(@WindowsDir & "\System32\en-US\ieframe.dll.mui") Then $WinLang = "en-US"
	If FileExists(@WindowsDir & "\System32\ar-SA\ieframe.dll.mui") Then $WinLang = "ar-SA"
	If FileExists(@WindowsDir & "\System32\bg-BG\ieframe.dll.mui") Then $WinLang = "bg-BG"
	If FileExists(@WindowsDir & "\System32\cs-CZ\ieframe.dll.mui") Then $WinLang = "cs-CZ"
	If FileExists(@WindowsDir & "\System32\da-DK\ieframe.dll.mui") Then $WinLang = "da-DK"
	If FileExists(@WindowsDir & "\System32\de-DE\ieframe.dll.mui") Then $WinLang = "de-DE"
	If FileExists(@WindowsDir & "\System32\el-GR\ieframe.dll.mui") Then $WinLang = "el-GR"
	If FileExists(@WindowsDir & "\System32\es-ES\ieframe.dll.mui") Then $WinLang = "es-ES"
	If FileExists(@WindowsDir & "\System32\es-MX\ieframe.dll.mui") Then $WinLang = "es-MX"
	If FileExists(@WindowsDir & "\System32\et-EE\ieframe.dll.mui") Then $WinLang = "et-EE"
	If FileExists(@WindowsDir & "\System32\fi-FI\ieframe.dll.mui") Then $WinLang = "fi-FI"
	If FileExists(@WindowsDir & "\System32\fr-FR\ieframe.dll.mui") Then $WinLang = "fr-FR"
	If FileExists(@WindowsDir & "\System32\he-IL\ieframe.dll.mui") Then $WinLang = "he-IL"
	If FileExists(@WindowsDir & "\System32\hr-HR\ieframe.dll.mui") Then $WinLang = "hr-HR"
	If FileExists(@WindowsDir & "\System32\hu-HU\ieframe.dll.mui") Then $WinLang = "hu-HU"
	If FileExists(@WindowsDir & "\System32\it-IT\ieframe.dll.mui") Then $WinLang = "it-IT"
	If FileExists(@WindowsDir & "\System32\ja-JP\ieframe.dll.mui") Then $WinLang = "ja-JP"
	If FileExists(@WindowsDir & "\System32\ko-KR\ieframe.dll.mui") Then $WinLang = "ko-KR"
	If FileExists(@WindowsDir & "\System32\lt-LT\ieframe.dll.mui") Then $WinLang = "lt-LT"
	If FileExists(@WindowsDir & "\System32\lv-LV\ieframe.dll.mui") Then $WinLang = "lv-LV"
	If FileExists(@WindowsDir & "\System32\nb-NO\ieframe.dll.mui") Then $WinLang = "nb-NO"
	If FileExists(@WindowsDir & "\System32\nl-NL\ieframe.dll.mui") Then $WinLang = "nl-NL"
	If FileExists(@WindowsDir & "\System32\pl-PL\ieframe.dll.mui") Then $WinLang = "pl-PL"
	If FileExists(@WindowsDir & "\System32\pt-BR\ieframe.dll.mui") Then $WinLang = "pt-BR"
	If FileExists(@WindowsDir & "\System32\pt-PT\ieframe.dll.mui") Then $WinLang = "pt-PT"
	If FileExists(@WindowsDir & "\System32\ro-RO\ieframe.dll.mui") Then $WinLang = "ro-RO"
	If FileExists(@WindowsDir & "\System32\ru-RU\ieframe.dll.mui") Then $WinLang = "ru-RU"
	If FileExists(@WindowsDir & "\System32\sk-SK\ieframe.dll.mui") Then $WinLang = "sk-SK"
	If FileExists(@WindowsDir & "\System32\sl-SI\ieframe.dll.mui") Then $WinLang = "sl-SI"
	If FileExists(@WindowsDir & "\System32\sr-Latn-CS\ieframe.dll.mui") Then $WinLang = "sr-Latn-CS"
	If FileExists(@WindowsDir & "\System32\sv-SE\ieframe.dll.mui") Then $WinLang = "sv-SE"
	If FileExists(@WindowsDir & "\System32\th-TH\ieframe.dll.mui") Then $WinLang = "th-TH"
	If FileExists(@WindowsDir & "\System32\tr-TR\ieframe.dll.mui") Then $WinLang = "tr-TR"
	If FileExists(@WindowsDir & "\System32\uk-UA\ieframe.dll.mui") Then $WinLang = "uk-UA"
	If FileExists(@WindowsDir & "\System32\zh-CN\ieframe.dll.mui") Then $WinLang = "zh-CN"
	If FileExists(@WindowsDir & "\System32\zh-HK\ieframe.dll.mui") Then $WinLang = "zh-HK"
	If FileExists(@WindowsDir & "\System32\zh-TW\ieframe.dll.mui") Then $WinLang = "zh-TW"
EndFunc   ;==> _WinLang
;===================================================================================================
