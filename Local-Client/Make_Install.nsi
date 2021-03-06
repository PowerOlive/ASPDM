!define PRODUCT_NAME "ASPDM"
!define PRODUCT_NAME_LONG "ASPDM : Package Manager"
!define PRODUCT_VERSION "1.0.0.0"
!define PRODUCT_COMPANY "The ASPDM group" ;The ahkscript.org Group
!define PRODUCT_PUBLISHER "The ASPDM group"
!define PRODUCT_COPYRIGHT "(c) 2014 The ASPDM group"
!define PRODUCT_WEB_SITE "http://aspdm.ahkscript.org"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\Package_Lister.ahk"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

SetCompressor /SOLID LZMA

!include "MUI2.nsh"
!include "StrFunc.nsh"
!include "FileFunc.nsh"
${StrRep} ;StringReplace Function

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "Installer_resources\ahk_install.ico"
!define MUI_UNICON "Installer_resources\ahk_remove.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "Installer_resources\ahk_banner.bmp"

InstallDir "$PROGRAMFILES\AutoHotkey\${PRODUCT_NAME}"
var /GLOBAL h_ahk_path
var /GLOBAL h_ahk_ver

Function .onInit
	SetOutPath $TEMP

	; Install to the correct directory on 32 bit or 64 bit machines
	IfFileExists $WINDIR\SYSWOW64\*.* Is64bit Is32bit
	Is32bit:
		SetRegView 32
		StrCpy $INSTDIR "$PROGRAMFILES32\AutoHotkey\${PRODUCT_NAME}"
		StrCpy $h_ahk_path "$PROGRAMFILES32\AutoHotkey\AutoHotkey.exe"
		GOTO End32Bitvs64BitCheck
	Is64bit:
		SetRegView 64
		StrCpy $INSTDIR "$PROGRAMFILES64\AutoHotkey\${PRODUCT_NAME}"
		StrCpy $h_ahk_path "$PROGRAMFILES64\AutoHotkey\AutoHotkey.exe"
	End32Bitvs64BitCheck:

	; Check to see if already installed
	ReadRegStr $R0 HKLM \
	"Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
	"UninstallString"
	StrCmp $R0 "" done

	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
	"${PRODUCT_NAME} is already installed. $\n$\nClick `OK` to remove the \
	previous version or `Cancel` to cancel this upgrade." \
	IDOK uninst
	Abort

	;Run the uninstaller
	uninst:
		ClearErrors
		ExecWait '$R0 _?=$INSTDIR' ;Do not copy the uninstaller to a temp file
		ReadRegStr $R0 HKLM \
		"Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
		"UninstallString"
		StrCmp $R0 "" done
		Delete /REBOOTOK '$R0'
	done:
	; -----NotInstalled:

	; Check if AutoHotkey is Installed
	ReadRegStr $1 HKLM "SOFTWARE\AutoHotkey" "InstallDir"
	${StrRep} $1 '$1' '"' "" ;remove all quotes
	IfFileExists '$1\AutoHotkey.exe' AHK_Installed_A AHK_NotInstalled_firstcheck
	AHK_NotInstalled_firstcheck:
		ReadRegStr $1 HKCR "AutoHotkeyScript\Shell\Open\Command" ""
		${StrRep} $1 '$1' ' "%1" %*' "" ;extract path
		${StrRep} $1 '$1' '"' "" ;remove all quotes
		IfFileExists '$1\AutoHotkey.exe' AHK_Installed_A AHK_NotInstalled_secondcheck
		AHK_NotInstalled_secondcheck:
			IfFileExists $h_ahk_path AHK_Installed AHK_NotInstalled
			AHK_NotInstalled:
				MessageBox MB_ICONEXCLAMATION|MB_YESNO "AutoHotkey seems to be not installed.$\nContinue Installation?" IDYES AHK_no_version
				MessageBox MB_OK|MB_ICONINFORMATION "Installation aborted. The installer will now exit."
				Abort
	AHK_Installed_A:
		StrCpy $h_ahk_path '$1\AutoHotkey.exe'
	AHK_Installed:
		; Get the installed AutoHotkey Version
		StrCmp $h_ahk_path "" AHK_no_version
		${GetFileVersion} '$h_ahk_path' $h_ahk_ver
		Goto AHK_min_version
	AHK_no_version:
		StrCpy $h_ahk_ver "NOT INSTALLED"
		goto AHK_Check_END
	AHK_min_version: ;1.1.13.01 but exclude 1.2+ and 2+
		GetDLLVersion "$h_ahk_path" $R0 $R1
		IntOp $R2 $R0 >> 16
		IntOp $R2 $R2 & 0x0000FFFF ; $R2 now contains major version
		IntOp $R3 $R0 & 0x0000FFFF ; $R3 now contains minor version
		IntOp $R4 $R1 >> 16
		IntOp $R4 $R4 & 0x0000FFFF ; $R4 now contains release
		IntOp $R5 $R1 & 0x0000FFFF ; $R5 now contains build
		IntCmp $R2 1 0 0 AHK_min_v_err
		IntCmp $R3 1 0 AHK_min_v_err AHK_min_v_err
		IntCmp $R4 13 AHK_Check_END AHK_min_v_err AHK_Check_END
		;IntCmp $R5 1 0 0 AHK_min_v_err
		MessageBox MB_OK "$R2.$R3.$R4"
		AHK_min_v_err:
		MessageBox MB_ICONEXCLAMATION|MB_YESNO "Your AutoHotkey version ($h_ahk_ver) is not supported.$\nIt is strongly recommended for the latest version of AutoHotkey v1.1 to be installed. Please note that versions 2+ are not supported by this version of ${PRODUCT_NAME}.$\n$\nContinue Installation?" IDYES AHK_Check_END
		MessageBox MB_OK|MB_ICONINFORMATION "Installation aborted. The installer will now exit."
		Abort
	AHK_Check_END:
FunctionEnd

Function LaunchASPDM
	ExecShell "" "$INSTDIR\Package_Lister.ahk"
FunctionEnd

BrandingText "${PRODUCT_NAME_LONG} v${PRODUCT_VERSION}"
; Welcome page
!define MUI_PAGE_CUSTOMFUNCTION_SHOW WelcomeShowVersion
!insertmacro MUI_PAGE_WELCOME
Function WelcomeShowVersion ;see http://stackoverflow.com/a/5319228/883015
	${NSD_CreateLabel} 120u 165u 50% 12u "Setup for ${PRODUCT_NAME} Version: ${PRODUCT_VERSION}"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"
	${NSD_CreateLabel} 120u 174u 50% 12u "Detected AutoHotkey Version: $h_ahk_ver"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"
FunctionEnd

; License page
!insertmacro MUI_PAGE_LICENSE "Installer_resources\license.txt"
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${PRODUCT_NAME_LONG}"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchASPDM"
!define MUI_FINISHPAGE_LINK "Open the ASPDM Website"
!define MUI_FINISHPAGE_LINK_LOCATION "${PRODUCT_WEB_SITE}"
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; Reserve files
;!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

; MUI end ------

Name "${PRODUCT_NAME_LONG}"
OutFile "ASPDM_Install-v${PRODUCT_VERSION}.exe"

VIProductVersion "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${PRODUCT_NAME_LONG}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${PRODUCT_COMPANY}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" "${PRODUCT_NAME} is a trademark of ${PRODUCT_COMPANY}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "${PRODUCT_COPYRIGHT} (${PRODUCT_WEB_SITE})"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${PRODUCT_NAME_LONG}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "OriginalFilename" "ASPDM_Install-v${PRODUCT_VERSION}.exe"

InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

Section "MainSection" SEC01
	SetOutPath "$INSTDIR"
	SetOverwrite ifnewer
	File "Package_Lister.ahk"
	File "Package_Builder.ahk"
	File "Package_Installer.ahk"
	File "Package_Remover.ahk"
	File "rHandler.exe"

	SetOutPath "$INSTDIR\Res"
	File /r Res\*.*

	SetOutPath "$INSTDIR\Lib"
	File /r Lib\*.*

	DetailPrint "Associating .ahkp files..."
		WriteRegStr HKCR ".ahkp" "" "ahkp.package"
		WriteRegStr HKCR "ahkp.package" "" "ahkp Package"
		WriteRegStr HKCR "ahkp.package\DefaultIcon" "" "$INSTDIR\Res\ahk.ico"
		WriteRegStr HKCR "ahkp.package\shell\open\command" "" '"$INSTDIR\rHandler.exe" "%1"'

	DetailPrint "Creating ASPDM:// URI Scheme..."
		WriteRegStr HKCR "ASPDM" "URL Protocol" ""
		WriteRegStr HKCR "ASPDM" "" "URL:ASPDM Protocol"
		WriteRegStr HKCR "ASPDM\DefaultIcon" "" "$INSTDIR\res\ahk.ico"
		WriteRegStr HKCR "ASPDM\shell\open\command" "" '"$INSTDIR\rHandler.exe" "%1"'
		WriteRegStr HKCU "Software\Classes\aspdm" "URL Protocol" ""
		WriteRegStr HKCU "Software\Classes\aspdm" "" "URL:AHK Script Protocol"
		WriteRegStr HKCU "Software\Classes\aspdm\DefaultIcon" "" "$INSTDIR\res\ahk.ico"
		WriteRegStr HKCU "Software\Classes\aspdm\shell\open\command" "" '"$INSTDIR\rHandler.exe" "%1"'

	DetailPrint "Creating shortcuts..."
	SetShellVarContext all
	SetOutPath "$INSTDIR"
	CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
	CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\Package_Lister.ahk" "" "$INSTDIR\Res\ahk.ico"
	CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Package Builder.lnk" "$INSTDIR\Package_Builder.ahk" "" "$INSTDIR\Res\ahk.ico"
	CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\Package_Lister.ahk" "" "$INSTDIR\Res\ahk.ico"
	CreateShortCut "$DESKTOP\${PRODUCT_NAME} Package Builder.lnk" "$INSTDIR\Package_Builder.ahk" "" "$INSTDIR\Res\ahk.ico"
	SetAutoClose false
SectionEnd

Section -AdditionalIcons
	SetOutPath $INSTDIR
	WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
	CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
	CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
	WriteUninstaller "$INSTDIR\uninst.exe"
	WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\Package_Lister.ahk"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME_LONG}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "QuietUninstallString" "$INSTDIR\uninst.exe /S"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\Res\ahk.ico"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd


Function un.onUninstSuccess
	HideWindow
	MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) v${PRODUCT_VERSION} was successfully removed from your computer."
FunctionEnd

Function un.onInit
	MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) v${PRODUCT_VERSION} and all of its components?" IDYES +2
	Abort
FunctionEnd

Section Uninstall
	Delete "$INSTDIR\uninst.exe"
	SetShellVarContext all

	Delete "$INSTDIR\Package_Lister.ahk"
	Delete "$INSTDIR\Package_Builder.ahk"
	Delete "$INSTDIR\Package_Installer.ahk"
	Delete "$INSTDIR\Package_Remover.ahk"
	Delete "$INSTDIR\rHandler.exe"
	RMDir /r "$INSTDIR\Res"
	RMDir /r "$INSTDIR\Lib"

	MessageBox MB_ICONEXCLAMATION|MB_YESNO "Keep ASPDM local repository and settings?" IDYES UNINST_KEEP_REPO
	DetailPrint "Removing ASPDM local repository and settings..."
	RMDir /r "$APPDATA\${PRODUCT_NAME}"
	UNINST_KEEP_REPO:

	DetailPrint "Removing .ahkp file association..."
	DeleteRegKey HKCR ".ahkp"
	DeleteRegKey HKCR "ahkp.package"
	DetailPrint "Removing ASPDM:// URI Scheme..."
	DeleteRegKey HKCR "ASPDM"
	DeleteRegKey HKCU "Software\Classes\aspdm"

	DetailPrint "Removing shortcuts..."
	Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk"
	Delete "$SMPROGRAMS\${PRODUCT_NAME}\Website.lnk"
	Delete "$INSTDIR\${PRODUCT_NAME}.url"
	Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
	Delete "$DESKTOP\${PRODUCT_NAME} Package Builder.lnk"
	Delete "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk"
	Delete "$SMPROGRAMS\${PRODUCT_NAME}\Package Builder.lnk"

	RMDir "$SMPROGRAMS\${PRODUCT_NAME}"
	;RMDir /r "$INSTDIR"

	DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
	DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
	SetAutoClose false
SectionEnd
