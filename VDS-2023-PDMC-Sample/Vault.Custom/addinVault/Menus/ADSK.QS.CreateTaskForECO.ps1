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

#register the current CO context
$vaultContext.ForceRefresh = $true
$selectionSet = $vaultContext.CurrentSelectionSet[0]
$mCoId= $selectionSet.Id

#create a new task, add a link from current CO to it and open for edit
$CustEntSrvc = $vault.CustomEntityService
$mEntityDefs = $CustEntSrvc.GetAllCustomEntityDefinitions()
$mEntDefId = ($mEntityDefs | Where-Object {$_.DispName -eq "Task" }).Id

#create a numbered name for the new task
[System.Collections.ArrayList]$numSchems = @($vault.NumberingService.GetNumberingSchemes('FILE', 'Activated'))
$ns = $numSchems | Where-Object { $_.Name.Equals("ECO-Task") }
if ($ns -ne $null)
{
	$NumGenArgs = @($selectionSet.Label)
	$mTaskName = $vault.DocumentService.GenerateFileNumber($ns.SchmID, $NumGenArgs)
}
else
{
	$mTaskName = "ECO-Task" #create new number consuming numbering scheme "ECO-Task" if found
}

[Autodesk.Connectivity.WebServices.CustEnt]$task = $CustEntSrvc.AddCustomEntity($mEntDefId, $mTaskName)
$link = $vault.DocumentService.AddLink($task.Id, "CO", $mCoId, "Parent->Child")

$dialog = $dsCommands.GetEditCustomObjectDialog($task.id)

#show the custom object edit dialog
$result = $dialog.Execute()





