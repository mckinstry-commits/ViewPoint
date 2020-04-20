SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[brptHQAuditEquipCodeChange1]

(@UserName bVPUserName)

as 

--Main Report Old Equipment Code Changed
Select
'Main' as 'Report',
TableName,
KeyString,
Co,
RecType,
FieldName,
OldValue,
NewValue,
[DateTime],
UserName
From HQMA 
Where Co = 1
	and UserName=@UserName 
	and KeyString like ('%79ChgTest%') 
	and RecType = 'C'
	and TableName = 'bEMEM' 
	and FieldName in ('Equipment','ChangeInProgress','LastUsedEquipmentCode','LastEquipmentChangeUser','EquipmentCodeChanges','LastEquipmentChangeDate')
--Order By HQMA.DateTime

Union All

--UpdateTableList (Sub Report) 
--use Co,UserName and KeyString as sub report parameters.
Select 
'UpdateTableList' as 'Report',
TableName,
KeyString,
Co,
RecType,
FieldName,
OldValue,
NewValue,
[DateTime],
UserName
From HQMA 
Where Co = 1 
	and  UserName=@UserName 
	and KeyString like ('%79ChgTest%') 
	and RecType = 'C'
	and TableName <> 'bEMEM' 
	and FieldName not in ('ChangeInProgress','LastUsedEquipmentCode','Last EquipmentChangeUser','Equipment CodeChanges','LastEquipmentChangeDate')
--Order By HQMA.DateTime

Union All

--EquipmentChanged to (sub report) 
--Parameters Co,UserName
--and create crystal report variable from NewValue column, Last Used Equipmet Code
Select 
'EquipmentChanged' as 'Report',
TableName,
KeyString,
Co,
RecType,
FieldName,
OldValue,
NewValue,
[DateTime],
UserName
From HQMA 
Where  Co = 1 
	and UserName=@UserName 
	and KeyString like ('%79') 
	and RecType = 'C'
	and TableName = 'bEMEM' 

GO
GRANT EXECUTE ON  [dbo].[brptHQAuditEquipCodeChange1] TO [public]
GO
