param(
    [Parameter(Mandatory)] [string] $Prefix,
    [Parameter(Mandatory)] [string] $FileHost,
    [Parameter(Mandatory)] [string] $ShareName,
    [Parameter(Mandatory)] [string] $StorageAccountName,
    [Parameter(Mandatory)] [string] $StorageAccountKey,
    [Parameter(Mandatory)] [string] $SessionHostNames,
    [Parameter(Mandatory)] [string] $MgmtVmName,
    [string] $BlockClipboard = '1',
    [string] $BlockDrives = '1'
)
$ErrorActionPreference = 'Stop'
Start-Transcript -Path 'C:\Windows\Temp\Configure-CSG.log' -Append
Import-Module ActiveDirectory, GroupPolicy

$domain   = Get-ADDomain
$domainDN = $domain.DistinguishedName
$unc      = "\\$FileHost\$ShareName"

# ============ Section 14: OU structure ============
function Set-OU([string]$Name, [string]$Path) {
    $dn = "OU=$Name,$Path"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Output "Created OU $dn"
    }
    return $dn
}
$rootOU  = Set-OU 'Contractor Secure Gateway' $domainDN
$hostsOU = Set-OU 'AVD Session Hosts' $rootOU
$mgmtOU  = Set-OU 'Management Servers' $rootOU
Set-OU 'Service Accounts' $rootOU | Out-Null
Set-OU 'User Groups' $rootOU | Out-Null

function Move-Computer([string]$Name, [string]$TargetOU) {
    $c = Get-ADComputer -Identity $Name
    if ($c.DistinguishedName -notlike "*,$TargetOU") {
        Move-ADObject -Identity $c.DistinguishedName -TargetPath $TargetOU
        Write-Output "Moved $Name to $TargetOU"
    }
}
foreach ($h in $SessionHostNames.Split(',')) { Move-Computer $h $hostsOU }
Move-Computer $MgmtVmName $mgmtOU

# ============ Section 10: NTFS permissions on the share ============
# Groups are resolved to SIDs, so ACLs don't depend on sAMAccountName format.
$fslogixGroup = Get-ADGroup -Filter "Name -eq 'FSLogix - $Prefix Users'"
$dcAdmins     = Get-ADGroup -Filter "Name -eq 'AAD DC Administrators'"
if (-not $fslogixGroup -or -not $dcAdmins) { throw 'FSLogix or AAD DC Administrators group not found in the managed domain yet (sync can take up to an hour).' }

& net use Y: /delete /y 2>$null | Out-Null
& net use Y: $unc "/user:localhost\$StorageAccountName" $StorageAccountKey | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not map $unc with the storage key." }
try {
    & icacls Y:\ /grant 'CREATOR OWNER:(OI)(CI)(IO)(F)'
    & icacls Y:\ /grant 'SYSTEM:(OI)(CI)(F)'
    & icacls Y:\ /grant "*$($dcAdmins.SID.Value):(OI)(CI)(F)"
    & icacls Y:\ /grant "*$($fslogixGroup.SID.Value):(M)"
    & icacls Y:\ /remove 'Authenticated Users'
    & icacls Y:\ /remove 'Builtin\Users'
    & icacls Y:\
} finally {
    & net use Y: /delete /y | Out-Null
}

# ============ Section 15: baseline GPOs, linked to AVD Session Hosts ============
function Set-LinkedGPO([string]$Name) {
    $g = Get-GPO -Name $Name -ErrorAction SilentlyContinue
    if (-not $g) { $g = New-GPO -Name $Name; Write-Output "Created GPO $Name" }
    $links = (Get-GPInheritance -Target $hostsOU).GpoLinks | ForEach-Object DisplayName
    if ($links -notcontains $Name) { New-GPLink -Name $Name -Target $hostsOU | Out-Null }
    return $Name
}
function Set-Reg([string]$Gpo, [string]$Key, [string]$Value, [string]$Type, $Data) {
    Set-GPRegistryValue -Name $Gpo -Key $Key -ValueName $Value -Type $Type -Value $Data | Out-Null
}

# ---- Section 16: FSLogix ----
$g = Set-LinkedGPO "$Prefix - AVD - FSLogix"
$k = 'HKLM\SOFTWARE\FSLogix\Profiles'
Set-Reg $g $k 'Enabled' DWord 1
Set-Reg $g $k 'VHDLocations' MultiString $unc
Set-Reg $g $k 'VolumeType' String 'VHDX'
Set-Reg $g $k 'IsDynamic' DWord 1
Set-Reg $g $k 'FlipFlopProfileDirectoryName' DWord 1
Set-Reg $g $k 'DeleteLocalProfileWhenVHDShouldApply' DWord 1
Set-Reg $g $k 'SizeInMBs' DWord 30000

# ---- Section 17.1: session limits ----
$g  = Set-LinkedGPO "$Prefix - AVD - Session Limits"
$ts = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
Set-Reg $g $ts 'MaxDisconnectionTime' DWord 900000   # 15 min, in ms
Set-Reg $g $ts 'MaxIdleTime' DWord 1800000           # 30 min
Set-Reg $g $ts 'fResetBroken' DWord 1                # end session at limit

# ---- Sections 17.2 and 17.5: drives and redirection ----
$g = Set-LinkedGPO "$Prefix - AVD - Drive and Redirection Restrictions"
Set-Reg $g $ts 'fDisableCdm' DWord ([int]$BlockDrives)
Set-Reg $g $ts 'fDisableClip' DWord ([int]$BlockClipboard)
Set-Reg $g $ts 'fDisableCcm' DWord 1
Set-Reg $g $ts 'fDisableLPT' DWord 1
Set-Reg $g $ts 'fDisablePNPRedir' DWord 1
$ex = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
Set-Reg $g $ex 'NoDrives' DWord 67108863       # hide all drives A-Z
Set-Reg $g $ex 'NoViewOnDrive' DWord 67108863  # block access to all drives

# ---- Sections 17.3 and 17.4: lockdown + loopback ----
$g = Set-LinkedGPO "$Prefix - AVD - Start Menu and Control Panel Lockdown"
# Loopback (Merge) so these User settings apply on the session host OU
Set-Reg $g 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'UserPolicyMode' DWord 1
Set-Reg $g $ex 'NoControlPanel' DWord 1
Set-Reg $g 'HKCU\Software\Policies\Microsoft\Windows\System' 'DisableCMD' DWord 2   # prompt off, scripts allowed
Set-Reg $g 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'DisableRegistryTools' DWord 1

# ---- Created and linked, settings to be defined (guide gives purpose only) ----
Set-LinkedGPO "$Prefix - AVD - Security Baseline" | Out-Null
Set-LinkedGPO "$Prefix - AVD - Browser Settings" | Out-Null

Get-GPInheritance -Target $hostsOU | Select-Object -ExpandProperty GpoLinks | Format-Table DisplayName, Enabled, Order
Write-Output 'Configure-CSG complete.'
Stop-Transcript
