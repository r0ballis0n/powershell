Import-Module ActiveDirectory
$usersToChange = Get-ADUser -SearchBase “ou=OU,dc=local,dc=domain” -filter *
# Grabs all the users you want and puts them in an array
 
foreach ($user in $usersToChange) {
 
### Get the samaccount name
 
$oldLogon = Get-AdUser -identity $user.SamAccountName -Properties * | Select-Object -Expand SamAccountName;
 
### Get the emailaddress
$logonemail = Get-AdUser -identity $user.SamAccountName -Properties * | Select-Object -Expand Emailaddress;
 
### New logon will be the emailaddress
$newlogon = $logonemail.Tolower().Split("@")[0];
 
Get-ADUser -identity $oldlogon | Set-AdUser -Replace @{userPrincipalName = $logonemail};
Get-ADUser -identity $user.SamAccountName | Set-AdUser -Replace @{samaccountname = $newLogon};
}