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
      Title:      UD table setup for Cross Reference: JC Cost Types
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark
      Revisions:  1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
                        --declare @datecreated smalldate time set @datecreated=getdate()
                        and added code for the UserNotes.
                        2. 08/10/2011 BBA - Added Notes column. 
                        3. 09/28/2011 BBA - Added Seq for multiple co conversions.              
                        4. 10/28/2011 BBA - Added NewYN column. 
                        5. 11/01/2011 BBA - Added Lookup for PhaseGroup and CostType columns.
                        6. 01/27/2012 MTG - Modified for use on CGC Conversions
                        7. 03/19/2012 BBA - Added Drop code.
      Notes:      
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefCostType]
(@datecreated smalldatetime)

AS 

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefCostType')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefCostType(
            Company     tinyint     not null, 
            CMSCostType varchar(1)  not null, 
            VPCo		tinyint		not null,
            CostType    tinyint     null,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL,
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefCostType'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefCostType','Cross Ref: JC Cost Type','1','Y',NULL,'udxrefCostType',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefCostType','N')


--SOURCE:  
/*
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq
from vDDFIc where Form='udxrefCostType'
*/

insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefCostType','5000','udxrefCostType','Company','Company in CGC','bJCCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company in CGC','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefCostType','5005','udxrefCostType','CMSCostType','Cost Type in CGC',NULL,'0','1',NULL,NULL,'Y','6',NULL,'2','0','N','Cost Type in CGC','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefCostType','5010','udxrefCostType','VPCo','Company in VP','bJCCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company in VP','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefCostType','5015','udxrefCostType','CostType','Cost Type in VP','bJCCType',NULL,NULL,NULL,'1','N','6',NULL,'4','0','N','Cost Type in VP','Y','Y',NULL,NULL,'Y','5010','0')

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefCostType'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefCostType', 0,    'Grid',     0)
      ,('udxrefCostType', 1,    'Info',     1)
            


--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefCostType'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefCostType', 5000, 0,    'viewpointcs')
      ,('udxrefCostType', 5005, 1,    'viewpointcs')
      ,('udxrefCostType', 5010, 2,    'viewpointcs')
      ,('udxrefCostType', 5015, 3,    'viewpointcs')
            

--SOURCE:  
/*
select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
AutoSeqType, ComboType
from bUDTC where TableName='udxrefCostType'
*/

insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefCostType','Company','Company','1','bJCCo',NULL,NULL,NULL,'6','5000','0',NULL)
      ,( 'udxrefCostType','CMSCostType','Cost Type in CGC','2',NULL,'0','0',NULL,'6','5005','0',NULL)
      , ( 'udxrefCostType','VPCo','VP Co','3','bJCCo',NULL,NULL,NULL,'6','5010','0',NULL) 
      ,( 'udxrefCostType','CostType','Cost Type in VP',NULL,'bJCCType',NULL,NULL,NULL,'6','5015',NULL,NULL)

      
--SOURCE:  select * from bUDTH where TableName='udxrefCostType'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefCostType', 'Cross Ref: JC Cost Type', 'udxrefCostType', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefCostType'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefCostType','Y');
      
/* no custom sizing needed
--SOURCE:  select Seq, CustomControlSize, ColumnName from DDFIc where Form='udxrefCostType'
update DDFIc 
set CustomControlSize=
      case
            when Seq=5005 then '86,91'    
            when Seq=5010 then '89,45'
            when Seq=5015 then '81,253'
            when Seq=5025 then '73,255'
            when Seq=5030 then '80,121'
            when Seq=5035 then '77,34'
            when Seq=5040 then '94,153'
            when Seq=5045 then '0,75'
            else null 
      end
where DDFIc.Form='udxrefCostType'
*/

/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefCostType as select a.* From budxrefCostType a;


-- Insert values into new ud table

insert into  Viewpoint.dbo.budxrefCostType

select distinct COMPANYNUMBER, COSTTYPE ,COMPANYNUMBER + 100,Null,Null
from CV_CMS_SOURCE.dbo.APTOPD
GO
