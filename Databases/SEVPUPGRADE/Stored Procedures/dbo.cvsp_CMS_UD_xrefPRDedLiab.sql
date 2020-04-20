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
      Title: UD table setup for Cross Reference: PR Deductions & Liabilities
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark
      Revisions:  
			1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
				--declare @datecreated smalldate time set @datecreated=getdate()
				and added code for the UserNotes.
			2. 08/10/2011 BBA - Added Notes column. 
			3. 10/28/2011 BBA - Added NewYN column.
			4. 11/01/2011 BBA - Added Lookup for PRCo, NewDLCode and NewLiabType and changed
			the type for NewLiabType to bLiabilityType.
			5. 11/21/2011 BBA - Added Notes column to Create Table.     
			6. 1/26/2012 MTG - Modified for use in CGC

      Notes:      This procedure creates a UD table and form for the PR Deductions & Liabilities
                  Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)
**/


--truncate table Viewpoint.dbo.budxrefPRDedLiab
CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefPRDedLiab]
(@datecreated smalldatetime)

AS 


/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefPRDedLiab')
BEGIN

CREATE TABLE Viewpoint.dbo.budxrefPRDedLiab
(
      CMSDedCode    int                  NOT NULL,
      CMSDedType    varchar(1)           NOT NULL,
      CMSUnion      varchar(10)          NOT NULL,
      Company       dbo.bCompany         NOT NULL,
      DLCode        dbo.bEDLCode         NULL,
      Description   varchar(30)          NULL,
      VPType		varchar(1)           NULL,
      UniqueAttchID uniqueidentifier     NULL,
      KeyID			bigint IDENTITY(1,1) NOT NULL
);

END




/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefPRDedLiab'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefPRDedLiab','Cross Ref: PR Deds & Liabs','1','Y',NULL,'udxrefPRDedLiab',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefPRDedLiab','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefPRDedLiab'
*/

--select * from vDDFIc where Form = 'udxrefPRDedLiab'
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
            
            /* Field Type 2=Required, 4=Not Required */
values
  ( 'udxrefPRDedLiab','5000','udxrefPRDedLiab','Company'    ,'Company'         ,'bPRCo'   ,NULL,NULL,NULL,NULL,'Y','6',NULL          ,'2','0','N','Company'         ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
  ,('udxrefPRDedLiab','5005','udxrefPRDedLiab','CMSDedCode' ,'CMS Ded Code'    ,NULL      ,'1' ,'4' ,'2' ,NULL,'Y','6',NULL          ,'2','0','N','CMS Ded Code'    ,'Y','Y','0' ,NULL,NULL,NULL,NULL)
  ,('udxrefPRDedLiab','5010','udxrefPRDedLiab','CMSDedType' ,'CMS Ded Type'    ,NULL      ,'0' ,'1' ,NULL,NULL,'Y','6',NULL          ,'2','0','N','CMSDedType'      ,'Y','Y','0' ,NULL,NULL,NULL,NULL)
  ,('udxrefPRDedLiab','5015','udxrefPRDedLiab','CMSUnion'   ,'CMS Union'       ,NULL      ,'0' ,'10',NULL,NULL,'N','6',NULL          ,'2','0','N','CMSUnion'        ,'Y','Y','0' ,NULL,NULL,NULL,NULL)
  ,('udxrefPRDedLiab','5020','udxrefPRDedLiab','DLCode'     ,'VP Code'         ,'bEDLCode',NULL,NULL,NULL,'1' ,'N','6','0,0,99,20'   ,'4','0','N','VP Code'         ,'Y','Y','0' ,NULL,NULL,NULL,NULL)
  ,('udxrefPRDedLiab','5025','udxrefPRDedLiab','VPType'     ,'VP Type (D or L)',NULL      ,'0' ,'1' ,NULL,'1' ,'N','6','2,133,136,20','4','0','N','VP Type (D or L)','Y','Y',NULL,NULL,NULL,NULL,NULL)
  ,('udxrefPRDedLiab','5030','udxrefPRDedLiab','Description','Description'     ,NULL      ,'0' ,'30',NULL,'1' ,'N','6','48,0,627,20' ,'4','0','N','Description'     ,'Y','Y',NULL,NULL,NULL,NULL,NULL)

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefPRDedLiab'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
       ('udxrefPRDedLiab', 0,    'Grid',     0)
      ,('udxrefPRDedLiab', 1,    'Info',     1)
            

--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefPRDedLiab'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
       ('udxrefPRDedLiab', 5000, 0,    'viewpointcs')
      ,('udxrefPRDedLiab', 5005, 1,    'viewpointcs')
      ,('udxrefPRDedLiab', 5010, 2,    'viewpointcs')
      ,('udxrefPRDedLiab', 5015, 3,    'viewpointcs')
      ,('udxrefPRDedLiab', 5020, 4,    'viewpointcs')
      ,('udxrefPRDedLiab', 5025, 5,    'viewpointcs')
      ,('udxrefPRDedLiab', 5030, 6,    'viewpointcs') 

            
--SOURCE:  
/*          
            select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType from bUDTC where TableName='udxrefPRDedLiab' order by DDFISeq
*/
--select * from bUDTC where TableName = 'udxrefPRDedLiab'
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values

       ( 'udxrefPRDedLiab' ,'Company'    ,'Company'         ,'1' ,'bPRCo'   ,NULL,NULL,NULL,'6' ,'5000',NULL,NULL)
      ,( 'udxrefPRDedLiab','CMSDedCode' ,'CMS Ded Code'    ,'2' ,NULL      ,'1' ,'4' ,'2' ,'6' ,'5005','0' ,NULL)
      ,( 'udxrefPRDedLiab','CMSDedType' ,'CMSDedType'      ,'3' ,NULL      ,'0' ,'1' ,NULL,'6' ,'5010','0' ,NULL)
      ,( 'udxrefPRDedLiab','CMSUnion'   ,'CMSUnion'        ,'4' ,NULL      ,'0' ,'10',NULL,'6' ,'5015','0' ,NULL)
      ,( 'udxrefPRDedLiab','DLCode'     ,'VP Code'         ,NULL,'bEDLCode',NULL,NULL,NULL,'6' ,'5020',NULL,NULL)
      ,( 'udxrefPRDedLiab','VPType'     ,'VP Type (D or L)',NULL,NULL      ,'0' ,'1' ,NULL,'6' ,'5025',NULL,NULL)
      ,( 'udxrefPRDedLiab','Description','Description'     ,NULL,NULL      ,'0' ,'30',NULL,'6' ,'5030',NULL,NULL)
      
  
      
      
--SOURCE:  select * from bUDTH where TableName='udxrefPRDedLiab'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefPRDedLiab', 'Cross Ref: PR Deds & Liabs', 'udxrefPRDedLiab', 'N', 'viewpointcs', @datecreated, 'Y', 'Y', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefPRDedLiab'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefPRDedLiab','Y');


--SOURCE:  select Seq, CustomControlSize from DDFIc where Form='udxrefPRDedLiab'
update Viewpoint.dbo.DDFIc 
set   CustomControlSize=
      case
            when Seq=5025 then '101,35'
            when Seq=5030 then '73,554'
            else null
      end
where Viewpoint.dbo.DDFIc.Form='udxrefPRDedLiab'


/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefPRDedLiab as select a.* From budxrefPRDedLiab a;


--- Insert values from CMS to populate the table---
--select * from Viewpoint.dbo.budxrefPRDedLiab
INSERT INTO Viewpoint.dbo.budxrefPRDedLiab (CMSDedCode, CMSDedType, CMSUnion, Company)

SELECT x.CMSDedCode, x.CMSDedType, x.CMSUnion, x.Company
FROM 
(SELECT DISTINCT 
  CMSDedType='M'
, CMSDedCode=DEDNUMBER
, CMSUnion=''
, Company=COMPANYNUMBER
FROM CV_CMS_SOURCE.dbo.PRTMED 
WHERE DEDNUMBER < 995 and COMPANYNUMBER = 1

UNION all

SELECT DISTINCT  
  CMSDedType =RECORDCODE
, CMSDedCode =DISTNUMBER
, CMSUnion=''
, Company=COMPANYNUMBER
FROM CV_CMS_SOURCE.dbo.PRTTCE 
WHERE DISTNUMBER < 995 and COMPANYNUMBER = 1
	and RECORDCODE <> 'U'

UNION all

SELECT DISTINCT
  CMSDedType = 'U'
, CMSDedCode = NUDTY
, CMSUnion=UNIONNO
, Company=COMPANYNUMBER
FROM CV_CMS_SOURCE.dbo.PRTMUN
WHERE NUDTY < 995 and COMPANYNUMBER = 1
) x


GO
