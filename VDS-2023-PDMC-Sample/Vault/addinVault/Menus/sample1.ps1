
$s=$vaultContext.CurrentSelectionSet[0].TypeId

[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowMessage($s, "VDS Sample Configuration", "OK")

$s1=$vaultContext.CurrentSelectionSet[0]|gm
$dsDiag.Trace($s1)

# you can tell the property grid to highlight
# a variable you want to inspect
# here it's the $location
# The variable name must be enclosed in single quotes!

$dsDiag.inspect('$location')