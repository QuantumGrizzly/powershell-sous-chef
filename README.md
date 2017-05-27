# powershell-sous-chef
A PowerShell module helping with Chef and Cloud automation.

## Purpose
Sous-Chef is a PowerShell module offering advanced functions to be reused in scripts, Chef cookbooks or any other tools requiring to execute PowerShell to automate tasks on Windows systems.

By providing those functions into libraries, it avoid situations where developers have to reinvent the wheel to perform common tasks accross scripts and projects. The functions in the module aim to accomplish those goals:
 - Wrote as PowerShell advanced functions
 - Documented using keywords
 - Include error handlings and exceptions
 - Can be easily re-used in other works by dot sourcing the libraries


## Usage
Functions provided in the library:

### Write-Invocation

```PowerShell
Function Write-Invocation {
	<#
	.SYNOPSIS
	Log a function initialization in Verbose.
	.DESCRIPTION
	This function logs function calls and initialization into verbose pipeline.
	.EXAMPLE

	.PARAMETER Level

	#>
```

### Write-Log
```PowerShell
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
```

### Format-TableObject
```PowerShell
Function Format-TableObject {
```

### Format-Verbose
```PowerShell
Function Format-Verbose {
	<#
	.SYNOPSIS
	Register logging events in the OUTPUT or VERBOSE pipeline.
	.LINK
	Original implementation by craigmmartin@hotmail.com
	http://www.integrationtrench.com/2014/07/neatly-formatting-hashtable-in-verbose.html
	#>
```

### Get-SessionDrive
```PowerShell
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
```

### Set-SessionDrive
```PowerShell
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
```


## Versions
* 0.1.0 Initial version
  - [x] Created the module
  - [x] Implemented logging functions
  - [x] Implemented SMB network session functions


## Reference
  - Maintainer: [QuantumGrizzly][1]
  - Git Repository: [powershel-sous-chef][2]



[1]: https://github.com/QuantumGrizzly
[2]: https://github.com/QuantumGrizzly/powershell-sous-chef
