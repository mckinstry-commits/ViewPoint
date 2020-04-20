SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:	UD table setup for Cross Reference: PR Earnings
	Created: 03/10/2011
	Created by:	VCS Technical Services - Bryan Clark
	Revisions:	
		1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
			--declare @datecreated smalldate time set @datecreated=getdate()
			and added code for the UserNotes.
		2. 08/10/2011 BBA - Added Notes column.  
		3. 10/28/2011 BBA - Added NewYN column.
		4. 11/01/2011 BBA - Added Lookup for JCCo and VPJCDept columns.
		5. 01/27/2012 MTG - Modified for use in CGC Conversions
        6. 03/19/2012 BBA - Added Drop code and removed odd characters in
			the last insert statement, replaced with single quotes.
				
	Notes:	This procedure creates a UD table and form for the PR Earnings Cross Reference.
			
	IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
	THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
	BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefPREarn]
(@datecreated smalldatetime)

AS 


/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefPREarn')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefPREarn
		(Company		smallint	not null, 
		CMSDedCode		varchar(10) not null, 
		CMSCode		    varchar(10) not null, 
		VPType			varchar(1)	 null,
		EarnCode		int			 null, 
		UniqueAttchID uniqueidentifier NULL,
		KeyID bigint IDENTITY(1,1) NOT NULL
		);
END
	
	
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefPREarn'
insert into Viewpoint.dbo.vDDFHc 
	(Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
	,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
	,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
	('udxrefPREarn','Cross Ref: PR Earn Codes','1','Y',NULL,'udxrefPREarn',NULL,NULL,'UD',
	'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefPREarn','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
	ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
	AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefPREarn'
*/
insert into Viewpoint.dbo.vDDFIc
	(Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
		ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
		AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
	 ('udxrefPREarn','5000','udxrefPREarn','Company','Company','bPRCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company','Y','Y',NULL,NULL,NULL,NULL,NULL)
	,('udxrefPREarn','5005','udxrefPREarn','CMSDedCode','CMS DedCode',NULL,'0','5',NULL,NULL,'Y','6',NULL,'2','0','N','CMS DedCode','Y','Y','0',NULL,NULL,NULL,NULL)
	,('udxrefPREarn','5010','udxrefPREarn','CMSCode','CMS Code','bDept',NULL,'0',NULL,NULL,'Y','6',NULL,'2','0','N','VP CMS Code','Y','Y','0',NULL,NULL,NULL,NULL)
	,('udxrefPREarn','5015','udxrefPREarn','VPType','VP Type (E or D)',NULL,'0','1',NULL,'1','N','6','2,2,136,20','4','0','N','VP Type (E or D)','Y','Y','0',NULL,NULL,NULL,NULL)
	,('udxrefPREarn','5020','udxrefPREarn','EarnCode','VP Earn Code','bEarnCode',NULL,NULL,NULL,'1','N','6','1,166,125,20','4','0','N','VP Earn Code','Y','Y',NULL,NULL,NULL,NULL,NULL)
	
	

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefPREarn'
insert into Viewpoint.dbo.vDDFTc
	(Form, Tab, Title, LoadSeq)
values
	 ('udxrefPREarn', 0,    'Grid',     0)
	,('udxrefPREarn', 1,    'Info',     1)
	

--SOURCE:  select Form, Seq, GridCol, VPUserNamefrom vDDUI where Form='udxrefPREarn'
insert into Viewpoint.dbo.vDDUI
	(Form, Seq, GridCol, VPUserName)
values
	 ('udxrefPREarn', 5000, 0,    'viewpointcs')
	,('udxrefPREarn', 5005, 1,    'viewpointcs')
	,('udxrefPREarn', 5010, 2,    'viewpointcs')
	,('udxrefPREarn', 5015, 3,    'viewpointcs')
	,('udxrefPREarn', 5020, 4,    'viewpointcs')

		
--SOURCE: 
/*		
		select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
		AutoSeqType, ComboType from bUDTC where TableName='udxrefPREarn' order by DDFISeq
*/
insert into Viewpoint.dbo.bUDTC 
	(TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
		AutoSeqType, ComboType)
values
	 ( 'udxrefPREarn','Company','Company','1','bPRCo',NULL,NULL,NULL,'6','5000',NULL,NULL)
	,( 'udxrefPREarn','CMSDedCode','CMS DedCode','2',NULL,'0','5',NULL,'6','5005','0',NULL)
	,( 'udxrefPREarn','CMSCode','CMS Code','3',NULL,'0','5',NULL,'6','5010','0',NULL)
	,( 'udxrefPREarn','VPType','VP Type (E or D)',NULL,NULL,'0','1',NULL,'6','5015','0',NULL)
	,( 'udxrefPREarn','EarnCode','VP Earn Code',NULL,'bEarnCode',NULL,NULL,NULL,'6','5020',NULL,NULL)
	
	
--SOURCE:  select * from bUDTH where TableName='udxrefPREarn'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
	(TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
	('udxrefPREarn', 'Cross Ref: PR Earn', 'udxrefPREarn', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefPREarn'
alter table vDDMFc disable trigger all;
INSERT INTO Viewpoint.dbo.vDDMFc
	(Mod, Form, Active)
values
	('UD','udxrefPREarn','Y');
alter table vDDMFc enable trigger all;
/* no control size necessary
--SOURCE:  select Seq, CustomControlSize from DDFIc where Form='udxrefPREarn'
update DDFIc 
set	CustomControlSize=case
		when Seq=5005 then '89,343'
		when Seq=5010 then '42,43'
		when Seq=5015 then '72,119'
		when Seq=5020 then '89,270'
		when Seq=5025 then '101,122'
		when Seq=5030 then '0,75'
		else null 
	end
where DDFIc.Form='udxrefPREarn'
*/


/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefPREarn as select a.* From budxrefPREarn a;

-- Insert values into new ud table

insert into dbo.budxrefPREarn
select distinct x.COMPANYNUMBER, x.CMSDedCode, x.CMSCode, null, null, null from 
(
Select distinct  COMPANYNUMBER,OTHHRSTYPE as CMSDedCode, 'OTH' as CMSCode from CV_CMS_SOURCE.dbo.PRTTCH 
where OTHHRS <>0 --this helps to get rid of typos in the OTTHRSTYPE field.
union all
Select distinct  COMPANYNUMBER,convert(varchar(10),DEDNUMBER) as CMSDedCode ,'A' as CMSCode from CV_CMS_SOURCE.dbo.PRTMAJ 
union all
Select distinct  COMPANYNUMBER,convert(varchar(10),BENEFITNUMBER) as CMSDedCode, 'H' as CMSCode from CV_CMS_SOURCE.dbo.HRTMBN
-- this last select stmt may need to be removed, it was originally used for Negative Earnings(401k)
-- now that we have Pre Tax Deductions they may need to be on the Deduction xref.
) as x

	
GO
