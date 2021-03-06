Import-Module grouppolicy

# WARNING
#   Use this script with caution!


# PARAMETERS
#   if your domain is intranet.entreprise the dc should
#   be "dc=intranet,dc=entreprise"
$dc = "dc=intranet,dc=entreprise"
$testingOU = "ou=TestingOU"

Clear-Host

# Ask for path
$path = Read-Host "OU Path without domain (ex: Managed/Laptops/VIP): "

$path = $path.Split("/")
[Array]::Reverse($path)
ForEach ($ou in $path) {
    $CS += "ou=" + $ou + ","
}

$originCS = $CS + $dc
$destinationCS = $CS + $testingOU + "," + $dc

Write-Host "All the links from " $destinationCS
Write-Host "will be overwritten with the ones from " $originCS
$confirm = Read-Host "Are you sure? (y/n): "

if ($confirm -eq "y") {
    if (-Not ([adsi]::Exists("LDAP://"+$originCS))) {
        Write-Warning "Origin OU does not exist - No changes made"
        Break
    }
    if (-Not ([adsi]::Exists("LDAP://"+$destinationCS))) {
        Write-Warning "Destination OU does not exist - No changes made"
        Break
    }
    $destGPOs = Get-GPInheritance -target $destinationCS
    ForEach($gpo in $destGPOs.GpoLinks) {
        $temp = Remove-GPLink -guid $gpo.GpoId -target $destinationCS
    }

    $newLinks = 0
    $originGPOs = Get-GPInheritance -target $originCS
    ForEach($gpo in $originGPOs.InheritedGpoLinks) {
        $temp = New-GPLink -guid $gpo.GpoId -target $destinationCS
        $newLinks++
    }
    Write-Host "Success: $newLinks new links created in " $destinationCS
    Write-Host ""
} else {
    Write-Host "No changes done"
}
