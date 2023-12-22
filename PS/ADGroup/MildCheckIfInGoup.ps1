Import-Module ActiveDirectory
$domainController = "europe.mittalco.com"
$userName = "633200" # Username/AMEI/Normal search stuff
$groupName = "AMLG-LOCAL-EUROPE.MITTALCO.COM_FLAT-SPE_F1-NOEXO" # Group name in DC
$hasGroup = 0
$appendExtraLetters = "Y","P","U","A"

foreach($line in Get-Content .\file.txt) 
{
    if ($line.Length -lt 7)
    {
        $line = "0" + $line
    }
	
	ForEach ($a in $appendExtraLetters)
	{
		$temp = $a + $line
		$user = Get-ADUser -Filter {SamAccountName -eq $temp} -Server $domainController
		
		if ($user)
		{
			Write-Host " "
			Write-Host "User $user found:"
			break
		}

	}
	
    if ($user) 
    {
            # Get the groups
            $groups = (Get-Aduser $user -Server $domainController -Properties MemberOf | Select MemberOf).MemberOf
            # Loop for contains
            foreach ($group in $groups)
            {
				Write-Host "	- $group"

                #if ($group.Contains("AMLG"))
                #{
                #    $hasGroup = 1
                #    $groupToRemove = $group.Substring(3,$group.IndexOf(",")-3)
				#	Write-Host "Removing group $groupToRemove from $username"
                    #Remove-ADGroupMember -Identity $groupToRemove -Members $user -Server $domainController
                    #break
                #}
            }

            if (-not $hasGroup)
            {
                # Add the user to the group, hopefully
                Add-ADGroupMember -Identity $groupName -Members $user
                Write-Host "User $temp added to group $groupName."
            }
            else
            {
                Write-Host "$temp already in group $groupName"
            }
    } 
    else 
    {
        Write-Host "User $temp does not exist."
    }
}