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

$entityId=$vaultContext.CurrentSelectionSet[0].Id

$links = $vault.DocumentService.GetLinksByParentIds(@($entityId),@("CO"))
[Autodesk.Connectivity.WebServices.ChangeOrder[]]$mECOs = $vault.ChangeOrderService.GetChangeOrdersByIds(@($links[0].ToEntId))

$path = $mECOs[0].Num
$selectionTypeId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::ChangeOrder
$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $path
$vaultContext.GoToLocation = $location

	