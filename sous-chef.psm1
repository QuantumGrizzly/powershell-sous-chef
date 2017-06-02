################################################################################
# PowerShell Module: sous-chef
################################################################################
<#
	.SYNOPSIS
	A PowerShell module helping with Chef and Cloud automation.
	.LINK
	https://github.com/QuantumGrizzly/powershell-sous-chef
#>

################################################################################
# PowerShell / Log
################################################################################
Function Write-Invocation {
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
			Write-Log -Level 'V1' -Message "Script: $Name"
			Write-Log -Level 'V2' -Message "Path" -Value $Path
		} Else {
			#Second IF checks if function is called from within another function
			#The trigger is the value stored in $Invocation.ScriptName
			#The value will be .\Library.ps1 if called from another Library function
			If ($Invocation.ScriptName -like "*Library*") {
				Write-Log -Level 'N1' -Message "`n"
				#Write-Log -Level 'V3' -Message "`n"
				#Write-Log -Level 'V2' -Message "-----NESTED FUNCTION-----"

				Write-Log -Level 'V2' -Message "Function: $Name"
			} Else {
				Write-Log -Level 'V1' -Message "Function: $Name"
			}
		}
		Write-Log -Level 'V2' -Message "Parameters" -Value $Line
	} #End Process
} #End Function

Function Write-Log {
	<#
	.SYNOPSIS
	Register logging events in the OUTPUT or VERBOSE pipeline.
	.DESCRIPTION
	The function logs strings, variable or objects into the OUTPUT or VERBORSE
	pileline of the PowerShell session.
	.EXAMPLE
	Write-Log -Level 'V1' -String 'Starting script'
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
# System / Process
################################################################################
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
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

		$Process = New-Object 'Diagnostics.ProcessStartInfo'
    $Process.FileName = $Executable
    $Process.Arguments = $Arguments

    Write-Log -Level 'V3' -Message "File Name" -Value $Process.FileName
    Write-Log -Level 'V3' -Message "Arguments" -Value $Process.Arguments

		Write-Log -Level 'V3' -Message "Starting the program execution"
    $RunningProcess = [Diagnostics.Process]::Start($Process)
    If ($Wait) {
				Write-Log -Level 'V3' -Message "Waiting the end of the execution"
        #$Wait.WaitForExit();
				$RunningProcess.WaitForExit();
				Write-Log -Level 'V3' -Message "Execution finished"
    }

	} #End of Process block
	End {
		Write-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

Function Test-Partition {
  <#
		.SYNOPSIS
		Send commands to AWS API to manipulate EC2 objects.
		.DESCRIPTION
		The function send commands using AWS CLI (aws.exe) to get describe, edit,
		create or delete EC2 objects.
		.EXAMPLE
		Run-Ec2Commands -Action
  #>
  #[CmdletBinding()]
  Param (
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		HelpMessage='Drive Letter')]
		[ValidateLength(1,1)]
		[string]$DriveLetter,

		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		HelpMessage='Should the partition be the only one on the disk?')]
		[ValidateLength(1,30)]
		[string]$CheckDedicated
  )

	Begin {
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"

  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

		$Partition = Get-Partition | Where DriveLetter -eq $DriveLetter
		If ($Partition) {
		    Write-Log -Level 'V3' -Message "Partition found"

		    If ($CheckDedicated) {
		        Write-Log -Level 'V3' -Message 'Checking dedicated disk'

						#Count the number of partitions on the same disk
		        $DiskPartitions = Get-Partition -DiskNumber $Partition.DiskNumber
		        $DiskCount = ($DiskPartitions | Measure).Count

						#Return result depending if more than one partition
		        If ($DiskCount -eq 1) {
							Write-Log -Level 'V3' -Message "Disk dedicated to partition"
							Return $True
		        } Else {
							Write-Log -Level 'V3' -Message 'Disk hosts other partitions'
							Return $False
		        }
		    } Else {
					Return $True
		    }
		} Else {
			Write-Log -Level 'V3' -Message 'Partition not found'
			Return $False
		} #End of condition Partition

	} #End of Process block
	End {
		Write-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

Function Set-ServiceAccount {
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
  #[CmdletBinding()]
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

	Begin {
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"

		#Test if service exists
    Try {
        $Service = Get-Service $Name -ErrorAction Stop
        Write-Log -Level 'V3' -Message '[+] Service exists'
    } Catch {
        Write-Log -Level 'V3' -Message '[-] Service does not exists'
        Return
    }
  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

    #Test if service is running
    If ($Service.Status -eq 'Running') {
        Write-Log -Level 'V3' -Message '[+] Service is running'
        Write-Log -Level 'V3' -Message '[!] Stopping service'
        Stop-Service -Name $Name -Verbose:$VerbosePreference -Force
    } Else {
        Write-Log -Level 'V3' -Message '[-] Service is not running'
    }

    #Change the service account
    Try {
        $Service = GWMI win32_service | Where-Object Name -like *$Name*
        $Service.Change( `
            $null, ` #DisplayName
            $null, ` #PathName
            $null, ` #ServiceType
            $null, ` #ErrorControl
            $null, ` #StartMode
            $null, ` #DesktopInteract
            $Username, ` #StartName
            $Password, ` #StartPassword
            $null, ` #LoadOrderGroup
            $null, ` #LoadOrderGroupDependencies
            $null)  #ServiceDependencies
    } Catch {
        Write-Log -Level 'V3' -Message '[!] An exception happened while trying to change the service'
    }

    #Restart the service
    Start-Service -Name $Name

	} #End of Process block
	End {
		Write-Log -Level 'V2' -Message "End"

		#Test if the service is running under the new account
		$Test = GWMI win32_service | Where-Object Name -like *$Name*
		If ($Test.StartName -eq $Username) {
				Write-Log -Level 'V3' -Message '[+] Service account successfully changed'
		} Else {
				Write-Log -Level 'V3' -Message '[-] Error, service use a different account'
				$Test.StartName
		}

	} #End of End block
} #Enf of function

################################################################################
# Network / SMB
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
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

		#Search for the network drive by looking for the UNC in Root
		If ($UNC) {
			Try {
				#Search for session UNC in the property .DisplayRoot (used in PS 5)
				#and then in property .Root if not found (used in earlier version)
				$Drive = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.DisplayRoot -like $UNC } -ErrorAction Stop
				If (-Not $Drive) {$Drive = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Root -like $UNC } -ErrorAction Stop}
				If ($Drive) {
					Write-Log -Level 'V3' -Message "Mapped folder found" -Value $UNC
				} Else {
					Write-Log -Level 'V3' -Message "Mapped folder not found" -Value $UNC
				}
				Return $Drive
			} Catch {
				Write-Log -Level 'V3' -Message "Mapped folder not found" -Value $UNC
			}
		#Search for a drive by looking at the Letter
		} Elseif ($Letter) {
			Try {
				$Drive = Get-PSDrive -PSProvider FileSystem -Name $Letter `
					-ErrorAction Stop
				Write-Log -Level 'V3' -Message "Drive found" -Value $Letter
				Return $Drive
			} Catch {
				Write-Log -Level 'V3' -Message "Drive not found" -Value $Letter
			}
		}
	}

	End {
		Write-Log -Level 'V2' -Message "End"
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
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

		#Check if the network session is already established to the shared folder
		$ConcurrentSession = Get-SessionDrive -UNC $UNC
		Write-Log -Level 'N2' -Message "`n"

		#Proceed if there is not session already established
		If (-Not $ConcurrentSession) {
			#Check if the drive letter is already used
			$ConcurrentDrive = Get-SessionDrive -Letter $Letter
			Write-Log -Level 'N2' -Message "`n"

			#Proceed if there is no drive already using the letter
			If ($ConcurrentDrive) {
				Write-Log -Level 'V3' -Message "Drive letter already taken" -Value $Letter
			} Else {
				Write-Log -Level 'V3' -Message "Drive letter available" -Value $Letter

				#Establish network session in a persistent or non-persistent way
				If ($Mapped) {
					Write-Log -Level 'V3' -Message "Establish persistent session" -Value $Letter
					New-PSDrive -Name $Letter -PSProvider 'FileSystem' -Root "$UNC" -Scope Global -Persist
				} Else {
					Write-Log -Level 'V3' -Message "Establish session" -Value $Letter
					New-PSDrive -Name $Letter -PSProvider 'FileSystem' -Root "$UNC" -Scope Global
				} #End of IF $Mapped
			} #End of IF $concurrentDrive
		} #End of If $ConcurrentSession
	} #End of Process block
	End {
		Write-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

################################################################################
# Network / AWS
################################################################################
Function Test-AWSSession {
  <#
		.SYNOPSIS
		Test the connection with AWS API.
		.DESCRIPTION
		The function execute a test command to AWS API to verify whether the session
		is initialized.
		.EXAMPLE
		Test-AWSSession -Command $Command
		.PARAMETER Command
		Command to run.
  #>
  [CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
  Param (
		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		HelpMessage='Test to perform')]
		[ValidateSet('Alias','AMI', 'Cookie')]
		[string]$Test = 'EC2'
  )

	Begin {
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

		#Perform test command
		Try {
			Switch ($Test) {
				alias {
					$ScriptBlock = {Get-IAMAccountAlias}
				}
				ami {
					$ScriptBlock = {aws ec2 describe-images --image-ids ami-e659c7f0}
				}
				cookie { #untested
					$ScriptBlock = {}
				}

			}
			Write-Log -Level 'V3' -Message "Invoke Command"
			$Result = Invoke-Command -command $ScriptBlock -ErrorAction Stop

			Write-Log -Level 'V3' -Message "Result" -Value $Result
			Return $Result
		} Catch {
			Write-Log -Level 'V3' -Message "An error occured while trying to connect AWS."
			Write-Log -Level 'V3' -Message "Exception code" -Value $error[0].ToString()
			Write-Debug $error[0].ToString()
		}
	} #End of Process block
	End {
		Write-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

Function Set-AWSSession {
  <#
		.SYNOPSIS
		Set the connection with AWS API.
		.DESCRIPTION
		The function establish a connection to AWS CLI by using the tool aws-adfs.
		.LINK
		https://github.com/venth/aws-adfs
		https://pypi.python.org/pypi/aws-adfs/0.3.3
		.EXAMPLE
		Set-AWSSession -Command $Command
		.PARAMETER Command
		Command to run.
  #>
  [CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
  Param (
		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		HelpMessage='Test if session exists first')]
		[ValidateNotNullOrEmpty()]
		#[ValidateLength(1,260)]
		[boolean]$Test = $True,

		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		HelpMessage='AWS Profile to use')]
		[ValidateNotNullOrEmpty()]
		[ValidateLength(1,50)]
		[string]$AWSProfile = 'nonprod'
  )

	Begin {
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"
  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

		#Initialize error codes
		$ErrorSecurityToken = 'The security token included in the request is expired'

		#Perform test command
		If ($Test -eq $True) {
			Write-Log -Level 'V3' -Message "Initialize Test-AWSSession."
			$Status = Test-AWSSession -Test 'Alias'
			Write-Log -Level 'N2' -Message "`n"

			If ($Status) {
				Write-Log -Level 'V3' -Message "Security token found, no need to continue."
				Return
			} Else {
				Write-Log -Level 'V3' -Message "Security token not found, proceeding."
			}
		}

		#Perform execution of the command establishing connection
		Try {
			$ScriptBlock = {aws-adfs login --no-ssl-verification}
			Write-Log -Level 'V3' -Message "Command" -Value "$ScriptBlock"

			Write-Log -Level 'V3' -Message "Executing command" -Value "$ScriptBlock"
			$Result = Invoke-Command -command $ScriptBlock -ErrorAction Stop

			Return $Result
		} Catch {
			Write-Log -Level 'V3' -Message "An error occured while trying to setup connection."
			Write-Log -Level 'V3' -Message "Exception code" -Value $error[0].ToString()
		}

	} #End of Process block
	End {
		Write-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

Function Invoke-Ec2Command {
  <#
		.SYNOPSIS
		Send commands to AWS API to manipulate EC2 objects.
		.DESCRIPTION
		The function send commands using AWS CLI (aws.exe) to get describe, edit,
		create or delete EC2 objects.
		.EXAMPLE
		Run-Ec2Commands -Action
  #>
  [CmdletBinding()]
	#[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Medium')]
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

		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		HelpMessage='Tag specification of the object')]
		[ValidateLength(1,1000)]
		[string]$TagSpecification
  )

	Begin {
		$MyInvocation | Write-Invocation
		Write-Log -Level 'V2' -Message "Begin"

  }
  Process {
		Write-Log -Level 'V2' -Message "Process"

		Switch ($Action) {
			#Launch an ec2 instance with or without tags
			launch_json {aws ec2 run-instances --cli-input-json file://$JsonPath}		#Working
			launch_json_tags {
				aws ec2 run-instances `
					--cli-input-json file://$JsonPath `
					--tag-specifications $TagSpecification
				}

			start {aws ec2 start-instances --instance-ids $InstanceId}
			stop {aws ec2 stop-instances --instance-ids $InstanceId}
			describe-instances {aws ec2 describe-instances --instance-ids $InstanceId}
			list-volumes {aws ec2 describe-instances --instance-ids $InstanceId}
			terminate-instances {aws ec2 terminate-instances --instance-ids $InstanceId}
			describe-volumes {aws ec2 describe-volumes --volume-ids $VolumeId}
		}
	} #End of Process block
	End {
		Write-Log -Level 'V2' -Message "End"
	} #End of End block
} #Enf of function

################################################################################
