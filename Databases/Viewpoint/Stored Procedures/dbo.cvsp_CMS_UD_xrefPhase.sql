
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
      Title:      UD table setup for Cross Reference: JC Phase
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
 
      Notes:      This procedure creates a UD table and form for the JC Phase
                  Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefPhase]
(@datecreated smalldatetime)

AS

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefPhase')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefPhase(
            Company tinyint NOT NULL,
            oldPhase varchar(15) NOT NULL,
            VPCo tinyint not null,
            newPhase  dbo.bPhase NULL,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefPhase'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefPhase','Cross Ref: Phase','1','Y',NULL,'udxrefPhase',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefPhase','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefPhase'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefPhase','5000','udxrefPhase','Company','Company','bPRCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company','Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udxrefPhase','5005','udxrefPhase','oldPhase','CMS Code',NULL,'0','15',NULL,NULL,'Y','6',NULL,'2','0','N','CMS Code','Y','Y',NULL,NULL,NULL,NULL,NULL)
     , ('udxrefPhase','5010','udxrefPhase','VPCo','VPCompany','bPRCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','VP Company','Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udxrefPhase','5015','udxrefPhase','newPhase','Phase in VP','bPhase',NULL,NULL,NULL,'1','N','6',NULL,'4','0','N','Phase in VP','Y','Y',NULL,NULL,'Y','5010','0')
      

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefPhase'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefPhase', 0,    'Grid',     0)
      ,('udxrefPhase', 1,    'Info',     1)
      

--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefPhase'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefPhase', 5000, 0,    'viewpointcs')
      ,('udxrefPhase', 5005, 1,    'viewpointcs')
      ,('udxrefPhase', 5010, 2,    'viewpointcs')
       ,('udxrefPhase', 5015, 2,    'viewpointcs')
--SOURCE:         
/*          
            select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType from bUDTC where TableName='udxrefPhase' order by DDFISeq
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefPhase','Company','Company','1','bJCCo',NULL,NULL,NULL,'6','5000',NULL,NULL)
      ,( 'udxrefPhase','oldPhase','CMS Code','2',NULL,'0','15',NULL,'6','5005',NULL,NULL)
      , ( 'udxrefPhase','VPCo','VP Company','3','bJCCo',NULL,NULL,NULL,'6','5010',NULL,NULL)
      ,( 'udxrefPhase','newPhase','Phase in VP',NULL,'bPhase',NULL,NULL,NULL,'6','5015',NULL,NULL)
      
      
--SOURCE:  select * from bUDTH where TableName='udxrefPhase'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefPhase', 'Cross Ref: PR Dept', 'udxrefPhase', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefPhase'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefPhase','Y');

/*No custom sizing needed
--SOURCE:  select Seq,CustomControlSize from DDFIc where Form='udxrefPhase'
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
where DDFIc.Form='udxrefPhase'
*/

/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefPhase as select a.* From budxrefPhase a;


/**********************************************

added the inner join to CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion
this is the view that contains the jobs to convert. CR 7/17/13
 
***********************************************/
declare @PhaseFormat varchar(30)
Set @PhaseFormat =  (Select InputMask from vDDDTc where Datatype = 'bPhase');
--- Insert values from CMS to populate the table---

insert into  Viewpoint.dbo.budxrefPhase

select  distinct x.COMPANYNUMBER, ltrim(rtrim(JCDISTRIBTUION)),x.COMPANYNUMBER + 100,newphase , null

from 
(select Distinct p.COMPANYNUMBER, JCDISTRIBTUION, 
dbo.bfMuliPartFormat(substring(LTRIM(RTRIM(JCDISTRIBTUION)),1,16),@PhaseFormat) as newphase
from CV_CMS_SOURCE.dbo.JCTPST p 
INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = p.COMPANYNUMBER
		AND jobs.JOBNUMBER     = p.JOBNUMBER
		and jobs.SUBJOBNUMBER  = p.SUBJOBNUMBER

union all

select Distinct  j.COMPANYNUMBER, JCDISTRIBTUION, 
dbo.bfMuliPartFormat(substring(LTRIM(RTRIM(JCDISTRIBTUION)),1,16),@PhaseFormat) as newphase
from CV_CMS_SOURCE.dbo.JCTMST j  
INNER JOIN CV_CMS_SOURCE.dbo.cvspMcKCGCActiveJobsForConversion jobs 
		ON	jobs.COMPANYNUMBER = j.COMPANYNUMBER
		AND jobs.JOBNUMBER     = j.JOBNUMBER
		and jobs.SUBJOBNUMBER  = j.SUBJOBNUMBER
) x
where newphase <>''

GO
