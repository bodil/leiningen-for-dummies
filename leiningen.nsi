!include LogicLib.nsh
!include MUI.nsh
!include EnvVarUpdate.nsh
!include AddToPath.nsh
!include Sections.nsh

Name "Leiningen"
OutFile "Leiningen-Setup.exe"
InstallDir "$PROFILE\Leiningen"
InstallDirRegKey HKCU "Software\Leiningen" ""
RequestExecutionLevel user

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "COPYING.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL

Var JavaInstallationPath
Section "Java JRE" JAVA
  SectionIn RO

  DetectTry1:
    StrCpy $1 "SOFTWARE\JavaSoft\Java Runtime Environment"
    StrCpy $2 0
    ReadRegStr $2 HKLM "$1" "CurrentVersion"
    StrCmp $2 "" DetectTry2 JRE
  JRE:
    ReadRegStr $5 HKLM "$1\$2" "JavaHome"
    StrCmp $5 "" DetectTry2 GetValue

  DetectTry2:
    ReadRegStr $2 HKLM "SOFTWARE\JavaSoft\Java Development Kit" "CurrentVersion"
    StrCmp $2 "" NoJava JDK
  JDK:
    ReadRegStr $5 HKLM "SOFTWARE\JavaSoft\Java Development Kit\$2" "JavaHome"
    StrCmp $5 "" NoJava GetValue

  GetValue:
    StrCpy $JavaInstallationPath $5
    Goto done

  NoJava:
    # Install Java
    SetOutPath '$TEMP'
    SetOverwrite on
    File "/oname=$TEMP\jre_setup.exe" 'jre-7u6-windows-i586-iftw.exe'
    ExecWait "$TEMP\jre_setup.exe" $0
    DetailPrint '..Java Runtime Setup exit code = $0'
    Delete "$TEMP\jre_setup.exe"

    Goto DetectTry1

  done:
    #$JavaInstallationPath should contain the system path to Java
    Push "$JavaInstallationPath\bin"
    Call AddToPath

SectionEnd

Section "cURL" CURL
  SetOutPath "$INSTDIR"
  File "curl.exe"
  File "libcurl.dll"
  File "libeay32.dll"
  File "libidn-11.dll"
  File "ssleay32.dll"
SectionEnd

Section "Leiningen" LEIN
  SectionIn RO

  SetOutPath "$INSTDIR"

  inetc::get /caption "Leiningen" "https://raw.github.com/technomancy/leiningen/preview/bin/lein.bat" "$INSTDIR\lein.bat"

  Pop $R0 ;Get the return value
  ${If} $R0 != "OK"
    MessageBox MB_OK "Download failed: $R0"
    Quit
  ${EndIf}

  Push $INSTDIR
  Call AddToPath

  ExecWait "$INSTDIR\lein.bat self-install"

SectionEnd

Section "Catnip" CATNIP

  CreateDirectory "$PROFILE\.lein"
  File "/oname=$PROFILE\.lein\profiles.clj" "profiles.clj"

SectionEnd

Section -FinishSection

  WriteRegStr HKCU "Software\Leiningen" "" $INSTDIR
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Leiningen" "DisplayName" "Leiningen"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Leiningen" "UninstallString" "$INSTDIR\uninstall.exe"

SectionEnd

Section "uninstall"

  Push $INSTDIR
  Call un.RemoveFromPath

  Delete "$INSTDIR\lein.bat"
  Delete "$INSTDIR\curl.exe"
  Delete "$INSTDIR\libcurl.dll"
  Delete "$INSTDIR\libeay32.dll"
  Delete "$INSTDIR\libidn-11.dll"
  Delete "$INSTDIR\ssleay32.dll"
  Delete "$INSTDIR\uninstall.exe"
  RmDir "$INSTDIR"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Leiningen"
  DeleteRegKey HKLM "Software\Leiningen"

SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${JAVA} "Leiningen depends on an installed Java JRE. One will be installed if necessary."
  !insertmacro MUI_DESCRIPTION_TEXT ${CURL} "Leiningen needs cURL to bootstrap itself. If you already have cURL installed and on your path, you can skip this."
  !insertmacro MUI_DESCRIPTION_TEXT ${LEIN} "Leiningen!"
  !insertmacro MUI_DESCRIPTION_TEXT ${CATNIP} "Install a preset Leiningen profile that includes the Catnip IDE plugin."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

BrandingText "Leiningen"
