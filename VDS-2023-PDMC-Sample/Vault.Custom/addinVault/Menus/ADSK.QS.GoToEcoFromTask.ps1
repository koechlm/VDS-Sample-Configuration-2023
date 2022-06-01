#region disclaimer
#=============================================================================
# PowerShell script sample for Vault Data Standard                            
#                                                                             
# Copyright (c) Autodesk - All rights reserved.                               
#                                                                             
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  
#=============================================================================
#endregion

$vaultContext.ForceRefresh = $true
$entityId=$vaultContext.CurrentSelectionSet[0].Id

#	there are some custom functions to enhance functionality; 2023 version added webservice and explorer extensions to be installed optionally
$mVdsUtilities = "$($env:programdata)\Autodesk\Vault 2023\Extensions\Autodesk.VdsSampleUtilities\VdsSampleUtilities.dll"
if (! (Test-Path $mVdsUtilities)) {
	#the basic utility installation only
	[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + '\Autodesk\Vault 2023\Extensions\DataStandard\Vault.Custom\addinVault\VdsSampleUtilities.dll')
}
Else {
	#the extended utility activation
	[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + '\Autodesk\Vault 2023\Extensions\Autodesk.VdsSampleUtilities\VdsSampleUtilities.dll')
}

$_mVltHelpers = New-Object VdsSampleUtilities.VltHelpers
$links = @()
$links = $_mVltHelpers.mGetLinkedChildren1($vaultconnection, $entityId, "CUSTENT", "CO")

[Autodesk.Connectivity.WebServices.ChangeOrder[]]$mECOs = $vault.ChangeOrderService.GetChangeOrdersByIds(@($links[0]))

$path = $mECOs[0].Num
$selectionTypeId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::ChangeOrder
$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $path
#$dsDiag.Inspect("location")
$vaultContext.GoToLocation = $location

	