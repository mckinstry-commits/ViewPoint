SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
Copyright © 2011 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
      Title:      UD table setup for Cross Reference: GL Journals
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark
      Revisions:  
			1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
				--declare @datecreated smalldate time set @datecreated=getdate()
				and added code for the UserNotes.
			2. 08/10/2011 BBA - Added Notes column.  
			3. 10/28/2011 BBA - Added NewYN column.
			4. 11/01/2011 BBA - Added Lookup for JCCo and VPGLJournals columns.
			5. 01/27/2012 MTG - Modified for use in CGC Conversions
			6. 01/27/2012 MTG - Modified for use on CGC Conversions
			
      Notes:      This procedure creates a UD table and form for the GL Journals Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefGLJournals]
(@datecreated smalldatetime)

AS 

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefGLJournals')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefGLJournals(
            CMSCode varchar(2) not null, 
			GLJrnl varchar(2) null, 
			Source varchar(20) null,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefGLJournals'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefGLJournals','Cross Ref: GL Journals','1','Y',NULL,'udxrefGLJournals',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefGLJournals','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefGLJournals'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefGLJournals','5000','udxrefGLJournals','CMSCode','CMS Code',NULL,'0','2',NULL,NULL,'Y','6',NULL,'2','0','N','CMS Code','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLJournals','5005','udxrefGLJournals','GLJrnl','VP Journal','bJrnl',NULL,NULL,NULL,'1','Y','6','0,0,112,20','4','0','N','VP Journal','Y','Y','0',NULL,'Y','-1','0')
      ,('udxrefGLJournals','5010','udxrefGLJournals','Source','Source',NULL,'0','20',NULL,'1','N','6','28,0,213,20','4','0','N','Source','Y','Y','0',NULL,NULL,NULL,NULL)
      

--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefGLJournals'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefGLJournals', 0,    'Grid',     0)
      ,('udxrefGLJournals', 1,    'Info',     1)
      


--SOURCE:  select Form, Seq, GridCol, VPUserNamefrom vDDUI where Form='udxrefGLJournals'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefGLJournals', 5000, 0,    'viewpointcs')
      ,('udxrefGLJournals', 5005, 1,    'viewpointcs')
      ,('udxrefGLJournals', 5010, 2,    'viewpointcs')
      

            
--SOURCE: 
/*          
            select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType from bUDTC where TableName='udxrefGLJournals' order by DDFISeq
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefGLJournals','CMSCode','CMS Code','1',NULL,'0','2',NULL,'6','5000',NULL,NULL)
      ,( 'udxrefGLJournals','GLJrnl','VP Journal',NULL,NULL,'0','2',NULL,'6','5005','0',NULL)
      ,( 'udxrefGLJournals','Source','Source',NULL,NULL,'0','2',NULL,'6','5010','0',NULL)
      
      
      
--SOURCE:  select * from bUDTH where TableName='udxrefGLJournals'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefGLJournals', 'Cross Ref: GL Journals', 'udxrefGLJournals', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefGLJournals'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefGLJournals','Y');


--SOURCE:  select Seq, CustomControlSize from DDFIc where Form='udxrefGLJournals'
update DDFIc 
set   CustomControlSize=case
            when Seq=5005 then '70,49'
            when Seq=5010 then '70,143'
            else null 
      end
where DDFIc.Form='udxrefGLJournals'



/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefGLJournals as select a.* From budxrefGLJournals a;

-- Insert values into new ud table

insert into Viewpoint.dbo.budxrefGLJournals

select distinct left(JOURNALCTL,2) , NULL, NULL from CV_CMS_SOURCE.dbo.GLTPST
      
GO
