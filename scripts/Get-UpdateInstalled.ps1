
################################################################################
# Initialization
################################################################################
#Setup script parameters
Param (
	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='KB to search.')]
	#[ValidateLength(1,1)]
	[string[]]$KB
)

#Import Library
$LibraryName	= 'Library.ps1'
$ScriptPath		= Split-Path $MyInvocation.MyCommand.Path
$LibraryPath	= Split-Path -Path $ScriptPath
. "$LibraryPath\$LibraryName"

#Start execution
$MyInvocation | Log-Invocation -Main:$True

################################################################################
# Main
################################################################################
#Usage
#CLS; .\Get-UpdateInstalled.ps1 -Verbose

#Initialization
Set-Log -Level 'V2' -Message "Initialize variables"

#KB's relevant to fix WannaCrypt vulnerability
$KB = @(
4012598,
4012212,
4012215,
4012213,
4012216,
4012214,
4012217,
4012606,
4013198,
4013389,
3177186,
3212646,
3205401,
3205409,
3210720,
3210721,
3213986,
4010096,
4010096,
4013429,
4015217,
4015438,
4015549,
4015550,
4015551,
4015552,
4015553,
4016635,
4019215,
4019216,
4019264,
4019472
)
Set-Log -Level 'V3' -Message "KB's to search" -Value $KB.Count

#Search for the KB using the class qfe
Set-Log -Level 'V2' -Message "Gather installed KBs from system"
$InstalledKB = Get-WmiObject -class win32_quickfixengineering

#Different method to return all KB's (including non-security)
#But it uses a different property format for HotFixID
#$InstalledKB = wmic qfe list

Set-Log -Level 'V3' -Message "KB's installed" -Value $InstalledKB.Count

#Loop for KB
Set-Log -Level 'V2' -Message "Start KB Loop"
Foreach ($Id in $KB) {
  #Set-Log -Level 'V3' -Message "Searching KB" -Value $Id
  $Result = $InstalledKB | Where-Object {$_.HotFixID -match "$Id"}
  If ($Result) {
    Set-Log -Level 'O2' -Message "KB Found:" -Value $Id
    Set-Log -Level 'O2' -Message "Installed On:" -Value $Result.InstalledOn
  } Else {
    Set-Log -Level 'V3' -Message "KB not Found:" -Value $Id
  }

#>
}
