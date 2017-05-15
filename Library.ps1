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
		$Source = $Invocation.MyCommand.Source
		$Line = $Invocation.Line -replace "`n|`r"

		#Log the function information in verbose
		#First IF checks if Function is called from the script body (Main) or from
		#another function
		If ($Main) {
			Set-Log -Level 'V1' -Message "Script: $Name"
			Set-Log -Level 'V2' -Message "Source" -Value $Source
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
		$LogOutput = "OUTPUT : $LogSpace1"
		$LogNested = "-----NESTED FUNCTION-----"

		#Perform logging when the message include a variable content
		If ($Value) {
			[string]$Message	= $Message
			[string]$Value		= $Value

			Switch ($Level) {
				#Verbose levels
				V1 { $Format = "$LogHeader1 {0,-30} [{1}]" -F $Message, $Value }
				V2 { $Format = "$LogSpace1 $LogHeader2 {0,-30} [{1}]" -F $Message, $Value }
				V3 { $Format = "$LogSpace1 $LogSpace2 `t- {0,-30} [{1}]" -F $Message, $Value }

				#Output levels
				O1 { $Format = "$LogOutput [!] {0,-30} [{1}]" -F $Message, $Value }
				O2 { $Format = "$LogOutput [+] {0,-30} [{1}]" -F $Message, $Value }
				O3 { $Format = "$LogOutput [-] {0,-30} [{1}]" -F $Message, $Value }
				#default {""}
			} #End Switch
			Write-Verbose ($Format)

		} Else {
			Switch ($Level) {
				#Verbose Messages
				V1 {Write-Verbose "$LogHeader1 $Message"}
				V2 {Write-Verbose "$LogSpace1 $LogHeader2 $Message"}
				V3 {Write-Verbose "$LogSpace1 $LogSpace2 $Message"}
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
		#Format the search used in Get-PSDrive depending of parameters

		If ($UNC) {
			Try {
				#Search for the network drive using the format T:\
				$Format = $Letter + ':\'
				$Drive = Get-PSDrive -PSProvider FileSystem | `
					Where-Object {$_.Root -eq $UNC} `
					-ErrorAction Stop
				Set-Log -Level 'V3' -Message "Mapped folder $UNC found"
				Return $Drive
			} Catch {
				Set-Log -Level 'V3' -Message "Mapped folder $UNC not found"
			}
		} Elseif ($Letter) {
			Try {
				$Drive = Get-PSDrive -PSProvider FileSystem | `
					Where-Object {$_.Root -eq $UNC} `
					-ErrorAction Stop
				Set-Log -Level 'V3' -Message "Drive $Letter found"
				Return $Drive
			} Catch {
				Set-Log -Level 'V3' -Message "Drive $Letter not found"
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

		[Parameter(Mandatory=$False,
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

		#Check if a session already exists under the same share UNC




		#Start execution of the share creation
		Try {
			#New-PSDrive -Name 'Temp' -PSProvider 'FileSystem' -Root $UNC
			#$Drive = Get-PSDrive -PSProvider FileSystem -Name $Letter -ErrorAction Stop
			#Set-Log -Level 'V3' -Message "Drive $Letter found"
			#Return $Drive
		} Catch {
			Set-Log -Level 'V3' -Message "Error when trying to establish session"
			#Write-Warning 'Drive not found'
			#Throw "[-] Drive $Letter does not exist [Error]"
		}

		If ($Letter) {
			$DriveExisting = Get-SessionDrive -Letter $Letter
			Set-Log -Level 'V2' -Message "Drive: $DriveExisting"
			Set-Log -Level 'N2' -Message "`n"
		}

		#Start session creation process
		#First IF operator checking if there is already an existing Mapped drive
		$RootExisting = Get-SessionDrive -UNC $UNC
		Set-Log -Level 'V2' -Message "Mapped Drive: $RootExisting"
		Set-Log -Level 'N2' -Message "`n"
		If ($RootExisting) {
			#"Test A1 $RootExisting"
			#The shared folder session already exists, no need to continue
			Set-Log -Level 'V3' -Message "Share $UNC already exists"
		} Else {
			#Check if the drive letter already exists on the system
			If ($Letter) {
				$DriveExisting = Get-SessionDrive -Letter $Letter
				Set-Log -Level 'V2' -Message "Drive: $DriveExisting"
				Set-Log -Level 'N2' -Message "`n"
			} Else {

			}

			#"Test 03 $RootExisting"
			Set-Log -Level 'V3' -Message "Creating the session"
			#Second IF operator checking if the shared folder session should be mapped
			If ($Mapped) {
				New-PSDrive -Name $Letter -Persist -PSProvider 'FileSystem' -Root "$UNC" #-Scope Global
			} Else {
				New-PSDrive -Name $Letter -PSProvider 'FileSystem' -Root "$UNC" -Scope Global
			}
		}

	} #End of Process block
	End {
		Set-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

################################################################################
