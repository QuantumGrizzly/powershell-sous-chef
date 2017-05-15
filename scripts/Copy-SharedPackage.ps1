################################################################################
# Initialization
################################################################################
#Setup script parameters
Param
(
	[Parameter(Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='Letter of the drive to mount.')]
	[ValidateLength(1,1)]
	[string[]]$Letter,

	[Parameter(Mandatory=$True,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='UNC path of the shared folder to mount.')]
	[ValidateLength(1,50)]
	[string[]]$Share,

	[Parameter(Mandatory=$False,
	ValueFromPipeline=$True,
	ValueFromPipelineByPropertyName=$True,
		HelpMessage='Should the shared folder be mapped?')]
	#[ValidateLength(1,1)]
	[boolean[]]$Mapped = $False
)

################################################################################
# Main
################################################################################
#Import Library
$LibraryName	= 'Library.ps1'
$ScriptPath		= Split-Path $MyInvocation.MyCommand.Path
$LibraryPath	= Split-Path -Path $ScriptPath
. "$LibraryPath\$LibraryName"

#Start execution
$MyInvocation | Log-Invocation -Main:$True

Set-SessionDrive -UNC $Share -Letter "$Letter" -Mapped:$Mapped
#Set-SessionDrive -UNC $Share -Letter "$Letter" -Mapped:$Mapped
