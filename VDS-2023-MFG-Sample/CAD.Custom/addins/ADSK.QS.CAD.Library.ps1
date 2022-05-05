#region disclaimer
	#===============================================================================
	# PowerShell script sample														
	# Author: Markus Koechl															
	# Copyright (c) Autodesk 2020													
	#																				
	# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER     
	# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES   
	# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.    
	#===============================================================================
#endregion

#region - version history
#Version Info - VDS-MFG/PDMC-Sample CAD Library 2023
	# migrated paths to 2023

#Version Info - VDS-MFG-Sample CAD Library 2022
	# migrated paths to 2022

#Version Info - VDS Quickstart CAD Library 2021.0.1
	# fixed issue for files in temp folders in function mGetProjectFolderPropToCadFile

#Version Info - VDS Quickstart CAD Library 2021
	# migrated paths to 2021

#Version Info - VDS quickstart CAD Library 2019.1.1
	# added and updated mGetProjectFolderToCADFile function; supports AutoCAD without IPJ settings enforeced.
	# added mGetPropTranslations, fixed failure in getting default language for DB if not set in DSLanguages

#Version Info - VDS quickstart CAD Library 2019.1.0
	# added mGetProjectFolderPropToCadFile

# Version Info - VDS Quickstart CAD Library 2019.0.0
	# initial release - mGetFolderPropValue function added

#endregion

#retrieve property value given by displayname from folder (ID)
function mGetFolderPropValue ([Int64] $mFldID, [STRING] $mDispName)
{
	$PropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FLDR")
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	} 
	$mPropDef = $propDefs | Where-Object { $_.DispName -eq $mDispName}
	$mEntIDs = @()
	$mEntIDs += $mFldID
	$mPropDefIDs = @()
	$mPropDefIDs += $mPropDef.Id
	$mProp = $vault.PropertyService.GetProperties("FLDR",$mEntIDs, $mPropDefIDs)
	$mProp | Where-Object { $mPropVal = $_.Val }
	Return $mPropVal
}

function mGetProjectFolderPropToCADFile ([String] $mFolderSourcePropertyName, [String] $mCadFileTargetPropertyName)
{
	#does the target property to write to exist?
	if(-not $Prop[$mCadFileTargetPropertyName])
	{
		return 
	}

	#get the Vault path of Inventors working folder
	$mappedRootPath = $Prop["_VaultVirtualPath"].Value + $Prop["_WorkspacePath"].Value
    $mappedRootPath = $mappedRootPath -replace "\\", "/" -replace "//", "/"
    if ($mappedRootPath -eq '')
    {
        $mappedRootPath = '$/'
    }
	#$dsDiag.Trace("mapped root: $($mappedRootPath)")
	$mWfVault = $mappedRootPath
					
	#get local path of vault workspace path for Inventor
	If($dsWindow.Name -eq "InventorWindow"){
		$mCAxRoot = $mappedRootPath.Split("/.")[1]
	}
	if ($dsWindow.Name -eq "AutoCADWindow") {
		$mCAxRoot = ""
	}

	if($vault.DocumentService.GetEnforceWorkingFolder() -eq "true") {
		$mWF = $vault.DocumentService.GetRequiredWorkingFolderLocation()
	}
	else {
		[System.Windows.MessageBox]::Show("Copy Project Property Expects Enforced Working Folder & IPJ!" , "Inventor VDS Client")
		return
	}
		
	try {
		#$dsDiag.Trace("mWF: $mWF")
		$mWFCAD = $mWF + $mCAxRoot
		#avoid for temporary files
		if($Prop["_FilePath"].Value -notcontains $mWFCAD)
		{
			$Prop[$mCadFileTargetPropertyName].Value = ""
			return
		}
		#merge the local path and relative target path of new file in vault
		$mPath = $Prop["_FilePath"].Value.Replace($mWFCAD, "")
		$mPath = $mWfVault + $mPath
		$mPath = $mPath.Replace(".\","")
		$mPath = $mPath.Replace("\", "/")
		$mFld = $vault.DocumentService.GetFolderByPath($mPath)
		#the loop to get the next parent project category folder; skip if you don't look for projects
		IF ($mFld.Cat.CatName -eq $UIString["CAT6"]) { $mProjectFound = $true}
		ElseIf ($mPath -ne "$/"){
			Do {
				$mParID = $mFld.ParID
				$mFld = $vault.DocumentService.GetFolderByID($mParID)
				IF ($mFld.Cat.CatName -eq $UIString["CAT6"]) { $mProjectFound = $true}
			} 
			Until (($mFld.Cat.CatName -eq $UIString["CAT6"]) -or ($mFld.FullName -eq "$"))
		}	
	}
	catch { 
		[System.Windows.MessageBox]::Show("Failed retreiving the target Vault folder's path of this new file" , "Inventor VDS Client")
	}			
			
	If ($mProjectFound -eq $true) {
		#Project's property Value copied to CAD file property
		$Prop[$mCadFileTargetPropertyName].Value = mGetFolderPropValue $mFld.Id $mFolderSourcePropertyName
	}
	Else{
		#empty field value if file will not link to a project
		$Prop[$mCadFileTargetPropertyName].Value = ""
	}
}

# VDS Dialogs and Tabs share property name translations $Prop[_XLTN_*] according DSLanguage.xml override or default powerShell UI culture;
# VDS MenuCommand scripts don't read as a default; call this function in case $UIString[] key value pairs are needed
function mGetPropTranslations
{
	# check language override settings of VDS
	[xml]$mDSLangFile = Get-Content "C:\ProgramData\Autodesk\Vault 2023\Extensions\DataStandard\Vault\DSLanguages.xml"
	$mUICodes = $mDSLangFile.SelectNodes("/DSLanguages/Language_Code")
	$mLCode = @{}
	Foreach ($xmlAttr in $mUICodes)
	{
		$mKey = $xmlAttr.ID
		$mValue = $xmlAttr.InnerXML
		$mLCode.Add($mKey, $mValue)
	}
	#If override exists, apply it, else continue with $PSUICulture
	If ($mLCode["DB"]){
		$mVdsDb = $mLCode["DB"]
	} 
	Else{
		$mVdsDb=$PSUICulture
	}
	[xml]$mPrpTrnsltnFile = get-content ("C:\ProgramData\Autodesk\Vault 2023\Extensions\DataStandard\" + $mVdsDb + "\PropertyTranslations.xml")
	$mPrpTrnsltns = @{}
	$xmlPrpTrnsltns = $mPrpTrnsltnFile.SelectNodes("/PropertyTranslations/PropertyTranslation")
	Foreach ($xmlAttr in $xmlPrpTrnsltns) {
		$mKey = $xmlAttr.Name
		$mValue = $xmlAttr.InnerXML
		$mPrpTrnsltns.Add($mKey, $mValue)
		}
	return $mPrpTrnsltns
}