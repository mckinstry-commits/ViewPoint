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
      Title:      UD table setup for Cross Reference: GL Account Types
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
 
      Notes:      This procedure creates a UD table and form for the GL Account Types
                  Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefGLAcctTypes]
(@datecreated smalldatetime)

AS

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefGLAcctTypes')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefGLAcctTypes(
            Company varchar(3) NOT NULL,
            oldAcctType  varchar(3) NOT NULL,
            newAcctType varchar(1) NULL,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefGLAcctTypes'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefGLAcctTypes','Cross Ref: GL Acct Types','1','Y',NULL,'udxrefGLAcctTypes',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefGLAcctTypes','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefGLAcctTypes'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefGLAcctTypes','5000','udxrefGLAcctTypes','Company','Company','bGLCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLAcctTypes','5005','udxrefGLAcctTypes','oldAcctType','CMS Acct Type',NULL,'0','3',NULL,NULL,'Y','6',NULL,'2','0','N','CMS Acct Type','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLAcctTypes','5010','udxrefGLAcctTypes','newAcctType','VP Acct Type',NULL,'0','1',NULL,'1','N','6',NULL,'4','0','N','VP Acct Type','Y','Y','0',NULL,NULL,NULL,NULL)
      

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefGLAcctTypes'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefGLAcctTypes', 0,    'Grid',     0)
      ,('udxrefGLAcctTypes', 1,    'Info',     1)
      

--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefGLAcctTypes'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefGLAcctTypes', 5000, 0,    'viewpointcs')
      ,('udxrefGLAcctTypes', 5005, 1,    'viewpointcs')
      ,('udxrefGLAcctTypes', 5010, 2,    'viewpointcs')
      
--SOURCE:         
/*          
            select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType from bUDTC where TableName='udxrefGLAcctTypes' order by DDFISeq
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefGLAcctTypes','Company','Company','1','bGLCo',NULL,NULL,NULL,'6','5000','0', NULL)
      ,( 'udxrefGLAcctTypes','oldAcctType','CMS Acct Type','2',NULL,'0','3',NULL,'6','5005','0',NULL)
      ,( 'udxrefGLAcctTypes','newAcctType','VP Acct Type',NULL,NULL,'0','1',NULL,'6','5010','0',NULL)
      
--SOURCE:  select * from bUDTH where TableName='udxrefGLAcctTypes'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefGLAcctTypes', 'Cross Ref: EM Cost Codes', 'udxrefGLAcctTypes', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefGLAcctTypes'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefGLAcctTypes','Y');

/*No custom sizing needed
--SOURCE:  select Seq,CustomControlSize from DDFIc where Form='udxrefGLAcctTypes'
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
where DDFIc.Form='udxrefGLAcctTypes'
*/

/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefGLAcctTypes as select a.* From budxrefGLAcctTypes a;

------- Insert values from CMS to populate the table---

--insert into Viewpoint.dbo.budxrefGLAcctTypes

--select distinct COMPANYNUMBER, GLACCTTYPE--, 
--	--newAcctType=case when GLACCTTYPE='AS' then 'A'
--	--			when GLACCTTYPE='CA' then 'C'
--	--			when GLACCTTYPE='EX' then 'E'
--	--			when GLACCTTYPE='IC' then 'I'
--	--			when GLACCTTYPE='LI' then 'L'
--	--			else 'E' end, null
			
--from CV_CMS_SOURCE.dbo.GLTMST
GO
