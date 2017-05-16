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
	[string[]]$Arguments
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
#Execute executable command
$Path = "$Folder\$Executable"
Invoke-Executable -Executable $Path -Arguments [string]$Arguments -Wait:$True
