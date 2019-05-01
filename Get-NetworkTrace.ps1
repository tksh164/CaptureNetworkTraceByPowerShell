#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $SaveFolderPath,

    [Parameter(Mandatory = $false)]
    [string] $FilePrefix,

    [Parameter(Mandatory = $false)]
    [uint32] $FileSwitchInterval  # in seconds.
)

$ErrorActionPreference = 'Stop'

function Invoke-Netsh
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Arguments
    )

    # Prepare the process information.
    $processInfo = New-Object -TypeName 'System.Diagnostics.ProcessStartInfo'
    $processInfo.UseShellExecute = $false
    $processInfo.RedirectStandardError = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.FileName = 'C:\Windows\System32\netsh.exe'
    $processInfo.Arguments = $Arguments
    $processInfo.WorkingDirectory = $PSScriptRoot

    # Create, execute and wait to the process.
    $process = New-Object -TypeName 'System.Diagnostics.Process'
    $process.StartInfo = $processInfo
    [void] $process.Start()
    $process.WaitForExit()

    # Retrieve the results of invoke command.
    [PSCustomObject] @{
        ExitCode = $process.ExitCode
        StdOut = $process.StandardOutput.ReadToEnd()
        StdErr = $process.StandardError.ReadToEnd()
    }
}

function Start-NetworkTrace
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $TraceFileSavePath,

        [Parameter(Mandatory = $false)]
        [uint32] $MaxFileSize = 500  # in mega bytes.
    )

    Invoke-Netsh -Arguments ('trace start capture=yes report=disabled correlation=disabled maxSize={0} traceFile="{1}"' -f $MaxFileSize, $TraceFileSavePath)
}

function Stop-NetworkTrace
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Invoke-Netsh -Arguments 'trace stop'
}

function Get-TraceFileName
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Prefix,

        [Parameter(Mandatory = $false)]
        [uint32] $FileCount = 0
    )

    ('{0}-{1}-{2}-{3:d3}.etl' -f $Prefix, $env:ComputerName, (Get-Date -Format 'yyyyMMdd-HHmmss'), $FileCount)
}

#
# Set default values if those were not specified.
#

if (-not $PSBoundParameters.Keys.Contains('SaveFolderPath')) { $SaveFolderPath = $PSScriptRoot }
if (-not $PSBoundParameters.Keys.Contains('FilePrefix')) { $FilePrefix = 'netcap' }
if (-not $PSBoundParameters.Keys.Contains('FileSwitchInterval')) { $FileSwitchInterval = 60 * 60 * 24 } # A day in seconds.

# Validate the save folder path.
$SaveFolderPath = (Resolve-Path -LiteralPath $SaveFolderPath).Path
if (-not (Test-Path -LiteralPath $SaveFolderPath -PathType Container))
{
    throw ('The specified save folder path "{0}" did not represent a folder.' -f $SaveFolderPath)
}

# Validate the file prefix.
$traceFilePath = Join-Path -Path $SaveFolderPath -ChildPath (Get-TraceFileName -Prefix $FilePrefix)
if (-not (Test-Path -LiteralPath $traceFilePath -PathType Leaf -IsValid))
{
    throw ('The prefix "{0}" was invalid. The prefix requires a text that can be used as part of file path.' -f $FilePrefix)
}

#
# Network capturing loop.
#

Write-Host -Object ''
Write-Host -Object 'Ctrl+C to finish capture manually.' -ForegroundColor Cyan -BackgroundColor Black
Write-Host -Object ''

$traceFileCount = 0

while(1)
{
    try
    {
        # Build the trace file path.
        $traceFilePath = Join-Path -Path $SaveFolderPath -ChildPath (Get-TraceFileName -Prefix $FilePrefix -FileCount $traceFileCount)

        Write-Verbose -Message ('Current trace file: {0}' -f $traceFilePath)

        # Start a new tracing session.
        $result = Start-NetworkTrace -TraceFileSavePath $traceFilePath
        if ($result.ExitCode -eq 0)
        {
            Write-Verbose -Message $result.StdOut
        }
        else
        {
            Write-Error -Message $result.StdErr
        }

        Write-Verbose -Message ('Wait for passed the file switch interval ({0} seconds).' -f $FileSwitchInterval)
        Start-Sleep -Seconds $FileSwitchInterval

        $traceFileCount++
    }
    finally
    {
        # Stop the tracing session.
        $result = Stop-NetworkTrace
        if ($result.ExitCode -eq 0)
        {
            Write-Verbose -Message $result.StdOut
        }
        else
        {
            Write-Error -Message $result.StdErr
        }
    }
}
