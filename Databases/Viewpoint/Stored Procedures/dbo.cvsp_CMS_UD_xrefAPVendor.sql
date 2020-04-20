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
	Title:	UD table setup for Cross Reference: AP Vendors
	Created: 03/09/2011
	Created by:	VCS Technical Services - Bryan Clark
	Revisions:	1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
					--declare @datecreated smalldate time set @datecreated=getdate()
					and added code for the UserNotes.
				2. 08/10/2011 BBA - Added Notes column in create table.
				3. 09/08/2011 BBA - Changed ActiveYN to checkbox.
				4. 09/21/2011 BBA - Added Seq for multiple co conversions. 
				5. 10/31/2011 BBA - Added Lookup for NewVendorID.
				6. 03/05/2012 BBA - Adjusted CustomControlSize.
				7. 03/20/2012 BBA - Added sp to CMS. Renamed table.
				8. 10/22/2012 BTC - Added CGCVendorType field to allow for conversion of Lienors
				9. 10/22/2012 BTC - Dropped Seq field and added Company field for multi-company conversions

Notes:	This procedure creates a UD table and form for the AP Vendor Cross Reference.
		
IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefAPVendor]
(@datecreated smalldatetime)

AS 

/* Create the ud table */
if not exists (select name from dbo.sysobjects where name ='budxrefAPVendor')
BEGIN
	CREATE TABLE Viewpoint.dbo.budxrefAPVendor(
		Company int NOT NULL,
		OldVendorID varchar(10) NOT NULL,
		CGCVendorType char(1) not null,
		VendorGroup dbo.bGroup NULL,
		NewVendorID dbo.bVendor NULL,
		Name varchar(60) NULL,
		ActiveYN dbo.bYN NOT NULL DEFAULT ('Y'),
		Notes dbo.bNotes NULL,
		UniqueAttchID uniqueidentifier NULL,
		KeyID bigint IDENTITY(1,1) NOT NULL
		);
END;
	
	
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefAPVendor'
insert into Viewpoint.dbo.vDDFHc 
	(Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
	,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
	,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
	('udxrefAPVendor','Cross Ref: AP Vendor','1','Y',NULL,'udxrefAPVendor',NULL,NULL,'UD',
	'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefAPVendor','N')


--SOURCE:  
/*
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
		ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
		AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq
from vDDFIc where Form='udxrefAPVendor'

*/
insert into Viewpoint.dbo.vDDFIc
	(Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
		ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
		AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
	 ('udxrefAPVendor','5000','udxrefAPVendor','Company','Company',NULL,'1','6','2',NULL,'Y','6',NULL,'2','0','N','Company','Y','Y',null,NULL,NULL,NULL,NULL)
	,('udxrefAPVendor','5005','udxrefAPVendor','OldVendorID','Old Vendor ID',NULL,'0','10',NULL,null,'Y','6',null,'2','0','N','Old Vendor ID','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefAPVendor','5010','udxrefAPVendor','CGCVendorType','CGC Vendor Type',NULL,'0','1',null,null,'Y','6',null,'2','0','N','CGC Vendor Type','Y','Y','0',null,null,null,null)
	,('udxrefAPVendor','5015','udxrefAPVendor','Name','Name',NULL,'0','60',NULL,'1','N','6','36,48,389,20','4','0','N','Name','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefAPVendor','5020','udxrefAPVendor','VendorGroup','Vendor Group','bGroup',NULL,NULL,NULL,'1','N','6','6,188,187,20','4','0','N','Vendor Group','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefAPVendor','5025','udxrefAPVendor','NewVendorID','New Vendor ID','bVendor',NULL,NULL,NULL,'1','N','6','6,405,194,20','4','0','N','New Vendor ID','Y','Y',NULL,NULL,'Y','5010','1')
	,('udxrefAPVendor','5030','udxrefAPVendor','ActiveYN','Active YN','bYN',NULL,NULL,NULL,'1','Y','14','65,95,93,20','4','0','N','Active YN','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefAPVendor','9999','udxrefAPVendor','Notes','User Notes','bNotes',NULL,NULL,NULL,'2','N','8',NULL,'1','0','N',NULL,'Y','Y',NULL,NULL,NULL,NULL,NULL)


--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefAPVendor'
insert into Viewpoint.dbo.vDDFTc
	(Form, Tab, Title, LoadSeq)
values
	 ('udxrefAPVendor', 0,    'Grid',     0)
	,('udxrefAPVendor', 1,    'Info',     1)
	,('udxrefAPVendor', 2,    'Notes',    2)		


--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefAPVendor'
insert into Viewpoint.dbo.vDDUI
	(Form, Seq, GridCol, VPUserName)
values
	 ('udxrefAPVendor', 5000, 0,    'viewpointcs')
	,('udxrefAPVendor', 5005, 1,    'viewpointcs')
	,('udxrefAPVendor', 5010, 2,    'viewpointcs')
	,('udxrefAPVendor', 5015, 3,    'viewpointcs')
	,('udxrefAPVendor', 5020, 4,    'viewpointcs')
	,('udxrefAPVendor', 5025, 5,    'viewpointcs')	
	,('udxrefAPVendor', 5030, 5,    'viewpointcs')
	,('udxrefAPVendor', 9999, 7,    'viewpointcs')		

	
--SOURCE:  
/*
select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
AutoSeqType, ComboType
from bUDTC where TableName='udxrefAPVendor'
*/
insert into Viewpoint.dbo.bUDTC 
	(TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
		AutoSeqType, ComboType)
values
	 ( 'udxrefAPVendor','Company','Company','1',NULL,'1','6','2','6','5000','1',NULL)
	,( 'udxrefAPVendor','OldVendorID','Old Vendor ID','2',NULL,'0','10',NULL,'6','5005',NULL,NULL)
	,( 'udxrefAPVendor','CGCVendorType','CGC Vendor Type','3',null,'0','1','2','6','5010','0',null)
	,( 'udxrefAPVendor','Name','Name',NULL,NULL,'0','60',NULL,'6','5015',NULL,NULL)
	,( 'udxrefAPVendor','VendorGroup','Vendor Group',NULL,'bGroup',NULL,NULL,NULL,'6','5020',NULL,NULL)	 
	,( 'udxrefAPVendor','NewVendorID','New Vendor ID',NULL,'bVendor',NULL,NULL,NULL,'6','5025',NULL,NULL)	
	,( 'udxrefAPVendor','ActiveYN','Active YN',NULL,'bYN',NULL,NULL,NULL,'14','5030',NULL,NULL)

	
--SOURCE:  select * from bUDTH where TableName='udxrefAPVendor'
--declare @datecreated smalldatetime set @datecreated=getdate()


EXEC sp_unbindrule 'bUDTH.UseNotesTab';

insert into Viewpoint.dbo.bUDTH
	(TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, AuditTable)
values
	('udxrefAPVendor', 'Cross Ref: AP Vendor', 'udxrefAPVendor', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 'Y');

EXEC sp_bindrule  'brYesNo', 'bUDTH.UseNotesTab';

--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefAPVendor'
INSERT INTO Viewpoint.dbo.vDDMFc
	(Mod, Form, Active)
values
	('UD','udxrefAPVendor','Y');


--SOURCE:  select Seq, ColumnName, CustomControlSize from DDFIc where Form='udxrefAPVendor'
update Viewpoint.dbo.DDFIc 
set CustomControlSize=
	case
		when Seq=5015 then '5,4,236,20'
		when Seq=5020 then '32,4,115,20'
		when Seq=5025 then '32,131,194,20'
		when Seq=5030 then '59,4,105,20'
		else null 
	end
where Viewpoint.dbo.DDFIc.Form='udxrefAPVendor' and ControlPosition is not null


/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW Viewpoint.dbo.udxrefAPVendor as select a.* from Viewpoint.dbo.udxrefAPVendor a;
GO
