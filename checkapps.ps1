# James - 2020, 
# This script just output some permission-sets of the Azure apps.

param ([string] $file="outputRolesnOath.csv", [string] $permissionFile="outputPermissions.csv")

$delimiter = "|"
$delimiter2 = ","


# Check Azure connection (TODO: error handle this)
try 
{
    $strDetails = Get-AzureADTenantDetail
} 
catch 
{
    write-host "[-] Please connect to Azure AD first..."
    Connect-AzureAD

    try 
    {
        $strDetails = Get-AzureADTenantDetail
    } 
    catch 
    {
        write-host "[-] Error... hmmm... guess something else is wrong..."
        return
    }
}


# Open file for output
$swOut = new-object System.IO.StreamWriter( $file)

# Fetch apps
$allApps = get-azureadapplication -All $true

# Write columns
$columns = "DisplayName", "ObjectId", "AvailableToOtherTenants","SignInAudience","PublicClient","IsDisabled","AllowGuestsSignIn","ObjectType","IdentifierUris","AppRoles", "Oauth2Permissions","AssignedAppRoles"

foreach($strColumn in $columns)
{
    $swOut.Write("$strColumn$delimiter")
}

$swOut.WriteLine()

# Go through all apps
foreach($app in $allApps)
{
    $strInfo = $app.DisplayName + $delimiter + $app.ObjectId + $delimiter + $app.AvailableToOtherTenants + $delimiter + $app.SignInAudience + $delimiter + $app.PublicClient + $delimiter + ` 
    $app.IsDisabled + $delimiter + $app.AllowGuestsSignIn + $delimiter + $app.ObjectType + $delimiter + [System.String]::Join(",",$app.IdentifierUris.ToArray()) `
    + $delimiter 

    $strAppRoles = "";

    foreach($appRole in $app.AppRoles)
    {
        $strAppRoles += $appRole.DisplayName + $delimiter2 + $appRole.IsEnabled + $delimiter2 + $appRole.Value
    }

    $strOauth2Permissions = "";

    foreach($oauthPerm in $app.Oauth2Permissions)
    {
        $strOauth2Permissions += "[" + $oauthPerm.Type + $delimiter2 + $oauthPerm.UserConsentDescription + $delimiter2 + $oauthPerm.AdminConsentDescription + "]"
    }

    $strInfo += $strAppRoles
    $strInfo += $delimiter
    $strInfo += $strOauth2Permissions

    $strAppAssignments = ""
    $strDisplay = "displayName eq '" + $app.DisplayName +"'"
    $appServicePrinciple = Get-AzureADServicePrincipal -All $true -Filter $strDisplay

    foreach($strObjectId in $appServicePrinciple.ObjectId)
    {

        $appAssignments = Get-AzureADServiceAppRoleAssignedTo -All $true -ObjectId $strObjectId

        if($appAssignments -ne $null)
        {
            foreach($appAssignment in $appAssignments)
            {
                $strAppAssignments += "["+ $appAssignment.ResourceDisplayName + ":" + $appAssignment.CreationTimeStamp + "]" + ","
            }

            #write-host $strAppAssignments
        }
    }

    $strFinished =  "$strInfo$delimiter$strAppAssignments"

    write-host $strFinished

    $swOut.WriteLine($strFinished);
}

# Cleanup
$swOut.Close()



### --- Part 2 - Permissions for specific resources
$swOut = new-object System.IO.StreamWriter( $permissionFile)

$applications = Get-AzureADServicePrincipal -All $true | Where-Object {$_.ServicePrincipalType.ToLower().IndexOf("application") -ge 0}

foreach ($sApp in $applications) 
{
	$resources = Get-AzureADServiceAppRoleAssignedTo -ObjectId $sApp.ObjectId 
	
	foreach ($obj in $resources)
	{
		for ($i=0; $i -lt ($applications).AppRoles.Count; $i++)
		{
			if (($applications).AppRoles[$i].Id -eq $obj.Id) 
			{
				$strOutput =  $obj.PrincipalDisplayName+"|"+$obj.ResourceDisplayName+"|"+$obj.PrincipalId +"|" +$appRoles[$i].Value      
                write-host $strOutput       
                   
                $swOut.WriteLine($strOutput)    
			}
		}
	}
}

$swOut.Close()
