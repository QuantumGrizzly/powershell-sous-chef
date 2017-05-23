
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
	[string]$VolumeId
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
#Check the connection to AWS works
Set-Log -Level 'V2' -Message "Start Main Logic"

#Setup AWS CLI connection if it is not already established
Set-AWSSession -Test:$True -AWSProfile 'nonprod'

#Perform AWS action
Set-Log -Level 'V2' -Message "Peform action"
Set-Log -Level 'V3' -Message "Type" -Value $Action

Invoke-Ec2Command -Action $Action -JsonPath $JsonPath
#Invoke-Ec2Command -Action $Action -JsonPath $JsonPath -TagSpecification $TagJson
