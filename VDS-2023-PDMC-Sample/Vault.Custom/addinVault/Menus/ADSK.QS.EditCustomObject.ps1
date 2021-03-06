$vaultContext.ForceRefresh = $true
$id=$vaultContext.CurrentSelectionSet[0].Id

$dialog = $dsCommands.GetEditCustomObjectDialog($id) #loads the default. 

#override the default dialog file assigned
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.CustomObject.xaml", "C:\ProgramData\Autodesk\Vault 2023\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObject.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
#$dsDiag.Trace($result)

if($result)
{
	$custent = $vault.CustomEntityService.GetCustomEntitiesByIds(@($id))[0]
	$cat = $vault.CategoryService.GetCategoryById($custent.Cat.CatId)
	switch($cat.Name)
	{
		"Person"
		{
			$mN1 = mGetCustentPropValue $custent.Id "First Name"
			$mN2 = mGetCustentPropValue $custent.Id "Last Name"
			$updatedCustent = $vault.CustomEntityService.UpdateCustomEntity($custent.Id, "$($mN1) $($mN2)")
		}
	}
}