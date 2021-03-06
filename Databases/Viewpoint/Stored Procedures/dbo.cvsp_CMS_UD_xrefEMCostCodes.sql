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
      Title:      UD table setup for Cross Reference: EM Cost Codes
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
        
      Notes:      This procedure creates a UD table and form for the EM Cost Codes
                  Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

Create PROCEDURE [dbo].[cvsp_CMS_UD_xrefEMCostCodes]
(@datecreated smalldatetime)

AS

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefEMCostCodes')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefEMCostCodes(
            CMSComponent varchar(3) NOT NULL,
            CostCode  varchar(10) NULL,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from Viewpoint.vDDFHc where Form='udxrefEMCostCodes'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefEMCostCodes','Cross Ref: EM Cost Codes','1','Y',NULL,'udxrefEMCostCodes',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefEMCostCodes','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from Viewpoint.dbo.vDDFIc where Form='udxrefEMCostCodes'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefEMCostCodes','5000','udxrefEMCostCodes','CMSComponent','CMS Component',NULL,'0','3',NULL,NULL,'Y','6',NULL,'2','0','N','CMS Component','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefEMCostCodes','5005','udxrefEMCostCodes','CostCode','VP Cost Code','bCostCode',NULL,NULL,NULL,'1','N','6',NULL,'4','0','N','VP Cost Code','Y','Y','0',NULL,'Y','-1','0')
      
      

--SOURCE:  select Form, Tab, Title, LoadSeq from Viewpoint.dbo.vDDFTc where Form='udxrefEMCostCodes'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefEMCostCodes', 0,    'Grid',     0)
      ,('udxrefEMCostCodes', 1,    'Info',     1)
      

--SOURCE:  select Form, Seq, GridCol, VPUserName from Viewpoint.dbo.vDDUI where Form='udxrefEMCostCodes'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefEMCostCodes', 5000, 0,    'viewpointcs')
      ,('udxrefEMCostCodes', 5005, 1,    'viewpointcs')
      
      
--SOURCE:         
/*          
            select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType from Viewpoint.dbo.bUDTC where TableName='udxrefEMCostCodes' order by DDFISeq
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefEMCostCodes','CMSComponent','CMS Component','1',NULL,'0','3',NULL,'6','5000','0', NULL)
      ,( 'udxrefEMCostCodes','CostCode','VP Cost Code',NULL,NULL,'0','10',NULL,'6','5005','0',NULL)
      
      
--SOURCE:  select * from Viewpoint.dbo.bUDTH where TableName='udxrefEMCostCodes'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefEMCostCodes', 'Cross Ref: EM Cost Codes', 'udxrefEMCostCodes', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from Viewpoint.dbo.vDDMFc where Form='udxrefEMCostCodes'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefEMCostCodes','Y');

/*No custom sizing needed
--SOURCE:  select Seq,CustomControlSize from Viewpoint.dbo.DDFIc where Form='udxrefEMCostCodes'
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
where DDFIc.Form='udxrefEMCostCodes'
*/

/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW Viewpoint.dbo.udxrefEMCostCodes as select a.* from Viewpoint.dbo.budxrefEMCostCodes a;

------- Insert values from CMS to populate the table---
insert into Viewpoint.dbo.budxrefEMCostCodes
select distinct 'COMPONENTNO03',null,null  from CV_CMS_SOURCE.dbo.EQPDTL
GO
