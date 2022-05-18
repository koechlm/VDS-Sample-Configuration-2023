#$vaultContext.ForceRefresh = $true
$currentSelected = $vaultContext.CurrentSelectionSet[0]
$folderId = $currentSelected.Id
#if selected object is of type 'FILE' then use $vaultContext.NavSelectionSet[0].Id,
#it will give you back the folder Id where this file is located
if ($currentSelected.TypeId.EntityClassId -eq "FILE")
{
	$folderId = $vaultContext.NavSelectionSet[0].Id
}

$dialog = $dsCommands.GetCreateDialog($folderId)
##override the default dialog file assigned
#if ($_IsOfficeClient)
#{
#	$xamlFile = New-Object CreateObject.WPF.XamlFile "Adsk.QS.FileOffice.xaml", "C:\ProgramData\Autodesk\Vault 2023\Extensions\DataStandard\Vault.Custom\Configuration\Adsk.QS.FileOffice.xaml"
#	$dialog.XamlFile = $xamlFile
#}
#else
#{
#	$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.File.xaml", "C:\ProgramData\Autodesk\Vault 2023\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.File.xaml"
#	$dialog.XamlFile = $xamlFile
#}

#differentiation of Office moved to PowerShell, GetTemplateFolders in *Default.ps1
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.File.xaml", "C:\ProgramData\Autodesk\Vault 2023\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.File.xaml"
$dialog.XamlFile = $xamlFile

#new file can be found in $dialog.CurrentFile
$result = $dialog.Execute()

if ($result)
{
	$folder = $vault.DocumentService.GetFolderById($folderId)
	$path=$folder.FullName+"/"+$dialog.CurrentFile.Name

	$selectionId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::File
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionId, $path
	$vaultContext.GoToLocation = $location
}