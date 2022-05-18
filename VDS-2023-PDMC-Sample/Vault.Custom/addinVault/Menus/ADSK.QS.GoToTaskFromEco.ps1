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

#an ECO likely links multiple tasks; the user needs to select one from the list; the selection writes the txt file
$mTargetObject = Get-Content "$($env:appdata)\Autodesk\DataStandard 2022\mECOTabClick.txt"

	$srchCondAll = @()		
	$mSearchString = "FLC-Task"
		
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	$propDef = $propDefs | Where-Object { $_.DispName -eq "Category Name" }
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = $mSearchString
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchCondAll += $srchCond
	
	$mSearchString = "$mTargetObject"
	$srchCond2 = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDef = $propDefs | Where-Object { $_.DispName -eq "Name" }
	$srchCond2.PropDefId = $propDef.Id
	$srchCond2.SrchOper = 3
	$srchCond2.SrchTxt = $mSearchString
	$srchCond2.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond2.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchCondAll += $srchCond2

	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""     
	$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'
	
		while(($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits))
		{
			 $mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchCondAll, @($srchSort),[ref]$bookmark,[ref]$searchStatus)
			
			If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent")
			{
				#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
			}
			if($mResultPage.Count -ne 0)
			{
				$mResultAll.AddRange($mResultPage)
			}
			else { break;}
				
			break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
		}

#identify custom object definition and unique (system name)
$custentNumber = $mResultPage[0].Num
$custentDefId = $mResultPage[0].CustEntDefId
$custentName = ($vault.CustomEntityService.GetAllCustomEntityDefinitions() | Where-Object { $_.Id -eq $custentDefId}).Name

#custom objects don't have a pre-defined selectiontypeID, so lets create one
$selectionTypeId = New-Object Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId($custentName)
$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $custentNumber
$vaultContext.GoToLocation = $location

#clean-up selection
	$mSelItem = $null
    $mOutFile = "mECOTabClick.txt"
	
	$mSelItem | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\$($mOutFile)"
	