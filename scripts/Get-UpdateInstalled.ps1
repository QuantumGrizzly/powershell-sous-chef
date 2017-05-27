################################################################################
# Initialization
################################################################################
<#
	.EXAMPLE
	.\Get-UpdateInstalled.ps1 -Verbose
#>
#Setup script parameters
Param (
	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='KB to search.')]
	#[ValidateLength(1,1)]
	[string[]]$KB,

	[string]$Module
)

# Helper Function loading library (script or module)
Function  Import-Library {
	Param (
		[string]$Name,
		[string]$Path
	)
	Write-Verbose 'Checking if resource is loaded'

	#Test if module is already loaded, if loaded end of execution
	If (Get-Module | Where-Object {$_.Path -like "*$Module*" }) {
		Write-Verbose '[+] Module Loaded'
	} Else {
		Write-Verbose '[-] Module Not Loaded'

		#Initialize resource path if not provided in arguments
		If (!($Path)) {
			$Path = Split-Path $Invocation.MyCommand.Path
			#$Path	= Split-Path -Path $Path
		}
		$Path = "$Path\$Name"

		#Detect if path is Root
		$Root = $Path[0] + ":\"

		#Search for library file in the folder and its parents
		Write-Verbose 'Entering While loop'
		While (!($Script:PathExists)) {
			$Test = Test-Path $Path

			If ($Test -eq $True) {
				Write-Verbose "[+] $Path"
				$Script:PathExists = 'Success'
			} Elseif ($Test -eq $False -and $Parent -eq $Root) {
				$Script:PathExists = "Failure"
			} Else {
				Write-Verbose "[-] $Path"
				$Parent = Split-Path -Path $Path -Parent | Split-Path -Parent
				If ($Parent -eq $Root) {
					Write-Verbose "[+] Root reached"
					$Path = "$Root$Name"
				} Else {
					#Write-Verbose "[-] Root not reached"
					$Path = "$Parent\$Name"
				} #End of If Root Parent
			} #Enf of If Test
		} #End of While

		#Test if library file exists
		If ($Script:PathExists -eq 'Success' ) {
			Write-Verbose '[+] Library file exists'
			Import-Module $Path
		} Else {
			Write-Verbose '[-] Library file does not exist'
			Exit
		} #End of If path
	} #End of If module
} #End of function

################################################################################
# Main
################################################################################
#Start execution
$Invocation = $MyInvocation
Import-Library -Name $Module
$Invocation | Write-Invocation -Main:$True -Verbose:$VerbosePreference

#Initialization
Write-Log -Level 'V2' -Message "Initialize variables"

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
Write-Log -Level 'V3' -Message "KB's to search" -Value $KB.Count -Verbose:$VerbosePreference

#Search for the KB using the class qfe
Write-Log -Level 'V2' -Message "Gather installed KBs from system" -Verbose:$VerbosePreference
$InstalledKB = Get-WmiObject -class win32_quickfixengineering

#Different method to return all KB's (including non-security)
#But it uses a different property format for HotFixID
#$InstalledKB = wmic qfe list

Write-Log -Level 'V3' -Message "KB's installed" -Value $InstalledKB.Count -Verbose:$VerbosePreference

#Loop for KB
Write-Log -Level 'V2' -Message "Start KB Loop" -Verbose:$VerbosePreference
Foreach ($Id in $KB) {
  #Write-Log -Level 'V3' -Message "Searching KB" -Value $Id
  $Result = $InstalledKB | Where-Object {$_.HotFixID -match "$Id"}
  If ($Result) {
    Write-Log -Level 'O2' -Message "KB Found:" -Value $Id -Verbose:$VerbosePreference
    Write-Log -Level 'O2' -Message "Installed On:" -Value $Result.InstalledOn -Verbose:$VerbosePreference
  } Else {
    Write-Log -Level 'V3' -Message "KB not Found:" -Value $Id -Verbose:$VerbosePreference
  }

#>
}
