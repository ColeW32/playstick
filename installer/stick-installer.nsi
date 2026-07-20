; Stick.ai Windows installer - one-click install like E6 / FlightScope.
; Installs to the user's local Programs folder (no admin/UAC prompt), creates a
; desktop shortcut + Start Menu entries, registers an uninstaller, and offers to
; launch the app when finished. Built on a Windows runner:
;   makensis /DSRC=<staging-dir> /DOUTFILE=<out.exe> stick-installer.nsi

!include "MUI2.nsh"

!define APPNAME "Stick.ai"
!define COMPANY "Stick"
; APPVER is the real app version, passed by CI (/DAPPVER=0.53). Falls back for local builds.
!ifndef APPVER
  !define APPVER "1.0.0"
!endif
!define VERSION "${APPVER}"

Name "${APPNAME}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Programs\Stick.ai"
InstallDirRegKey HKCU "Software\Stick.ai" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma

; --- Setup.exe file metadata (Properties -> Details), so the installer itself is identifiable ---
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "Stick.ai"
VIAddVersionKey "ProductVersion" "${APPVER}"
VIAddVersionKey "FileVersion" "${APPVER}"
VIAddVersionKey "FileDescription" "Stick.ai Installer"
VIAddVersionKey "CompanyName" "${COMPANY}"
VIAddVersionKey "LegalCopyright" "Stick"

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
  ; Stop the running app AND its connector FIRST. Windows refuses to let File /r overwrite a
  ; locked file — if the old Stick.ai.exe (or the mevo-connector holding a handle on the app
  ; folder) is still open, the copy below silently skips those files while everything else
  ; updates, so Setup reports success but the app, and the version it shows, never change.
  ; This is the classic "reinstall does nothing / still shows the old version" failure.
  ; /T also kills any child processes the app spawned.
  nsExec::Exec 'taskkill /F /T /IM "Stick.ai.exe"'
  nsExec::Exec 'taskkill /F /IM "mevo-connector.exe"'
  nsExec::Exec 'taskkill /F /IM "mevo-connector-ota.exe"'
  Sleep 1500   ; give Windows time to release the file locks before we delete

  ; Clean replace: wipe the previous install so no stale file from an older build survives.
  ; Safe — user data (stats/settings) lives in AppData\LocalLow, never in $INSTDIR.
  RMDir /r "$INSTDIR"

  SetOutPath "$INSTDIR"
  SetOverwrite on
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
