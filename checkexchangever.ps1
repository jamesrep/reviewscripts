# James Dickson - 2021
# Instead of using the Get-ExchangeServer EMC-command, this uses the registry key (simpler to run by remote).
# Example: checkexchangever.ps1 -computername "jamesExchange1,exchangeserver2,lastone"
param($computername="localhost")

$strNames = $computername.Split(",")

foreach($strName in $strNames)
{	
	# List of known registry key-versions for different exchange-versions (2007,2013,2016 and 2019)
    $strVersionList = "AE1D439464EB1B8488741FFA028E291C","461C2B4266EDEF444B864AD6D9E5B613", "442189DC8B9EA5040962A6BED9EC1F1F"
	$bFound = $false
	
    foreach($strV in $strVersionList)
    {
        $strRemoteCommand = "reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\$strV\InstallProperties /v DisplayVersion"
        $scriptBlock = [Scriptblock]::Create($strRemoteCommand)

        $rversion  = Invoke-Command -ComputerName $strName -ScriptBlock $scriptBlock -ErrorAction SilentlyContinue

        if($rversion -ne $null)
        {
            $strVersion = $rversion[2]
            write-host "[+] Found: $strName - $strVersion"
			$bFound = $true # continuing anyway since we may have several installs?
        }
    }
	
	if($bFound -ne $true)
	{
		write-host "[-] Could not determine version of: $strName"
	}
}
