#$PSDefaultParameterValues['*:Encoding'] = 'utf8'
#$ProgressPreference = 'SilentlyContinue'
#Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name ActiveHoursEnd

$fPicPrefix = $Env:Onedrive + '\图片\Wallpaper\unSplash-Wallpaper-'
$strHeader = 'Client-ID ' + (Get-Content -Path $PSScriptRoot\unSplashID.txt)
$sProxy = 'http://clash-proxy:10900/'
$nHistory = 20

<#
collections     Public collection ID(‘s) to filter selection. If multiple, comma-separated
topics          Public topic ID(‘s) to filter selection. If multiple, comma-separated
username        Limit selection to a single user.
query           Limit selection to photos matching a search term.
orientation     Filter by photo orientation. (Valid values: landscape, portrait, squarish)
content_filter  Limit results by content safety. Default: low. Valid values are low and high.
count           The number of photos to return. (Default: 1; max: 30)
https://unsplash.com/documentation#get-a-random-photo
#>
$urlRandomParameters='&orientation=landscape&collections=background&content_filter=high'
<#
w, h:   for adjusting the width and height of a photo
crop:   for applying cropping to the photo
fm:     for converting image format
auto=format:    for automatically choosing the optimal image format depending on user browser
q:      for changing the compression quality when using lossy file formats
fit:    for changing the fit of the image within the specified dimensions
dpr:    for adjusting the device pixel ratio of the image
https://unsplash.com/documentation#supported-parameters
#>
$picImgixparameters='&w=1920&h=1080&fit=crop&crop=edges'

$jsonPicUnsplash = Invoke-RestMethod `
    -Uri ('https://api.unsplash.com/photos/random?' + $urlRandomParameters) -Method Get `
    -Headers @{'Authorization' = $strHeader; 'Accept-Version' = 'v1'} 
$filePic = ($fPicPrefix + $jsonPicUnsplash.id + '.jpg')
Invoke-WebRequest -Uri ($jsonPicUnsplash.urls.raw + $picImgixparameters) -OutFile $filePic -Proxy $sProxy

$srcSetWallpapers = @"
using System.Runtime.InteropServices;
public class Wallpaper
{
  public const int SetDesktopWallpaper = 20;
  public const int UpdateIniFile = 0x01;
  public const int SendWinIniChange = 0x02;
  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
  public static void SetWallpaper(string path)
  {
    SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
  }
}
"@
Add-Type -TypeDefinition $srcSetWallpapers

if (Test-Path -Path "$filePic") {
  [Wallpaper]::SetWallpaper($filePic)
}

<#
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name WallPaper -Value $filePic
1..60|ForEach-Object{
  RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters ,1 ,True
  Start-Sleep 1
}
#>

$listHistory = (Get-Item ($fPicPrefix + '*') | Sort-Object -Property LastWriteTime -Descending | Select-Object -Skip $nHistory)
If ($listHistory.count -gt 0) {
    foreach($_ in $listHistory)
    {
        Remove-Item $_.FullName -Recurse -Force
    }
} 