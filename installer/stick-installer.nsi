; Stick.ai Windows installer - one-click install like E6 / FlightScope.
; Installs to the user's local Programs folder (no admin/UAC prompt), creates a
; desktop shortcut + Start Menu entries, registers an uninstaller, and offers to
; launch the app when finished. Built on a Windows runner:
;   makensis /DSRC=<staging-dir> /DOUTFILE=<out.exe> stick-installer.nsi

!include "MUI2.nsh"

!define APPNAME "Stick.ai"
!define COMPANY "Stick"
!define VERSION "1.0.0"

Name "${APPNAME}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Programs\Stick.ai"
InstallDirRegKey HKCU "Software\Stick.ai" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\Stick.ai.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Stick.ai now"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  ; Kill any already-running copy FIRST. Windows refuses to let File /r overwrite a locked
  ; .exe — if the old Stick.ai.exe is still open, the copy below silently skips just that one
  ; file while every other file updates fine, so Setup reports success but the app itself,
  ; and the version it displays, never actually changes. This is what makes "reinstall" look
  ; like it does nothing: everything except the one file that matters gets replaced.
  ExecWait 'taskkill /F /IM "Stick.ai.exe"'
  Sleep 500

  SetOutPath "$INSTDIR"
  File /r "${SRC}\*"

  CreateShortcut "$DESKTOP\Stick.ai.lnk" "$INSTDIR\Stick.ai.exe" "" "$INSTDIR\Stick.ai.exe" 0
  CreateDirectory "$SMPROGRAMS\Stick.ai"
  CreateShortcut "$SMPROGRAMS\Stick.ai\Stick.ai.lnk" "$INSTDIR\Stick.ai.exe" "" "$INSTDIR\Stick.ai.exe" 0
  CreateShortcut "$SMPROGRAMS\Stick.ai\Stick.ai Demo.lnk" "$INSTDIR\Stick.ai.exe" "-demo" "$INSTDIR\Stick.ai.exe" 0
  CreateShortcut "$SMPROGRAMS\Stick.ai\Uninstall Stick.ai.lnk" "$INSTDIR\Uninstall.exe"

  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Stick.ai" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai" "DisplayName" "Stick.ai"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai" "Publisher" "${COMPANY}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai" "DisplayIcon" "$INSTDIR\Stick.ai.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai" "NoRepair" 1

  ; In-app auto-update runs this installer SILENTLY (/S). In that case there's no finish page,
  ; so relaunch the app ourselves. A normal (interactive) install skips this — the finish page's
  ; "Launch Stick.ai now" checkbox handles it, and we must not double-launch.
  IfSilent 0 +2
    Exec "$INSTDIR\Stick.ai.exe"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Stick.ai.lnk"
  RMDir /r "$SMPROGRAMS\Stick.ai"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Stick.ai"
  DeleteRegKey HKCU "Software\Stick.ai"
SectionEnd
