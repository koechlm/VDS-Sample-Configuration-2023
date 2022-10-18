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

$mId = Get-Content "$($env:appdata)\Autodesk\DataStandard 2023\mECOTabClick.txt"

$dialog = $dsCommands.GetEditCustomObjectDialog($mId)

#show the custom object edit dialog
$result = $dialog.Execute()