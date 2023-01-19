#region disclaimer =============================================================================
# PowerShell script sample for Vault Data Standard
#			 Autodesk Vault - VDS-PDMC-Sample 2022
# This sample is based on VDS 2023 RTM and adds functionality and rules
#
# Copyright (c) Autodesk - All rights reserved.
#
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
#endregion =============================================================================

#region - version history
# Version Info - VDS-PDMC-Sample Classfication 2022.1.0
	#merge IEC61355 classification support

# Version Info - VDS-PDMC-Sample Classification 2022.0.1
	#fixed issue of overlapping Initialization of DataSheet and Dialogs
	#fixed error 303 if user does not have right Custom Entity Read as a minimum

# Version Info - VDS-PDMC-Sample Classification 2022
	#removed multi-DB-language support -> support EN only, as PDMC-Sample is an en-US DB sample

# Version Info - VDS-PDMC-Sample Classification 2021
	#added condition _ReadOnly for Remove/Add Button

# Version Info - VDS-PDMC-Sample Classification 2020.0.0
	# Support default values for classes on AddClassification()
	# Use Case _CreateMode removed: an existing file is required to add class properties
	# code maintenance

# Version Info - VDS-PDMC-Sample Classification 2019.1.1
	# initial version

#endregion

function mInitializeClassificationTab($ParentType, $file)
{
	$dsWindow.FindName("txtClassificationStatus").Visibility = "Collapsed"
	$Global:mClsTabInitialized = $false

	if($Global:mClsTabInitialized -ne $true)
	{
		#$dsDiag.Trace("...not intialized yet -> Initialize classification tab.")
		#variables, that we need in any case; limit number of server calls

		$Global:mAllCustentPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		$Global:mCustentUdpDefs = $Global:mAllCustentPropDefs | Where-Object { $_.IsSys -eq $false}
		$Global:mCustentDefs = $vault.CustomEntityService.GetAllCustomEntityDefinitions()
		$Global:mClassCustentDef = $Global:mCustentDefs | Where-Object { $_.DispName -eq "Class"}
		if(-not $Global:mClassCustentDef)
		{
			$dsWindow.FindName("txtClassificationStatus").Text = $UIString["Adsk.QS.Classification_13"]
			$dsWindow.FindName("txtClassificationStatus").Visibility = "Visible"
		}
		#configuration info - the custom object names used for the classification structure may vary. Align Custent names of your Vault in UIStrings ADSK.WS.ClassLEver_*
		$mClsLevelNames = ("Segment", "Main Group", "Group","Sub Group")
		$Global:mClassLevelCustentDefIds = ($Global:mCustentDefs | Where-Object { $_.DispName -in $mClsLevelNames}).Id		
	}

	Switch($ParentType)
	{
		"Dialog"
		{
			#$dsDiag.Trace("Initialize UI Controls for Dialog starts...")

			$Global:mFile = mGetFileObject

			#activate UI controls
			if ($null -ne $dsWindow.FindName("cmbAvailableClasses")) {
				$dsWindow.FindName("cmbAvailableClasses").add_SelectionChanged({
						If ($Prop["_ReadOnly"].Value -eq $false -and $dsWindow.FindName("txtActiveClass").Text -eq "" -and $dsWindow.FindName("cmbAvailableClasses").SelectedIndex -gt -1) {
							$dsWindow.FindName("btnAssignClass").IsEnabled = $true
						}
						Else { $dsWindow.FindName("btnAssignClass").IsEnabled = $false }
					})
			}

			$dsWindow.FindName("dtgrdClassProps").add_LostFocus({
			#update property values by leaving the tab
				#$dsDiag.Trace("data grid Class Props lost focus")
				try{
						Foreach($row in $dsWindow.FindName("dtgrdClassProps").Items)
						{
							$Prop[$row.Key].Value = $row.Value
						}
				}
				catch{
					$dsDiag.Trace("Error writing class properties to file properties")
				}
			}) #lostFocus

			mAvlblClsReset
			
			if($dsWindow.FindName("wrpClassification2")){
					if($dsWindow.FindName("wrpClassification2").Children.Count -lt 1)
				{
					#activate command should not add another combo row, if already classe(s) are selected
					mAddClsLevelCombo -ClassLevelName "Segment"
				}
			}
			
			if($Prop["_XLTN_CLASS"].Value.Length -lt 1 -and $false -eq $Prop["_ReadOnly"].Value) { 
				$dsWindow.FindName("btnRemoveClass").IsEnabled = $false
				$dsWindow.FindName("btnAssignClass").IsEnabled = $true
			}
			if($Prop["_XLTN_CLASS"].Value.Length -gt 0 -and $Prop["_ReadOnly"].Value -eq $false) 
			{ 	
				$dsWindow.FindName("btnRemoveClass").IsEnabled = $true
			}
			else
			{
				$dsWindow.FindName("btnRemoveClass").IsEnabled = $false
			}

			$Global:mClsTabInitialized = $true
			#$dsDiag.Trace("...Initialize UI Controls for Dialog finished")
		}
		default #data sheet tab
		{
			#$dsDiag.Trace("Initialize Detail Tab Datasheet starts...")
			$Global:mFile = $file
			$Global:mClsTabInitialized = $true
			#$dsDiag.Trace("...Initialize Detail Tab Datasheet finished")
		}
	}

	mGetFileClsValues

	#$dsDiag.Trace("...Initialize Classification Tab ended.")
}

function mGetFileClsValues
{
	#$dsDiag.Trace(">>Function mGetFileClsValues starts...")
	$dsWindow.FindName("dtgrdClassProps").ItemsSource = $null
	$mActiveClass = @()
	$mActiveClass += mGetCustentiesByName -Name $Prop["_XLTN_CLASS"].Value #Note - custom object names are not unique, only its Number, and we need to handle returning more than one.
	if($mActiveClass.Count -eq 1)
	{
		#region get Property Ids and Displaynames for this class
		#$dsDiag.Trace("	...class object for file class property value found.")
		$mClsPrpNames = mGetClsPrpNames -ClassId $mActiveClass[0].Id
		$mClsPropTable = @{}
		$mClsLevelProps = ("Segment", "Main Group", "Group", "Sub Group", "Class")

		#get the file's class property values 
		$mFileClassProps = $vault.PropertyService.GetProperties("FILE", @($mFile.Id), $mClsPrpNames.Keys)
		Foreach($mClsProp in $mClsPrpNames.GetEnumerator())
		{
			#filter the classification property, add all others
			if($mClsPrpNames[$mClsProp.Key] -notin $mClsLevelProps)
				{
					$mClsPropTable.Add($mClsPrpNames[$mClsProp.Key], (($mFileClassProps | Where-Object { $_.PropDefId -eq ($mClsProp.Key)}).Val))
				}
		}
		#fill the grid
		$dsWindow.FindName("dtgrdClassProps").ItemsSource = $mClsPropTable
	}
	if ($mActiveClass.Count -gt 1)
	{
		#$dsDiag.Trace("	...multiple class objects for given name found.")
	}
	#$dsDiag.Trace("...Function mGetFileClsValues finished.<<")
}

function mGetClsDfltValues
{
	#$dsDiag.Trace(">>Function mGetClsDfltValues starts...")
	$mActiveClass = @()
	$mActiveClass += mGetCustentiesByName -Name $dsWindow.FindName("cmbAvailableClasses").SelectedValue
	#$dsDiag.Trace("	...active class: " + '$mActiveClass' + "read from class property")
	$mClsPrpNames = mGetClsPrpNames -ClassId $mActiveClass[0].Id
	$mClsPrpValues = mGetClsPrpValues -ClassId $mActiveClass[0].Id
	$mClsPropTable = @{}
	$mClsLevelProps = ("Segment", "Main Group", "Group","Sub Group" ,"Class")

	if($mActiveClass.Count -eq 1)
	{
		Foreach($mClsProp in $mClsPrpNames.GetEnumerator())
		{
			#filter the all classification level properties but add all class' properties
			if($mClsPrpNames[$mClsProp.Key] -notin $mClsLevelProps) { $mClsPropTable.Add($mClsPrpNames[$mClsProp.Key], $mClsPrpValues[$mClsProp.Key])}
		}
	}

	$dsWindow.FindName("dtgrdClassProps").ItemsSource = $mClsPropTable
	try{
		Foreach($row in $dsWindow.FindName("dtgrdClassProps").Items)
		{
			$Prop[$row.Key].Value = $row.Value
		}
	}
	catch{
		#$dsDiag.Trace("	...Error writing class properties to file properties")
	}
	#$dsDiag.Trace("...Function mGetClsDfltValues finsihed.<<")
}

function mGetClsPrpNames($ClassId) #get Properties added to this class
{
	$global:mClsPropInsts = @()
	$global:mClsPropInsts += $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($ClassId))
	$mClsPropNames = @{}
	ForEach($mPropInst in $mClsPropInsts)
	{
		#add UDPs of the Custom Object "Class" only
		If($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId })
		{
			$mDispName = ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId }).DispName
			$mClsPropNames.Add($mPropInst.PropDefId, $mDispName)
		}
	}
	return $mClsPropNames
}

function mGetClsPrpValues($ClassId) #get Properties added to this class
{
	$mClsPropValues = @{}
	ForEach($mPropInst in $global:mClsPropInsts)
	{
		#add UDPs of the Custom Object "Class" only
		If($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId })
		{
			$mClsPropValues.Add($mPropInst.PropDefId, $mPropInst.Val)
		}
	}
	return $mClsPropValues
}



function mGetCustentiesByName([String]$Name)
{
	$mSearchString = $Name
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	#$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	#$propDef = $propDefs | Where-Object { $_.SysName -eq "Name" }
	$propDef = $Global:mAllCustentPropDefs | Where-Object { $_.SysName -eq "Name" }
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 1 #equals
	$srchCond.SrchTxt = $mSearchString
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""
	$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'

	while(($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits))
	{
		try
		{
			$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions(@($srchCond),@($srchSort),[ref]$bookmark,[ref]$searchStatus)
		}
		catch
		{
			$dsWindow.FindName("txtClassificationStatus").Text = $UIString["Adsk.QS.Classification_12"]
			$dsWindow.FindName("txtClassificationStatus").Visibility = "Visible"
		}
		If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent")
		{
			#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
			$dsWindow.FindName("txtClassificationStatus").Text = $UIString["Adsk.QS.Classification_12"]
			$dsWindow.FindName("txtClassificationStatus").Visibility = "Visible"
		}
		if($mResultPage.Count -ne 0)
		{
			$mResultAll.AddRange($mResultPage)
		}
		else { break;}
		$dsWindow.FindName("txtClassificationStatus").Visibility = "Collapsed"
		return $mResultAll
		break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
	}
}

function mGetFileObject()
{
	$result = FindFile -fileName ($Prop["_FileName"].Value + $Prop["_FileExt"].Value)
	foreach($fileresult in $result)
	{
		if($Prop["_FilePath"].Value -eq ($vault.DocumentService.GetFolderById($fileresult.FolderId)).FullName)
		{
			$file = $fileresult
			return $file
		}
	}
	return $null
}

function mAddClassification()
{
	#$dsDiag.Trace("AddClassification starts...")

	if ($Global:mFile)
	{
		#the function mFindCustent returns a generic list object
		$mActiveClass = @()
		$mActiveClass += mFindCustent -CustentName $dsWindow.FindName("cmbAvailableClasses").SelectedValue -Category "Class" #custom object names should be unique per category
		If($mActiveClass.Count -eq 1)
		{
			$mClsPrpNames = mGetClsPrpNames -ClassId $mActiveClass.Id
			$mPropsAdd = @()
			$mPropsAdd += $mClsPrpNames.Keys
		}
		else
		{
			[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($UIString["Adsk.QS.Classification_10"], "VDS Sample Configuration")
			return
		}
		$mPropsRemove = @()
		$mAddRemoveComment = "Added classification"
		$mFileUpdated = $vault.DocumentService.UpdateFilePropertyDefinitions(@($Global:mFile.MasterId), $mPropsAdd, $mPropsRemove, $mAddRemoveComment)
		if ($null -eq $mFileUpdated) {
			#$dsDiag.Trace("AddClassification Error on UpdateFilePropertyDefinitions")
		}
	}
	$Prop["_XLTN_CLASS"].Value = $dsWindow.FindName("cmbAvailableClasses").SelectedValue
	$dsWindow.FindName("btnRemoveClass").IsEnabled = $true
	$dsWindow.FindName("btnAssignClass").IsEnabled = $false

				
	$value = $dsWindow.FindName("cmbAvailableClasses").SelectedItem.Id
	$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2023\mFileClassId.txt"

	mGetClsDfltValues
	
	mResetClassSelection

	#$dsDiag.Trace("...AddClassification finished.")
}

function mRemoveClassification()
{
	#$dsDiag.Trace("Remove Class starts...")
	if($Prop["_EditMode"])
	{
		if ($Global:mFile)
		{
			#$dsDiag.Trace("...remove class - file found")
			$mActiveClass = @()
			$mActiveClass +=  mFindCustent -CustentName $Prop["_XLTN_CLASS"].Value -Category "Class" #custom object names should be unique within a category, only its Number
			If($mActiveClass.Count -eq 1)
			{
				$mClsPrpNames = mGetClsPrpNames -ClassId $mActiveClass.Id
				$mPropsRemove = @()
				$mPropsRemove += $mClsPrpNames.Keys
			}
			Else{
				[Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($UIString["Adsk.QS.Classification_10"], "VDS Sample Configuration")
				return
			}
			$mMsgResult = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowMessage(([String]::Format($UIString["Adsk.QS.Classification_11"],"`n")), "VDS Sample Configuration", "YesNo")
			if($mMsgResult -eq "No") { return}

			$mAddRemoveComment = "removed classification"
			$mFileUpdated = $vault.DocumentService.UpdateFilePropertyDefinitions(@($Global:mFile.MasterId), $mPropsAdd, $mPropsRemove, $mAddRemoveComment)
			if ($null -eq $mFileUpdated) {
				#$dsDiag.Trace("Removelassification Error on UpdateFilePropertyDefinitions")
			}
		}
	}
	#reset the classification
	$dsWindow.FindName("dtgrdClassProps").ItemsSource = $null
	$Prop["_XLTN_CLASS"] = $null #remove the property from the current window's collection, otherwise it will re-attached to the file
	$dsWindow.FindName("txtActiveClass").Text = ""

	$dsWindow.FindName("btnRemoveClass").IsEnabled = $false
	if($dsWindow.FindName("cmbAvailableClasses").SelectedIndex -ne -1 -and $Prop["_ReadOnly"].Value -eq $false) { $dsWindow.FindName("btnAssignClass").IsEnabled = $true}
	
	#write the highest level Custent Id to a text file for post-close event
	$value = -1
	$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2023\mFileClassId.txt"

	#$dsDiag.Trace("...remove classification finished.")
}


#region classification breadcrumb
function mAddClsLevelCombo ([String] $ClassLevelName, $ClsLvls) {
	$children = mGetCustentClsLevelList -ClassLevelName $ClassLevelName
	if($children -eq $null) { return }
	$mBreadCrumb = $dsWindow.FindName("wrpClassification2")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClsBrdCrmb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = "Name";
	$cmb.ItemsSource = @($children)
	#IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
	$cmb.MinWidth = 140
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.BorderThickness = "1,1,1,1"
	$mWindowName = $dsWindow.Name
		switch($mWindowName)
		{
			"CustomObjectTermWindow"
			{
				IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
			}
			default
			{
				if($dsWindow.FindName("cmbAvailableClasses").Items.Count -gt 1)
				{
					$dsWindow.FindName("cmbAvailableClasses").IsDropDownOpen = $true
				}
				if($dsWindow.FindName("cmbAvailableClasses").Items.Count -eq 0 -and $Prop["_XLTN_CLASS"].Value -eq ""){ $cmb.IsDropDownOpen = $true}
			}
		}
	$cmb.add_SelectionChanged({
			param($sender,$e)
			#$dsDiag.Trace("1. SelectionChanged, Sender = $sender, $e")
			mClsLevelCmbSelectionChanged -sender $sender
		});
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb);

	#region EditMode CustomObjectTerm Window
	If ($dsWindow.Name-eq "CustomObjectTermWindow")
	{
		IF ($Prop["_EditMode"].Value -eq $true)
		{
			$_cmbNames = @()
			Foreach ($_cmbItem in $cmb.Items)
			{
				#$dsDiag.Trace("---$_cmbItem---")
				$_cmbNames += $_cmbItem.Name
			}
			#$dsDiag.Trace("Combo $index Namelist = $_cmbNames")
			if ($ClsLvls[0]) #avoid activation of null ;)
			{
				$_CurrentName = $ClsLvls[0]
				#$dsDiag.Trace("Current Name: $_CurrentName ")
				#get the index of name in array
				$i = 0
				Foreach ($_Name in $_cmbNames)
				{
					$_1 = $_cmbNames.count
					$_2 = $_cmbNames[$i]
					#$dsDiag.Trace(" Counter: $i von $_1 Value: $_2  and CurrentName: $_CurrentName ")
					If ($_cmbNames[$i] -eq $_CurrentName)
					{
						$_IndexToActivate = $i
					}
					$i +=1
				}
				#$dsDiag.Trace("Index of current name: $_IndexToActivate ")
				$cmb.SelectedIndex = $_IndexToActivate
			} #end if ClsLvls[0]

		}
	}
	#endregion
} # addCoCombo

function mAddClsLevelCmbChild ($data) {
	$children = mGetCustentClsLevelUsesList -sender $data
	#$dsDiag.Trace("check data object: $children")
	if($children -eq $null) { return }
	#Filter classification levels and classes
	#mAvlblClsReset
	$mClassLevelObjects = @() #filtered list for the 4 levels
	$mClassLevelObjects += $children | Where-Object {$_.CustEntDefId -in $Global:mClassLevelCustentDefIds}
	$mClassObjects = @() #filtered list for the class object only
	$mClassObjects += $children | Where-Object {$_.CustEntDefId -eq $Global:mClassCustentDef.Id}

	if($mClassObjects.Count -gt 0)
	{
		$dsWindow.FindName("cmbAvailableClasses").ItemsSource = $mClassObjects
		$dsWindow.FindName("cmbAvailableClasses").SelectedIndex = 0
		$dsWindow.FindName("cmbAvailableClasses").IsEnabled = $true
	}
	if($mClassObjects.Count -eq 0)
	{
		mAvlblClsReset
	}
	$children = $mClassLevelObjects
	$mBreadCrumb = $dsWindow.FindName("wrpClassification2")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClsBrdCrmb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = "Name";
	$cmb.ItemsSource = @($children)
	$cmb.BorderThickness = "1,1,1,1"
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.MinWidth = 140
	$mWindowName = $dsWindow.Name
		switch($mWindowName)
		{
			"CustomObjectTermWindow"
			{
				IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
			}
			default
			{
				if($dsWindow.FindName("cmbAvailableClasses").Items.Count -gt 1)
				{
					$dsWindow.FindName("cmbAvailableClasses").IsDropDownOpen = $true
				}
				if($dsWindow.FindName("cmbAvailableClasses").Items.Count -eq 0){ $cmb.IsDropDownOpen = $true}

			}
		}
	$cmb.add_SelectionChanged({
			param($sender,$e)
			#$dsDiag.Trace("next. SelectionChanged, Sender = $sender")
			mClsLevelCmbSelectionChanged -sender $sender
		});
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb)

	$_i = $mBreadCrumb.Children.Count
	$_Label = "lblGroup_" + $_i
	#$dsDiag.Trace("Label to display: $_Label - but not longer used")
	# 	$dsWindow.FindName("$_Label").Visibility = "Visible"

	#region EditMode for CustomObjectTerm Window
	If ($dsWindow.Name-eq "CustomObjectTermWindow")
	{
		IF ($Prop["_EditMode"].Value -eq $true)
		{
			Try
			{
				$_cmbNames = @()
				Foreach ($_cmbItem in $cmb.Items)
				{
					#$dsDiag.Trace("---$_cmbItem---")
					$_cmbNames += $_cmbItem.Name
				}
				#$dsDiag.Trace("Combo $index Namelist = $_cmbNames")
				#get the index of name in array
				if ($ClsLvls[$_i-2]) #avoid activation of null ;)
				{
					$_CurrentName = $ClsLvls[$_i-2] #remember the number of breadcrumb children is +2 (delete button, and the class start with index 0)
					#$dsDiag.Trace("Current Name: $_CurrentName ")
					$i = 0
					Foreach ($_Name in $_cmbNames)
					{
						$_1 = $_cmbNames.count
						$_2 = $_cmbNames[$i]
						#$dsDiag.Trace(" Counter: $i von $_1 Value: $_2  and CurrentName: $_CurrentName ")
						If ($_cmbNames[$i] -eq $_CurrentName)
						{
							$_IndexToActivate = $i
						}
						$i +=1
					}
					#$dsDiag.Trace("Index of current name: $_IndexToActivate ")
					$cmb.SelectedIndex = $_IndexToActivate
				} #end

			} #end try
		catch
		{
			$dsDiag.Trace("Error activating an existing index in edit mode.")
		}
	}
	}
	#endregion
} #addCoComboChild

function mGetCustentClsLevelList ([String] $ClassLevelName) {
	try {
		#$dsDiag.Trace(">> mGetCustentClsLevelList started")
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 1
		$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
		#$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT") global var in ADSK.QS.Classification
		$propDefs = $Global:mAllCustentPropDefs
		$propNames = @("CustomEntityName")
		$propDefIds = @{}
		foreach($name in $propNames) {
			$propDef = $propDefs | Where-Object { $_.SysName -eq $name }
			$propDefIds[$propDef.Id] = $propDef.DispName
		}
		$srchCond.PropDefId = $propDef.Id
		$srchCond.SrchOper = 3
		$srchCond.SrchTxt = $ClassLevelName
		$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[0] = $srchCond
		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$_CustomEnts = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds,$null,[ref]$bookmark,[ref]$searchStatus)
		#$dsDiag.Trace(".. mGetCustentClsLevelList finished - returns $_CustomEnts <<")
		return $_CustomEnts
	}
	catch {
		$dsDiag.Trace("!! Error in mGetCustentClsLevelList")
	}
}

function mGetCustentClsLevelUsesList ($sender) {
	try {
		#$dsDiag.Trace(">> mGetCustentClsLevelUsesList started")
		$mBreadCrumb = $dsWindow.FindName("wrpClassification2")
		$_i = $mBreadCrumb.Children.Count -1
		$_CurrentCmbName = "cmbClsBrdCrmb_" + $mBreadCrumb.Children.Count.ToString()
		$_CurrentClass = $mBreadCrumb.Children[$_i].SelectedValue.Name
        switch($_i)
		        {
			        0 { $mSearchFilter = "Segment"}
			        1 { $mSearchFilter = "Main Group"}
			        2 { $mSearchFilter = "Group"}
					3 { $mSearchFilter = "Sub Group"}
			        default { $mSearchFilter = "*"}
		        }
		$_customObjects = mGetCustentClsLevelList -ClassLevelName $mSearchFilter
		$_Parent = $_customObjects | Where-Object { $_.Name -eq $_CurrentClass }

		try {
			$links = $vault.DocumentService.GetLinksByParentIds(@($_Parent.Id),@("CUSTENT"))
			$linkIds = @()
			$links | ForEach-Object { $linkIds += $_.ToEntId }
			$mLinkedCustObjects = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds)
			#$dsDiag.Trace(".. mGetCustentClsLevelUsesList finished - returns $mLinkedCustObjects <<")
			return $mLinkedCustObjects #$global:_Groups
		}
		catch {
			$dsDiag.Trace("!! Error getting links of Parent Co !!")
			return $null
		}
	}
	catch { $dsDiag.Trace("!! Error in mAddCoComboChild !!") }
}

function mClsLevelCmbSelectionChanged ($sender) {
	$mBreadCrumb = $dsWindow.FindName("wrpClassification2")
	$position = [int]::Parse($sender.Name.Split('_')[1]);
	$children = $mBreadCrumb.Children.Count - 1
	while($children -gt $position )
	{
		$cmb = $mBreadCrumb.Children[$children]
		$mBreadCrumb.UnregisterName($cmb.Name) #unregister the name to correct for later addition/registration
		$mBreadCrumb.Children.Remove($mBreadCrumb.Children[$children]);
		$children--;
	}
	Try{
		$Prop["_XLTN_SEGMENT"].Value = $mBreadCrumb.Children[1].SelectedItem.Name
		$Prop["_XLTN_MAINGROUP"].Value = $mBreadCrumb.Children[2].SelectedItem.Name
		$Prop["_XLTN_GROUP"].Value = $mBreadCrumb.Children[3].SelectedItem.Name
		$Prop["_XLTN_SUBGROUP"].Value = $mBreadCrumb.Children[4].SelectedItem.Name
	}
	catch{}
	#$dsDiag.Trace("---combo selection = $_selected, Position $position")

	mAvlblClsReset

	mAddClsLevelCmbChild -sender $sender.SelectedItem
}

function mResetClassSelection
{
    #$dsDiag.Trace(">> Reset Filter started...")

	$mBreadCrumb = $dsWindow.FindName("wrpClassification2")
	$mBreadCrumb.Children[0].SelectedIndex = -1

	#$dsDiag.Trace("...Reset Filter finished <<")
}

function mAvlblClsReset
{
	if ($null -ne $dsWindow.FindName("cmbAvailableClasses")) {
		$dsWindow.FindName("cmbAvailableClasses").ItemsSource = $null
		$dsWindow.FindName("cmbAvailableClasses").SelectedIndex = -1
		$dsWindow.FindName("cmbAvailableClasses").IsEnabled = $false
	}
	$dsWindow.FindName("btnAssignClass").IsEnabled = $false
}
#endregion classification breadcrumb

function mAssignClassification
{
	[xml]$AssignClsXaml = Get-Content "C:\ProgramData\Autodesk\Vault 2023\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.SelectClassification.xaml"
    $reader = New-Object System.Xml.XmlNodeReader $AssignClsXaml
    $AssignClsWindow = [Windows.Markup.XamlReader]::Load($reader) 
    $AssignClsWindow.DataContext = $dsWindow.DataContext

	mAssignClsGrdReset -ComboBox $AssignClsWindow.FindName("cmb_ClsStd")

	$AssignClsWindow.FindName("cmb_ClsStd").add_SelectionChanged({
		param ($sender, $e)
		mAssignClsGrdReset -ComboBox $AssignClsWindow.FindName("cmb_ClsStd")
	})

	if ($AssignClsWindow.ShowDialog() -eq "OK") {
        #grab all the values to return
        return
    } else {
        return $null
    }
}

function mAssignClsGrdReset ($ComboBox){
	if ($ComboBox.SelectedIndex -eq "0"){
			$AssignClsWindow.FindName("grdIEC61355").Visibility = "Visible"
			$AssignClsWindow.FindName("grdClassification").Visibility = "Collapsed"
		}
		Else{
			$AssignClsWindow.FindName("grdIEC61355").Visibility = "Collapsed"
			$AssignClsWindow.FindName("grdClassification").Visibility = "Visible"
		}
}