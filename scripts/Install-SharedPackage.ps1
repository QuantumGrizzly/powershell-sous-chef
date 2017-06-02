################################################################################
# Initialization
################################################################################
#Setup script parameters
Param (
	[Parameter(Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='Path of the package folder.')]
	[ValidateLength(1,260)]
	[string[]]$Folder,

	[Parameter(Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='name of the executable in the folder.')]
	[ValidateLength(1,100)]
	[string[]]$Executable,

	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='Arguments used with the executable.')]
	[ValidateLength(1,100)]
	[string[]]$Arguments,

	[string]$Module
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

#Execute executable command
$Path = "$Folder\$Executable"
Invoke-Executable -Executable $Path -Arguments [string]$Arguments -Wait:$True -Verbose:$VerbosePreference
