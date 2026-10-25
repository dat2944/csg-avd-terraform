param(
    [Parameter(Mandatory)] [string] $RegistrationToken
)
$ErrorActionPreference = 'Stop'
Start-Transcript -Path 'C:\Windows\Temp\Install-AVDAgent.log' -Append

# Skip if already registered (re-runs are safe)
if (Get-Service -Name RDAgentBootLoader -ErrorAction SilentlyContinue) {
    Write-Output 'AVD agent already installed.'
    Stop-Transcript; exit 0
}

New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null
# Microsoft download links for the agent and bootloader (verify against
# "Add session hosts to a host pool" on Microsoft Learn if they stop resolving)
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2310011' -OutFile 'C:\Temp\RDAgent.msi' -UseBasicParsing
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2311028' -OutFile 'C:\Temp\RDAgentBootLoader.msi' -UseBasicParsing

$p = Start-Process msiexec.exe -ArgumentList "/i C:\Temp\RDAgent.msi /quiet /norestart REGISTRATIONTOKEN=$RegistrationToken" -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "RDAgent install failed: $($p.ExitCode)" }
$p = Start-Process msiexec.exe -ArgumentList '/i C:\Temp\RDAgentBootLoader.msi /quiet /norestart' -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "Bootloader install failed: $($p.ExitCode)" }

Get-Service RDAgentBootLoader, RDAgent | Format-Table Name, Status
Stop-Transcript
