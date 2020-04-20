SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright © 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	UD table setup for Cross Reference: AR Customers
	Created: 05/18/2012
	Created by:	VCS Technical Services - Bryan Clark
	Revisions:	1. None

Notes:	This procedure creates a UD table and form for the AR Customer Cross Reference.
		
IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefARCustomer]
(@datecreated smalldatetime)

AS 

/* Create the ud table */
if not exists (select name from dbo.sysobjects where name ='budxrefARCustomer')
BEGIN
	CREATE TABLE Viewpoint.dbo.budxrefARCustomer(
		Company int NOT NULL,
		OldCustomerID varchar(10) NOT NULL,
		CustGroup dbo.bGroup NULL,
		NewCustomerID dbo.bCustomer NULL,
		Name varchar(60) NULL,
		ActiveYN dbo.bYN NOT NULL DEFAULT ('Y'),
		NewYN dbo.bYN NOT NULL DEFAULT ('Y'),
		Notes dbo.bNotes NULL,
		UniqueAttchID uniqueidentifier NULL,
		KeyID bigint IDENTITY(1,1) NOT NULL
		);
END;
	
	
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefARCustomer'
insert into Viewpoint.dbo.vDDFHc 
	(Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
	,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
	,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
	('udxrefARCustomer','Cross Ref: AR Customer','1','Y',NULL,'udxrefARCustomer',NULL,NULL,'UD',
	'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefARCustomer','N')


--SOURCE:  
/*
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
		ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
		AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq
from vDDFIc where Form='udxrefARCustomer'

*/
insert into Viewpoint.dbo.vDDFIc
	(Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
		ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
		AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
	 ('udxrefARCustomer','5000','udxrefARCustomer','Company','Company',NULL,'1','6','2',NULL,'Y','6',NULL,'2','0','N','Company','Y','Y',null,NULL,NULL,NULL,NULL)
	,('udxrefARCustomer','5005','udxrefARCustomer','OldCustomerID','Old Customer ID',NULL,'0','10',NULL,null,'Y','6',null,'2','0','N','Old Customer ID','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefARCustomer','5010','udxrefARCustomer','CustGroup','Customer Group','bGroup',NULL,NULL,NULL,'1','N','6','6,188,187,20','4','0','N','Customer Group','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefARCustomer','5015','udxrefARCustomer','NewCustomerID','New Customer ID','bCustomer',NULL,NULL,NULL,'1','N','6','6,405,194,20','4','0','N','New Customer ID','Y','Y',NULL,NULL,'Y','5010','1')
	,('udxrefARCustomer','5020','udxrefARCustomer','Name','Name',NULL,'0','60',NULL,'1','N','6','36,48,389,20','4','0','N','Name','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefARCustomer','5025','udxrefARCustomer','ActiveYN','Active YN','bYN',NULL,NULL,NULL,'1','Y','14','65,95,93,20','4','0','N','Active YN','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefARCustomer','5030','udxrefARCustomer','NewYN','New YN','bYN',NULL,NULL,NULL,'1','Y','14','65,273,70,20','4','0','N','New YN','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefARCustomer','9999','udxrefARCustomer','Notes','User Notes','bNotes',NULL,NULL,NULL,'2','N','8',NULL,'1','0','N',NULL,'Y','Y',NULL,NULL,NULL,NULL,NULL)


--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefARCustomer'
insert into Viewpoint.dbo.vDDFTc
	(Form, Tab, Title, LoadSeq)
values
	 ('udxrefARCustomer', 0,    'Grid',     0)
	,('udxrefARCustomer', 1,    'Info',     1)
	,('udxrefARCustomer', 2,    'Notes',    2)		


--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefARCustomer'
insert into Viewpoint.dbo.vDDUI
	(Form, Seq, GridCol, VPUserName)
values
	 ('udxrefARCustomer', 5000, 0,    'viewpointcs')
	,('udxrefARCustomer', 5005, 1,    'viewpointcs')
	,('udxrefARCustomer', 5010, 2,    'viewpointcs')
	,('udxrefARCustomer', 5015, 3,    'viewpointcs')
	,('udxrefARCustomer', 5020, 4,    'viewpointcs')
	,('udxrefARCustomer', 5025, 5,    'viewpointcs')	
	,('udxrefARCustomer', 5030, 5,    'viewpointcs')
	,('udxrefARCustomer', 9999, 6,    'viewpointcs')		

	
--SOURCE:  
/*
select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
AutoSeqType, ComboType
from bUDTC where TableName='udxrefARCustomer'
*/
insert into Viewpoint.dbo.bUDTC 
	(TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
		AutoSeqType, ComboType)
values
	 ( 'udxrefARCustomer','Company','Company','1',NULL,'1','6','2','6','5000','1',NULL)
	,( 'udxrefARCustomer','OldCustomerID','Old Customer ID','2',NULL,'0','10',NULL,'6','5005',NULL,NULL)
	,( 'udxrefARCustomer','CustGroup','Customer Group',NULL,'bGroup',NULL,NULL,NULL,'6','5010',NULL,NULL)	 
	,( 'udxrefARCustomer','NewCustomerID','New Customer ID',NULL,'bCustomer',NULL,NULL,NULL,'6','5015',NULL,NULL)	
	,( 'udxrefARCustomer','Name','Name',NULL,NULL,'0','60',NULL,'6','5020',NULL,NULL)
	,( 'udxrefARCustomer','ActiveYN','Active YN',NULL,'bYN',NULL,NULL,NULL,'14','5025',NULL,NULL)
	,( 'udxrefARCustomer','NewYN','New YN',NULL,'bYN',NULL,NULL,NULL,'14','5030',NULL,NULL)

	
--SOURCE:  select * from bUDTH where TableName='udxrefARCustomer'
--declare @datecreated smalldatetime set @datecreated=getdate()

EXEC sp_unbindrule 'bUDTH.UseNotesTab';


insert into Viewpoint.dbo.bUDTH
	(TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
	('udxrefARCustomer', 'Cross Ref: AR Customer', 'udxrefARCustomer', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');

EXEC sp_bindrule  'brYesNo', 'bUDTH.UseNotesTab';

  

--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefARCustomer'
INSERT INTO Viewpoint.dbo.vDDMFc
	(Mod, Form, Active)
values
	('UD','udxrefARCustomer','Y');


--SOURCE:  select Seq, ColumnName, CustomControlSize from DDFIc where Form='udxrefARCustomer'
update Viewpoint.dbo.DDFIc 
set CustomControlSize=
	case
		when Seq=5010 then '87,100'
		when Seq=5020 then '46,343'
		when Seq=5025 then '0,93'
		when Seq=5030 then '0,75'
		else null 
	end
where Viewpoint.dbo.DDFIc.Form='udxrefARCustomer' and ControlPosition is not null


/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW udxrefARCustomer as select a.* from Viewpoint.dbo.budxrefARCustomer a;
GO
