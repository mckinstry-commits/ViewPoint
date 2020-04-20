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
      Title:      UD table setup for Cross Reference: GL Sub Ledgers
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark
      Revisions:  
		1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
			--declare @datecreated smalldate time set @datecreated=getdate()
			and added code for the UserNotes.
        2. 08/10/2011 BBA - Added Notes column.
        3. 09/12/2011 BBA - Added Seq to prevent duplicates and multiple data folders. 
        4. 10/28/2011 BBA - Added NewYN column.
        5. 11/01/2011 BBA - Added Lookup for PRCo and NewDepartment.
        6. 11/21/2011 BBA - Added Notes to create table.
        7. 01/12/2012 MTG - updated for use in CGC
        8. 03/19/2012 BBA - Added Drop code.       
        
      Notes:      This procedure creates a UD table and form for the GL Sub Ledgers
                  Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefGLSubLedger]
(@datecreated smalldatetime)

AS

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefGLSubLedger')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefGLSubLedger(
            Company tinyint NOT NULL,
            oldAppCode  varchar(1) NOT NULL,
            newSubLedgerCode varchar(1) NULL,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefGLSubLedger'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefGLSubLedger','Cross Ref: GL Sub Ledgers','1','Y',NULL,'udxrefGLSubLedger',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefGLSubLedger','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefGLSubLedger'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefGLSubLedger','5000','udxrefGLSubLedger','Company','Company','bGLCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLSubLedger','5005','udxrefGLSubLedger','oldAppCode','CMS App Code',NULL,'0','1',NULL,NULL,'Y','6',NULL,'2','0','N','CMS App Code','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLSubLedger','5010','udxrefGLSubLedger','newSubLedgerCode','VP Sub Ledger',NULL,'0','1',NULL,'1','N','6',NULL,'4','0','N','VP Sub Ledger','Y','Y','0',NULL,NULL,NULL,NULL)
      

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefGLSubLedger'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefGLSubLedger', 0,    'Grid',     0)
      ,('udxrefGLSubLedger', 1,    'Info',     1)
      

--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefGLSubLedger'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefGLSubLedger', 5000, 0,    'viewpointcs')
      ,('udxrefGLSubLedger', 5005, 1,    'viewpointcs')
      ,('udxrefGLSubLedger', 5010, 2,    'viewpointcs')
      
--SOURCE:         
/*          
            select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType from bUDTC where TableName='udxrefGLSubLedger' order by DDFISeq
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
       ( 'udxrefGLSubLedger','Company','Company','1','bGLCo',NULL,NULL,NULL,'6','5000','0', NULL)
      ,( 'udxrefGLSubLedger','oldAppCode','oldAcctType','2',NULL,'0','3',NULL,'6','5005','0',NULL)
      ,( 'udxrefGLSubLedger','newSubLedgerCode','newAcctType',NULL,NULL,'0','1',NULL,'6','5010','0',NULL)
      
--SOURCE:  select * from bUDTH where TableName='udxrefGLSubLedger'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefGLSubLedger', 'Cross Ref: EM Cost Codes', 'udxrefGLSubLedger', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefGLSubLedger'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefGLSubLedger','Y');

/*No custom sizing needed
--SOURCE:  select Seq,CustomControlSize from DDFIc where Form='udxrefGLSubLedger'
update DDFIc 
set  CustomControlSize=
      case
            when Seq=5005 then '97,97'    
            when Seq=5010 then '94,348'
            when Seq=5015 then '43,47'
            when Seq=5020 then '102,98'
            when Seq=5025 then '99,350'
            when Seq=5030 then '0,75'
            when Seq=5035 then '0,75'
            else null 
      end
where DDFIc.Form='udxrefGLSubLedger'
*/

/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefGLSubLedger as select a.* From budxrefGLSubLedger a;

------- Insert values from CMS to populate the table---
--select * from  Viewpoint.dbo.budxrefGLSubLedger
insert into Viewpoint.dbo.budxrefGLSubLedger
select distinct COMPANYNUMBER, oldAppCode=GLAPPLCODE, 
	newSubLedger=case when GLAPPLCODE=0 then null
				when GLAPPLCODE=1 then 'J'
				when GLAPPLCODE=2 then 'J'
				when GLAPPLCODE=3 then 'P'
				when GLAPPLCODE=4 then 'R'
				when GLAPPLCODE=5 then 'I'
				when GLAPPLCODE=6 then 'E'
			 end,NULL
from CV_CMS_SOURCE.dbo.GLTMST
GO
