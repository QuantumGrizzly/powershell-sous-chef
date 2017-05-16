
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
$KB = @(4012598,
  4012212,
  4012215,
  4012213,
  4012216,
  4012214,
  4012217,
  4012606,
  4013198,
  4013429)
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
  Set-Log -Level 'V3' -Message "Searching KB" -Value $Id
  $Result = $InstalledKB | Where-Object {$_.HotFixID -match "$Id"}
  If ($Result) {
    Set-Log -Level 'O2' -Message "KB Found:" -Value $Id
    Set-Log -Level 'O2' -Message "Installed On:" -Value $Result.InstalledOn
  }

#>
}
