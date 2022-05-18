#region disclaimer
#===================================================================
# PowerShell script sample for Vault Data Standard                            
#                                                                             
# Copyright (c) Autodesk - All rights reserved.                               
#                                                                             
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  
#===================================================================
#endregion

#region - version history
# Version Info - ADSK.QS.FileImport 2020.0.0
	# updated according new NumberingService
#endregion

Add-Type @"
public class FilePropData
{
	public string mOrigFileName {get;set;}
	public string mFileNewFullName {get;set;}
	public string mFileNewName {get;set;}
	public string mFileTitle {get;set;}	
	public string mFileDescr {get;set;}
}
"@

function mInitializeFileImport
{
	$dsWindow.FindName("txtStatusInfo").Text = ""
	$dsWindow.FindName("txtInstructionMsg").Text = "Drop Files on Upload Symbol below; files are added to Vault DMS Folder."
	$dsWindow.FindName("btnRestart").IsEnabled = $false
	$dsWindow.FindName("btnUpdate").IsEnabled = $false
	$dsWindow.FindName("dtGrdPropEdit").Visibility = "Collapsed"
	$dsWindow.FindName("dockPanelDragArea").Visibility = "Visible"
	$dsWindow.FindName("grdRadioBtns1").Visibility = "Visible"
	$dsWindow.FindName("mImportProgress").Value = 0
	
	$dsWindow.FindName("mFilesDragArea").add_Drop({			
		param( $sender, $e)						
		mDragEnter $sender $e

		}) #end drag & drop
}

function mFileImportRestart
{
	mInitializeFileImport
}

function mImportUpdateProps
{
	$dsWindow.FindName("mImportProgress").Value = 0
	$dsWindow.Cursor = "Wait"
	$dsWindow.FindName("txtStatusInfo").Text = "Updating Properties..."
	$mGridItems = $dsWindow.FindName("dtGrdPropEdit").Items
	$mUpdateProps = @{}
	$mUpdateProps.Add('Titel', '')
	$mUpdateProps.Add('Beschreibung', '')
	$_n = 0
	Foreach ($mGridItem in $dsWindow.FindName("dtGrdPropEdit").Items)
	{
		$mFileUpdated = $null
		$mUpdateProps.Set_Item('Titel', $mGridItem.mFileTitle)
		$mUpdateProps.Set_Item('Beschreibung', $mGridItem.mFileDescr)
		Try
		{
			$mFileUpdated = Update-VaultFile -File $mGridItem.mFileNewFullName -Properties $mUpdateProps
			If ($mFileUpdated) 
			{ 
				$_n +=1 
				$dsWindow.FindName("mImportProgress").Value += 10
			}
		}
		Catch{
			#$dsDiag.Trace("--Update-VaultFile failed for file: $($mGridItem.mFileNewFullName)")
		}
		
	}
	$dsWindow.FindName("btnUpdate").IsEnabled = $false
	$dsWindow.FindName("btnRestart").IsEnabled = $true
	$_ResultMessage = $_n.ToString() + " Files updated."
	$dsWindow.FindName("txtStatusInfo").Text = $_ResultMessage
	$dsWindow.Cursor = "Arrow"
	$dsWindow.FindName("mImportProgress").Value = 100
}

function mDragEnter ($sender, $e)
{
	#$dsDiag.Trace("Drag Enter fired")
			[System.Windows.DataObject]$mDragData = $e.Data
		$mFileList = $mDragData.GetFileDropList()
		#Filter folders, we attach files directly selected only
		$mFileList = $mFileList | Where { (get-item $_).PSIsContainer -eq $false }
		If ($mFileList)
		{
			$dsWindow.Cursor = "Wait"
			$_NumFiles = $mFileList.Count
			$_n = 0
			$dsWindow.FindName("mImportProgress").Value = 0
			$mExtExclude = @(".ipt", ".iam", ".ipn", ".dwg", ".idw", ".slddrw", ".sldprt", ".sldasm")
			$mImportFilesPath = @() #filepath array of imported files to be attached
			$mImportFiles = @() #array of file objects imported
			$mGridFiles = @()
			ForEach ($_file in $mFileList)
			{
				$m_FileName = [System.IO.Path]::GetFileNameWithoutExtension($_file)
				$m_Ext = [System.IO.Path]::GetExtension($_file)
				If ($mExtExclude -contains $m_Ext){
					$mCADWarning = $true
					break;
				}
				$m_Dir = [System.IO.Path]::GetDirectoryName($_file)
				
				#create new datagrid row object
				$mDtRow = New-Object FilePropData
				
				#get new number and create new file name
				[System.Collections.ArrayList]$numSchems = @($vault.NumberingService.GetNumberingSchemes('FILE', 'Activated'))
				if ($numSchems.Count -gt 1 -and $dsWindow.FindName("radioNumberedName").IsChecked -eq $true)
				{							
					$_DfltNumSchm = $numSchems | Where { $_.Name -eq $UIString["ADSK-ItemFileImport_00"]}
					if($_DfltNumSchm)
					{
						$NumGenArgs = @("")
						$_newFile=$vault.DocumentService.GenerateFileNumber($_DfltNumSchm.SchmID, $NumGenArgs)
					}		
				}

				#add file
				If($_newFile)
				{
					#get appropriate folder number (limit 1k files per folder)
					Try{
						$mTargetPath = mGetFolderNumber $_newFile 3 #hand over the file number (name) and number of files / folder
					}
					catch { 
						[System.Windows.MessageBox]::Show($UIString["ADSK-ItemFileImport_01"], "Item-File Attachment Import")
					}
					#add extension to number
					$_newFile = $_newFile + $m_Ext
					$mFullTargetPath = $mTargetPath + $_newFile
					$mImportedFile = Add-VaultFile -From $_file -To $mFullTargetPath -Comment $UIString["ADSK-ItemFileImport_02"]
					$mImportFilesPath += $mImportedFile._FullPath
					$mImportFiles += $mImportedFile
					#add grid row data
					$mDtRow.mFileNewName = $_newFile
					$mDtRow.mFileNewFullName = $mFullTargetPath
					$mDtRow.mOrigFileName = [System.IO.Path]::GetFileName($_file)
					$mDtRow.mFileTitle = $mImportedFile._Title
					$mDtRow.mFileDescr = $mImportedFile._Description
					$mGridFiles += $mDtRow
				}
				Else #continue with the given file name
				{
					$mTargetPath = "$/xDMS/"
					$mFullTargetPath = $mTargetPath + $m_FileName + $m_Ext
					$mImportedFile = Add-VaultFile -From $_file -To $mFullTargetPath -Comment $UIString["ADSK-ItemFileImport_02"]
					$mImportFilesPath += $mImportedFile._FullPath
					$mImportFiles += $mImportedFile
					#add grid row data
					$mDtRow.mFileNewName = $mImportedFile._Name
					$mDtRow.mFileNewFullName = $mFullTargetPath
					$mDtRow.mOrigFileName = [System.IO.Path]::GetFileName($_file)
					$mDtRow.mFileTitle = $mImportedFile._Title
					$mDtRow.mFileDescr = $mImportedFile._Description
					$mGridFiles += $mDtRow
				}
				$_n += 1
				$dsWindow.FindName("mImportProgress").Value = (($_n/$_NumFiles)*100)-10

			} #for each file
			
			$dsWindow.FindName("mImportProgress").Value = (($_n/$_NumFiles)*100)
			#
			$dsWindow.FindName("dtGrdPropEdit").ItemsSource = $mGridFiles
			If ($mCADWarning)
			{
				[System.Windows.MessageBox]::Show($UIString["ADSK-ItemFileImport_04"], "Item-File Attachment Import")
			}
		}
		$mFileList = $null
		#reset the UI
		$dsWindow.FindName("txtStatusInfo").Text = ""
		$dsWindow.FindName("txtInstructionMsg").Text = "Optionally, you may edit property values and update the imported files."

		$dsWindow.FindName("btnRestart").IsEnabled = $true
		$dsWindow.FindName("btnUpdate").IsEnabled = $true
		$dsWindow.FindName("dtGrdPropEdit").Visibility = "Visible"
		$dsWindow.FindName("dockPanelDragArea").Visibility = "Collapsed"
		$dsWindow.FindName("grdRadioBtns1").Visibility = "Collapsed"
		$dsWindow.FindName("mImportProgress").Value = 0
		$dsWindow.Cursor = "Arrow"

		$dsWindow.FindName("mDragAreaEnabled").remove_Drop()
		
}