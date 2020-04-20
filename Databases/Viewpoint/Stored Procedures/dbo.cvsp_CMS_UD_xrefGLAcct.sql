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
      Title:      UD table setup for Cross Reference: GL Account
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark
      Revisions:  
		1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
			--declare @datecreated smalldate time set @datecreated=getdate()
			and added code for the UserNotes.
        2. 08/10/2011 BBA - Added Notes column in create table.
        3. 09/06/2011 BBA - Changed OldCo to not be a key and set to varchar(4).
        4. 10/28/2011 BBA - Corrected size and type of fields. 
        5. 11/01/2011 BBA - Added Lookup for NewCo and NewAccountID columns.
        6. 01/27/2012 MTG - Modified for use on CGC Conversions

      Notes:      This procedure creates a UD table and form for the GL Account Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefGLAcct]
(@datecreated smalldatetime)

AS 

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefGLAcct')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefGLAcct
            (Company smallint not null, 
            oldGLAcct varchar(30) not null, 
            newGLAcct varchar(20) null,
            Description varchar(30) null,
            Notes dbo.bNotes NULL,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );

END

      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from Viewpoint.dbo.vDDFHc  where Form='udxrefGLAcct'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefGLAcct','Cross Ref: GL Account','1','Y',NULL,'udxrefGLAcct',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefGLAcct','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq
from Viewpoint.dbo.vDDFIc where Form='udxrefGLAcct'
*/

insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefGLAcct','5000','udxrefGLAcct','Company','Company','bGLCo',NULL,NULL,NULL,NULL,'Y','6',Null,'2','0','N','Company','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLAcct','5005','udxrefGLAcct','oldGLAcct','CMS GL Acct',NULL,'0','30',NULL,NULL,'Y','6',NULL,'2','0','N','CMS GL Acct','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLAcct','5010','udxrefGLAcct','newGLAcct','VP GL Acct','bGLAcct',NULL,NULL,NULL,'1','N','6','1,1,259,20','4','0','N','VP GL Acct','Y','Y','0',NULL,NULL,NULL,NULL)
      ,('udxrefGLAcct','5015','udxrefGLAcct','Description','Description',NULL,'0','30',NULL,'1','N','6','33,0,263,20','4','0','N','Description','Y','Y',NULL,NULL,NULL,NULL,NULL)
     


--SOURCE:  select Form, Tab, Title, LoadSeq from Viewpoint.dbo.vDDFTc where Form='udxrefGLAcct'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefGLAcct', 0,    'Grid',     0)
      ,('udxrefGLAcct', 1,    'Info',     1)
 


--SOURCE:  select Form, Seq, GridCol, VPUserName from Viewpoint.dbo.vDDUI where Form='udxrefGLAcct'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefGLAcct', 5000, 0,    'viewpointcs')
      ,('udxrefGLAcct', 5005, 1,    'viewpointcs')
      ,('udxrefGLAcct', 5010, 2,    'viewpointcs')
      ,('udxrefGLAcct', 5015, 3,    'viewpointcs')
 

            
--SOURCE:  
/*
select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType 
from Viewpoint.dbo.bUDTC  where TableName='udxrefGLAcct'
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefGLAcct','Company','Company','1','bGLCo',NULL,NULL,NULL,'6','5000','0',NULL)
      ,( 'udxrefGLAcct','oldGLAcct','CMS GL Acct','2',NULL,'0','30',NULL,'6','5005','0',NULL)
      ,( 'udxrefGLAcct','newGLAcct','VP GL Acct',NULL,'bGLAcct',NULL,NULL,NULL,'6','5010','0',NULL)    
      ,( 'udxrefGLAcct','Description','Description',NULL,NULL,'0','30',NULL,'6','5015',NULL,NULL)        

      
      
      
--SOURCE:  select * from bUDTH where TableName='udxrefGLAcct'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefGLAcct', 'Cross Ref: GL Account', 'udxrefGLAcct', 'N', 'viewpointcs', @datecreated, 'Y', 'N',  0, 'Y');


--SOURCE:  select Mod, Form, Active from Viewpoint.dbo.vDDMFc where Form='udxrefGLAcct'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefGLAcct','Y');


--SOURCE:  select Seq, ColumnName, CustomControlSize from Viewpoint.dbo.DDFIc  where Form='udxrefGLAcct'
update Viewpoint.dbo.DDFIc 
set CustomControlSize=
      case
            when Seq=5010 then '72,187'
            
            else null 
      end
where DDFIc.Form='udxrefGLAcct'


/* CREATE VIEW - must be run manually in the Viewpoint database */
--RUN MANUALLY:
--      CREATE VIEW udxrefGLAcct as select a.* From Viewpoint.dbo.budxrefGLAcct a;
--select * from Viewpoint.dbo.udxrefGLAcct
--insert into Viewpoint.dbo.budxrefGLAcct
select distinct MSCONO, MSGLAN,NULL,left(MSD25A,30),  null, null
from CV_CMS_SOURCE.dbo.GLPMST

--select * from Viewpoint.dbo.budxrefGLAcct
-- select * from Viewpoint.dbo.udxrefGLAcct
GO
