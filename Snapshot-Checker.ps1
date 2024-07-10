param(
    [Parameter(Mandatory=$true, HelpMessage="IP or FQDN of the vCenter Server")]
    [string]$VIHost,
    
    [Parameter(Mandatory=$true, HelpMessage="User credential for the vCenter Server")]
    [string]$VIUser,
    
    [Parameter(Mandatory=$true, HelpMessage="Password credential for the vCenter Server")]
    [string]$VIPassword,

    [Parameter(Mandatory=$true, HelpMessage="String for acknowledged snapshots -> warning")]
    [string]$SsDIs
)

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$null = Disconnect-VIServer -Confirm:$false
Connect-VIServer -Server $VIHost -User $VIUser -Password $VIPassword

$vms_w_ss = Get-VM | Get-Snapshot | Where {$_.Description -notmatch $SsDIs}
$vms_w_ss_d = Get-vm | Get-Snapshot | Where {$_.Description -match $SsDIs}
$vms = Get-VM | Select Name

$result_main = 0
$return_msg = @()

For ($i=0; $i -lt $vms.Length; $i++) {
    $value = 0
    $x = $vms[$i].Name -replace '\s',''
    For ($c=0; $c -lt $vms_w_ss_d.Length; $c++) {
        $y = $vms_w_ss_d[$c].VM -replace '\s',''
        If ($x -eq $y) {
            $value = 2
            If ($result_main -lt 3) {
                $result_main = 2
            }
        }
    }
    For ($r=0; $r -lt $vms_w_ss.Length; $r++) {
        $y = $vms_w_ss[$r].VM -replace '\s',''
        If ($x -eq $y) {
            $value = 3
            $result_main = 3
        }
    }

    $VMName = $vms[$i].Name 
    $return_msg += "<result><channel>$VMName Snapshots</channel><value>$value</value><LimitMaxWarning>1</LimitMaxWarning><LimitWarningMsg>Acknowledged Snapshot></LimitWarningMsg><LimitMaxError>2</LimitMaxError><LimitErrorMsg>Unacknowledged Snapshot</LimitErrorMsg><LimitMode>1</LimitMode></result>"
}

Write-Host
    '<prtg>'
    '<result>'
    '<channel>VM Snapshots</channel>'
    "<value>$result_main</value>"
    '<LimitMaxWarning>1</LimitMaxWarning>'
    '<LimitWarningMsg>Atleast one VM with existing Snapshot></LimitWarningMsg>'
    '<LimitMaxError>2</LimitMaxError>'
    '<LimitErrorMsg>Atleast one VM with existing Snapshot</LimitErrorMsg>'
    '<LimitMode>1</LimitMode>'
    '</result>'

For ($a=0; $a -lt $return_msg.Length; $a++) {
    Write-Host $return_msg[$a]
}

Write-Host '</prtg>'
