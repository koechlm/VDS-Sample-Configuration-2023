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

Add-Type @'
public class mAssocCustent
{
	public string icon;
	public string name;
	public string title;
	public string description;
	public string owner;
	public string datestart;
	public string status;
	public string priority;
	public string dateend;
	public string comments;
}
'@

function mGetAssocCustents($mIds)
{
	#$dsDiag.Trace(">> Starting mGetAssocCustents($mIds)")
	$mCustEntities = $vault.CustomEntityService.GetCustomEntitiesByIds($mIds)
	$PropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}
	$mAssocCustents = @()
	
	$mCustEntities | ForEach-Object { 
		$mCustEntProps = $vault.PropertyService.GetProperties("CUSTENT",@($_.Id),$propDefIds)
		$mAssocCustEnt = New-Object mAssocCustent
		
		#set custom icon
		$iconLocation = $([System.IO.Path]::GetDirectoryName($VaultContext.UserControl.XamlFile))
		$mIconpath = [System.IO.Path]::Combine($iconLocation,"Icons\task.ico")
		$exists = Test-Path $mIconPath
		$mAssocCustEnt.icon = $mIconPath
		
		#set system properties name, title, description
		$mAssocCustEnt.name = $_.Name
		$mtitledef = $PropDefs | Where-Object { $_.SysName -eq "Title"}
		$mtitleprop = $mCustEntProps | Where-Object { $_.PropDefId -eq $mtitledef.Id}
		$mAssocCustEnt.title = $mtitleprop.Val
		$mdescriptiondef = $PropDefs | Where-Object { $_.SysName -eq "Description"}
		$mdescriptionprop = $mCustEntProps | Where-Object { $_.PropDefId -eq $mdescriptiondef.Id}
		$mAssocCustEnt.description = $mdescriptionprop.Val
		
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-02"]} #date start
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		IF ($mUdpProp.Val -gt 0) { $mUdpProp.Val = $mUdpProp.Val.ToString("d")}
		$mAssocCustEnt.datestart = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-03"]} #date end
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		IF ($mUdpProp.Val -gt 0) { $mUdpProp.Val = $mUdpProp.Val.ToString("d")}
		$mAssocCustEnt.dateend = $mUdpProp.Val
		#set user def properties 
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-04"]} #owner
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.owner = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-LnkdTask-05"]} #priority
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.priority = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["LBL7"]} #comments
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.comments = $mUdpProp.Val

		#add the filled entity
		$mAssocCustents += $mAssocCustEnt
	}
	return $mAssocCustents

}

function mTaskClick()
{
	$mSelItem = $dsWindow.FindName("dataGrdLinks").SelectedItem
    $mOutFile = "mECOTabClick.txt"
	foreach($mItem in $mSelItem)
	{
		$mItem.Name | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\$($mOutFile)"
	}
}
