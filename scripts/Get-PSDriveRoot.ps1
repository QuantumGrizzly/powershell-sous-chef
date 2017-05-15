#cls; D:\coding\powershell-sous-chef\scripts\Copy-SharedPackage.ps1 -Verbose -Share '\\localhost\users' -Letter 'T'
#cls; D:\coding\powershell-sous-chef\scripts\Copy-SharedPackage.ps1 -Verbose -Share '\\localhost\users' -Letter 'T' -Mapped:$True
#cls; .\Get-PSDriveRoot.ps1 -Verbose

#Variables
$Letter = 'X'
$LetterMap = 'T'
$UNC = '\\localhost\users'

Write-Warning 'Set Non-Persistent Drive'
$NewDrive = New-PSDrive -Name $Letter -PSProvider 'FileSystem' -Root $UNC

#Write-Warning 'Get PSDrive'
#Get-PSDrive -PSProvider FileSystem #| Format-List

#WORKING
Write-Warning 'Get TEMP drive where Root'
$NonPersistent = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Root -eq $UNC}
$NonPersistent

#WORKING
Write-Warning 'Get MAPPED drive where Root'
$Format = $LetterMap + ':\'
$Mapped = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Root -eq $Format}
$Mapped
