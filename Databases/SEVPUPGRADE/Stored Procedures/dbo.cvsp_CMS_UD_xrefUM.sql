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
      Title:      UD table setup for Cross Reference: Unit of Measure
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark
      Revisions:  
			1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
				--declare @datecreated smalldate time set @datecreated=getdate()
				and added code for the UserNotes.
			2. 08/10/2011 BBA - Added Notes column in create table.  
			3. 09/12/2011 BBA - Added control positions and changed NewYN to checkbox.
			4. 10/20/2011 BBA - Fixed issue with Seq field needed to be an int.
			5. 1/21/2012  MTG - Changed to accomodate CGC Conversion
			6. 01/27/2012 MTG - Modified for use on CGC Conversions

      Notes:      This procedure creates a UD table and form for the Unit of Measure
                  Cross Reference.
                  
      IMPORTANT: IF CLIENT HAS SQL 2005, THIS PROCEDURE WILL NOT INSTALL AUTOMATICALLY.
      THE UD TABLE HAS TO BE EITHER SETUP MANUALLY IN VIEWPOINT OR YOU CAN RUN THIS MANUALLY
      BUT YOU MUST ONLY RUN THE INSERTS FOR ONE VALUE AT A TIME. (See Brenda or Jim for an example.)

**/

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefUM]
(@datecreated smalldatetime)

AS 

/* Create the ud table */
if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefUM')
BEGIN
CREATE TABLE Viewpoint.dbo.budxrefUM(
            CGCUM varchar(10)not null, 
            VPUM  varchar(3)   null,
            UniqueAttchID uniqueidentifier NULL,
            KeyID bigint IDENTITY(1,1) NOT NULL
            );
END
      
      
/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from Viewpoint.dbo.vDDFHc where Form='udxrefUM'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefUM','Cross Ref: UM','1','Y',NULL,'udxrefUM',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefUM','N')


--SOURCE: 
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefUM'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)
values
      ('udxrefUM','5000','udxrefUM','CGCUM','UM in CGC',NULL,'0','2',NULL,NULL,'Y','6',NULL,'2','0','N','UM in CGC','Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udxrefUM','5005','udxrefUM','VPUM','UM in VP','bUM',NULL,NULL,NULL,'1','N','6',NULL,'4','0','N','UM in VP','Y','Y',NULL,NULL,NULL,'Y','101') 
      
--SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefUM'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefUM', 0,    'Grid',     0)
      ,('udxrefUM', 1,    'Info',     1)

      

--SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefUM'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ('udxrefUM', 5000, 0,    'viewpointcs')
      ,('udxrefUM', 5005, 1,    'viewpointcs')
            
      
      
--SOURCE: 
/*
select TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType  from bUDTC where TableName='udxrefUM'
*/
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
      ( 'udxrefUM','CGCUM','UM in CGC','1',NULL,'0','2',NULL,'6','5000',NULL,NULL)
      ,( 'udxrefUM','VPUM','UM in VP',NULL,'bUM',NULL,NULL,NULL,'6','5005',NULL,NULL)     
      
      
--SOURCE:  select * from bUDTH where TableName='udxrefUM'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefUM', 'Cross Ref: UM', 'udxrefUM', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');


--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefUM'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefUM','Y');

/*No Control size needed
--SOURCE:  select Seq, CustomControlSize from DDFIc where Form='udxrefUM'
update DDFIc 
set ControlPosition=
      case
            when Seq=5020 then '0,75'           
            else null 
      end
where DDFIc.Form='udxrefUM'
*/

/* CREATE VIEW */
--RUN MANUALLY:
--      CREATE VIEW dbo.udxrefUM as select a.* From budxrefUM a;

-- Insert into the new ud Table

insert into Viewpoint.dbo.budxrefUM
select distinct UNITOFMEASURE, Null, Null from CV_CMS_SOURCE.dbo.JCTMST
where UNITOFMEASURE<>''


GO
