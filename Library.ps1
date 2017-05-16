################################################################################
# Script Automation
################################################################################

Function Log-Invocation {
	<#
	.SYNOPSIS
	Log a function initialization in Verbose.
	.DESCRIPTION
	This function logs function calls and initialization into verbose pipeline.
	.EXAMPLE

	.PARAMETER Level

	#>
	[CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
	Param (
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Invocation object')]
			$Invocation,

		[Parameter(Mandatory=$False,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Switch to identify if script is called in Main body')]
			[boolean]$Main = $False
	)

	Process {
		#Get information about script invocation
		$Name= $Invocation.MyCommand.Name
		$Path = $Invocation.MyCommand.Path
		$Line = $Invocation.Line -replace "`n|`r"

		#Log the function information in verbose
		#First IF checks if Function is called from the script body (Main) or from
		#another function
		If ($Main) {
			Set-Log -Level 'V1' -Message "Script: $Name"
			Set-Log -Level 'V2' -Message "Path" -Value $Path
		} Else {
			#Second IF checks if function is called from within another function
			#The trigger is the value stored in $Invocation.ScriptName
			#The value will be .\Library.ps1 if called from another Library function
			If ($Invocation.ScriptName -like "*Library*") {
				Set-Log -Level 'N1' -Message "`n"
				#Set-Log -Level 'V3' -Message "`n"
				#Set-Log -Level 'V2' -Message "-----NESTED FUNCTION-----"

				Set-Log -Level 'V2' -Message "Function: $Name"
			} Else {
				Set-Log -Level 'V1' -Message "Function: $Name"
			}
		}
		Set-Log -Level 'V2' -Message "Parameters" -Value $Line
	} #End Process
} #End Function

Function Set-Log {
	<#
	.SYNOPSIS
	Register logging events in the OUTPUT or VERBOSE pipeline.
	.DESCRIPTION
	The function logs strings, variable or objects into the OUTPUT or VERBORSE
	pileline of the PowerShell session.
	.EXAMPLE
	Set-Log -Level 'V1' -String 'Starting script'
	.PARAMETER Level
	Type of indentation used:
	V1 '----->'
	V2 '==>'
	.PARAMETER String
	Mesaged to be displayed in the log.
	#>
	[CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
	Param (
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Type of indentation used')]
			[ValidateLength(2,2)]
			[string[]]$Level,

		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='String to be logged.')]
			[ValidateLength(1,50)]
			[string[]]$Message,

		[Parameter(Mandatory=$False,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Content of a variable to pass.')]
			[ValidateLength(1,200)]
			[string[]]$Value
	)

	Process {
		#Define the different levels of indentation
		$LogHeader1	= '----->'
		$LogHeader2	= '==>'
		$LogSpace1	= '      '
		$LogSpace2	= '   '
		$LogOutput1 = "OUTPUT : $LogSpace1"
		$LogOutput2 = $LogOutput1 + $LogSpace2
		$LogNested = "-----NESTED FUNCTION-----"

		#Perform logging when the message include a variable content
		If ($Value) {
			[string]$Message	= $Message
			[string]$Value		= $Value

			$Type = $Level.SubString(0,1)
			Switch ($Type) {
				V {
					Switch ($Level) {
						#Verbose levels
						V1 { $Format = "$LogHeader1 {0,-50} [{1}]" -F $Message, $Value }
						V2 { $Format = "$LogSpace1 $LogHeader2 {0,-50} [{1}]" -F $Message, $Value }
						V3 { $Format = "$LogSpace1 $LogSpace2 `t- {0,-50} [{1}]" -F $Message, $Value }
					} #End Switch Verbose Levels
					Write-Verbose ($Format)
				} #End of Switch Verbose

				O {
					Switch ($Level) {
						O1 { $Format = "$LogOutput1 $LogSpace2 [!]{0,-50} [{1}]" -F $Message, $Value }
						O2 { $Format = "$LogOutput1 $LogSpace2 [+]{0,-50} [{1}]" -F $Message, $Value }
						O3 { $Format = "$LogOutput1 $LogSpace2 [-]{0,-50} [{1}]" -F $Message, $Value }
					} #End Switch Output Levels
					Write-Output ($Format)
				} #End of Switch Output

				D {} #End of Switch Debug
			}
			#Write-Verbose ($Format)

		} Else {
			Switch ($Level) {
				#Verbose Messages
				V1 {Write-Verbose "$LogHeader1 $Message"}
				V2 {Write-Verbose "$LogSpace1 $LogHeader2 $Message"}
				#V3 {Write-Verbose "$LogSpace1 $LogSpace2 $Message"}
				V3 {Write-Verbose "$LogSpace1 $LogSpace2 `t- $Message"}
				O1 {Write-Output "$LogOutput [!] $Message"}
				O2 {Write-Output "$LogOutput [+] $Message"}
				O3 {Write-Output "$LogOutput [-] $Message"}

				#Verbose messages for Nested Functions
				N1 {Write-Verbose ''; Write-Verbose "$LogSpace1 $LogNested"}
				N2 {Write-Verbose "$LogSpace1 $LogNested"; Write-Verbose ''}
				#default {""}
			} #End Switch
		} #End If
	} #End Process
} #End Function

Function Format-TableObject {
	Param(
		[string]$Col1, [string]$Value1,
		[string]$Col2, [string]$Value2,
		[string]$Col3, [string]$Value3
	)
	Process {
		$Object = New-Object PSObject
		If ($Col1) { $Object | Add-Member NoteProperty $Col1 $Value1 }
		If ($Col2) { $Object | Add-Member NoteProperty $Col2 $Value2 }
		If ($Col3) { $Object | Add-Member NoteProperty $Col3 $Value3 }
		Write-Output $Object
	}
}

Function Format-Verbose {
	<#
	.SYNOPSIS
	Register logging events in the OUTPUT or VERBOSE pipeline.
	.LINK
	Original code by craigmmartin@hotmail.com
	http://www.integrationtrench.com/2014/07/neatly-formatting-hashtable-in-verbose.html
	#>
	Param(
		[string]$Data,
		[string]$Value
	)
	Process {
		$HashTable = @{
			$Data     = $Value
			#bar     = $Value
		}

		### Find the longest Key to determine the column width
		$ColumnWidth = $HashTable.Keys.length | Sort-Object| Select-Object -Last 1

		### Output the HashTable using the column width
		$HashTable.GetEnumerator() | ForEach-Object {
			Write-Verbose ("  {0,-$ColumnWidth} : {1}" -F $_.Key, $_.Value) -Verbose
		}
	}
}

################################################################################
# Network
################################################################################
Function Get-SessionDrive {
  <#
	  .SYNOPSIS
	  Identify if a drive (local or network) already exists on the system.
	  .DESCRIPTION
	  This function will verify if a mapped drived or session drive exists on the OS
	  .EXAMPLE
	  Get-SessionDrive -Letter 'T'
	  .PARAMETER Letter
	  Letter of the drive to check.
  #>
  [CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
  Param (
    [Parameter(Mandatory=$False,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='Which drive letter do you want to check')]
    [ValidateLength(1,1)]
    [string[]]$Letter,

		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
			HelpMessage='Shared Folder UNC to check')]
		[ValidateLength(1,100)]
		[string[]]$UNC
  )

	Begin {
		$MyInvocation | Log-Invocation
		Set-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Set-Log -Level 'V2' -Message "Process"

		#Search for the network drive by looking for the UNC in Root
		If ($UNC) {
			Try {
				#Search for session UNC in the property .DisplayRoot (used in PS 5)
				#and then in property .Root if not found (used in earlier version)
				$Drive = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.DisplayRoot -like $UNC } -ErrorAction Stop
				If (-Not $Drive) {$Drive = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Root -like $UNC } -ErrorAction Stop}
				If ($Drive) {
					Set-Log -Level 'V3' -Message "Mapped folder found" -Value $UNC
				} Else {
					Set-Log -Level 'V3' -Message "Mapped folder not found" -Value $UNC
				}
				Return $Drive
			} Catch {
				Set-Log -Level 'V3' -Message "Mapped folder not found" -Value $UNC
			}
		#Search for a drive by looking at the Letter
		} Elseif ($Letter) {
			Try {
				$Drive = Get-PSDrive -PSProvider FileSystem -Name $Letter `
					-ErrorAction Stop
				Set-Log -Level 'V3' -Message "Drive found" -Value $Letter
				Return $Drive
			} Catch {
				Set-Log -Level 'V3' -Message "Drive not found" -Value $Letter
			}
		}
	}

	End {
		Set-Log -Level 'V2' -Message "End"
	}
}

Function Set-SessionDrive {
  <#
		.SYNOPSIS
		Set up a network drive on the system.
		.DESCRIPTION
		The function will check if a drive already exists under the letter. If not
		it will set it up as either a session or persistent drive.

		Establish the network session one of two methods:
		1) Persistent, the drive will be mounted on the OS and available to all
		2) Non-Persistent Global, the session will be available within PowerShell
		.EXAMPLE
		Get-SessionDrive -Letter 'T'
		.PARAMETER Letter
		Letter of the drive to check.
  #>
  [CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
  Param (
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
			HelpMessage='Shared Folder UNC to check')]
		[ValidateLength(1,100)]
		[string[]]$UNC,

		[Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='Which drive letter do you want to check')]
    [ValidateLength(1,1)]
    [string]$Letter,

		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
			HelpMessage='Should the shared folder be mapped?')]
		#[ValidateLength(1,1)]
		[boolean[]]$Mapped = $False
  )

	Begin {
		$MyInvocation | Log-Invocation
		Set-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Set-Log -Level 'V2' -Message "Process"

		#Check if the network session is already established to the shared folder
		$ConcurrentSession = Get-SessionDrive -UNC $UNC
		Set-Log -Level 'N2' -Message "`n"

		#Proceed if there is not session already established
		If (-Not $ConcurrentSession) {
			#Check if the drive letter is already used
			$ConcurrentDrive = Get-SessionDrive -Letter $Letter
			Set-Log -Level 'N2' -Message "`n"

			#Proceed if there is no drive already using the letter
			If ($ConcurrentDrive) {
				Set-Log -Level 'V3' -Message "Drive letter already taken" -Value $Letter
			} Else {
				Set-Log -Level 'V3' -Message "Drive letter available" -Value $Letter

				#Establish network session in a persistent or non-persistent way
				If ($Mapped) {
					Set-Log -Level 'V3' -Message "Establish persistent session" -Value $Letter
					New-PSDrive -Name $Letter -PSProvider 'FileSystem' -Root "$UNC" -Scope Global -Persist
				} Else {
					Set-Log -Level 'V3' -Message "Establish session" -Value $Letter
					New-PSDrive -Name $Letter -PSProvider 'FileSystem' -Root "$UNC" -Scope Global
				} #End of IF $Mapped
			} #End of IF $concurrentDrive
		} #End of If $ConcurrentSession
	} #End of Process block
	End {
		Set-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

Function Invoke-Executable {
  <#
		.SYNOPSIS
		Run an executable program.
		.DESCRIPTION
		The function will execute a program with or without arguments provided.
		.EXAMPLE
		Invoke-Executable -Executable $Path -Arguments $Arguments -Wait:$True
		.PARAMETER Executable
		Path of the executable to run.
		.PARAMETER Arguments
		Arguments to run against the executable.
		.PARAMETER Wait
		Waiting the execution is finished.
  #>
  [CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
  Param (
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
			HelpMessage='Path of the executable to run')]
		[ValidateLength(1,260)]
		[string[]]$Executable,

		[Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='Arguments to run against the executable')]
    [ValidateLength(1,100)]
    [string]$Arguments,

		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
			HelpMessage='Waiting the execution is finished')]
		[switch[]]$Wait = $False
  )

	Begin {
		$MyInvocation | Log-Invocation
		Set-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Set-Log -Level 'V2' -Message "Process"

		$Process = New-Object 'Diagnostics.ProcessStartInfo'
    $Process.FileName = $Executable
    $Process.Arguments = $Arguments

    Set-Log -Level 'V3' -Message "File Name" -Value $Process.FileName
    Set-Log -Level 'V3' -Message "Arguments" -Value $Process.Arguments

		Set-Log -Level 'V3' -Message "Starting the program execution"
    $RunningProcess = [Diagnostics.Process]::Start($Process)
    If ($Wait) {
				Set-Log -Level 'V3' -Message "Waiting the end of the execution"
        #$Wait.WaitForExit();
				$RunningProcess.WaitForExit();
				Set-Log -Level 'V3' -Message "Execution finished"
    }

	} #End of Process block
	End {
		Set-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function


################################################################################
