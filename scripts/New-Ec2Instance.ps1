
################################################################################
# Initialization
################################################################################
#Setup script parameters
Param (
	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='Type of action you would like to perform')]
	[ValidateLength(1,50)]
	#[ValidateSet('Launch','Start', 'Stop', 'Terminate', 'describe-instances', 'List-Volumes')]
	[string]$Action,

	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='Path of the JSON file used in input')]
	[ValidateLength(1,260)]
	[string]$JsonPath,

	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='ID of the EC2 instance')]
	[ValidateLength(17,19)]
	[string]$InstanceId,

	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
	HelpMessage='ID of the EC2 Volume')]
	[ValidateLength(19,21)]
	[string]$VolumeId,

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

#Check the connection to AWS works
Write-Log -Level 'V2' -Message "Start Main Logic" -Verbose:$VerbosePreference

#Setup AWS CLI connection if it is not already established
Set-AWSSession -Test:$True -AWSProfile 'nonprod' -Verbose:$VerbosePreference

#Perform AWS action
Write-Log -Level 'V2' -Message "Peform action" -Verbose:$VerbosePreference
Write-Log -Level 'V3' -Message "Type" -Value $Action -Verbose:$VerbosePreference

Invoke-Ec2Command -Action $Action -JsonPath $JsonPath -Verbose:$VerbosePreference
#Invoke-Ec2Command -Action $Action -JsonPath $JsonPath -TagSpecification $TagJson
