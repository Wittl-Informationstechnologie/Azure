#    Vaiablen
$ResourceGroup
$ResourceGroupLocation = "westeurope"

#   Start
Connect-AzAccount
New-AzResourceGroup `
    -Name $ResourceGroup `
    -Location $ResourceGroupLocation