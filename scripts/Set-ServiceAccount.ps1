################################################################################
# Initialization
################################################################################
<#
	.SYNOPSIS
	Modify the account of a Windows Service.
	.DESCRIPTION
	The function stops and change the username and password of a Windows Service
	before starting it again.
	.EXAMPLE
	.\Set-ServiceAccount.ps1 -Name 'MSSQLSERVER' -Username '.\svc-sql-new' -Password 'Passw0rd' -Verbose
	.\Set-ServiceAccount.ps1 -Name 'SQLSERVERAGENT' -Username '.\svc-sql-new' -Password 'Passw0rd' -Verbose
#>

#Setup script parameters
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='Name of the service (Service name, not Display Name)')]
	[ValidateLength(1,50)]
	[string]$Name,

	[Parameter(Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='Username of the Log On account')]
	[ValidateLength(1,50)]
	[string]$Username,

	[Parameter(Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='Password of the Log On account')]
	[ValidateLength(1,50)]
	[string]$Password
)

# Helper Function loading library (script or module)
Function  Import-Library {
	Param (
		[string]$Name,
		[string]$Path = 'C:\Program Files\WindowsPowerShell\Modules'
	)
	Write-Verbose 'Checking if resource is loaded'

	#Test if module is already loaded, if loaded end of execution
	If (Get-Module | Where-Object {$_.Path -like "*$Name*" }) {
		Write-Verbose '[+] Module Loaded'
	} Else {
		Write-Verbose '[-] Module Not Loaded'

        #Method 01: Try to find module in default PowerShell folder
        $Folder = [io.path]::GetFileNameWithoutExtension($Name)
        Try {
            $ModulePath = Get-Item $Path\*$Folder* -ErrorAction Stop
            Write-Verbose '[+] Module found in path'
            $ModulePath.FullName

            #Try to find the module file (*.psm1 in folder)
            Try {
                $ModuleFilePath = Get-ChildItem -Path $ModulePath -Filter '*.psm1' -Recurse
                Write-Verbose "[+] Module file found in folder"
                $ModuleFilePath.FullName

                Import-Module $ModuleFilePath.FullName
                Return

            } Catch {
                Write-Verbose '[-] Module file not found in path'
            }

            $ModuleFilePath = Get-ChildItem -Path $ModulePath -Filter '*.psm1' -Recurse
            $ModuleFilePath.FullName
        } Catch {
            Write-Verbose '[-] Module not found in path'
        }

		#Method 02: Try to find module in script folder
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
Import-Library -Name 'sous-chef.psm1'
$Invocation | Write-Invocation -Main:$True -Verbose:$VerbosePreference

#Check the connection to AWS works
Write-Log -Level 'V2' -Message "Start Main Logic" -Verbose:$VerbosePreference

Set-ServiceAccount `
    -Name $Name `
    -Username $Username `
    -Password $Password `
    -Verbose:$VerbosePreference
