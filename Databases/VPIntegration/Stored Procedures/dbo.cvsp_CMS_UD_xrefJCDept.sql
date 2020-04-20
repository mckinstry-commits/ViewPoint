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
      Title:      UD table setup for Cross Reference: JC Department
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark
      Revisions:  
			1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
				--declare @datecreated smalldate time set @datecreated=getdate()
				and added code for the UserNotes.
			2. 08/10/2011 BBA - Added Notes column.  
			3. 10/28/2011 BBA - Added NewYN column.
			4. 11/01/2011 BBA - Added Lookup for JCCo and VPJCDept columns.
			5. 01/27/2012 MTG - Modified for use in CGC Conversions
			6. 01/27/2012 MTG - Modified for use on CGC Conversions
            7. 03/19/2012 BBA - Added Drop code.
 
      Notes:      This procedure creates a UD table and form for the JC Department Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefJCDept]
(@datecreated smalldatetime)

AS 

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefJCDept')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefJCDept(
            Company     tinyint     not null, 
            CMSDept     varchar(10)not null,
            VPCo		tinyint		not null, 
            VPDept      varchar(10) null,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefJCDept'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefJCDept','Cross Ref: JC Dept','1','Y',NULL,'udxrefJCDept',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefJCDept','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefJCDept'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefJCDept','5000','udxrefJCDept','Company','Company','bJCCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company','Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udxrefJCDept','5005','udxrefJCDept','CMSDept','CMS Dept',NULL,'0','10',NULL,NULL,'Y','6',NULL,'2','0','N','CMS Dept','Y','Y','0',NULL,NULL,NULL,NULL)
     ,('udxrefJCDept','5010','udxrefJCDept','VPCo','VP Company','bJCCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','VP Company','Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udxrefJCDept','5015','udxrefJCDept','VPDept','VP Dept','bDept',NULL,NULL,NULL,'1','N','6',NULL,'4','0','N','VP Dept','Y','Y','0',NULL,'Y','5010','0')
      

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefJCDept'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefJCDept', 0,    'Grid',     0)
      ,('udxrefJCDept', 1,    'Info',     1)
      


--SOURCE:  select Form, Seq, GridCol, VPUserNamefrom vDDUI where Form='udxrefJCDept'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefJCDept', 5000, 0,    'viewpointcs')
      ,('udxrefJCDept', 5005, 1,    'viewpointcs')
      ,('udxrefJCDept', 5010, 2,    'viewpointcs')
      ,('udxrefJCDept', 5015, 3,    'viewpointcs')
      

            
--SOURCE: 
/*          
            select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType from bUDTC where TableName='udxrefJCDept' order by DDFISeq
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefJCDept','Company','Company','1','bJCCo',NULL,NULL,NULL,'6','5000',NULL,NULL)
      ,( 'udxrefJCDept','CMSDept','CMS Dept','2',NULL,'0','10',NULL,'6','5005','0',NULL)
      ,( 'udxrefJCDept','VPCo','VP Company','3','bJCCo',NULL,NULL,NULL,'6','5010',NULL,NULL)
       ,( 'udxrefJCDept','VPDept','VP Dept',NULL,'bDept',NULL,NULL,NULL,'6','5015','0',NULL)
      
      
--SOURCE:  select * from bUDTH where TableName='udxrefJCDept'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefJCDept', 'Cross Ref: JC Dept', 'udxrefJCDept', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefJCDept'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefJCDept','Y');

/* no control size necessary
--SOURCE:  select Seq, CustomControlSize from DDFIc where Form='udxrefJCDept'
update DDFIc 
set   CustomControlSize=case
            when Seq=5005 then '89,343'
            when Seq=5010 then '42,43'
            when Seq=5015 then '72,119'
            when Seq=5020 then '89,270'
            when Seq=5025 then '101,122'
            when Seq=5030 then '0,75'
            else null 
      end
where DDFIc.Form='udxrefJCDept'
*/


/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefJCDept as select a.* From budxrefJCDept a;

-- Insert values into new ud table

insert into Viewpoint.dbo.budxrefJCDept

select distinct COMPANYNUMBER,DEPARTMENTNO ,COMPANYNUMBER+100, NULL, NULL
      from CV_CMS_SOURCE.dbo.JCTDSC
      
GO
