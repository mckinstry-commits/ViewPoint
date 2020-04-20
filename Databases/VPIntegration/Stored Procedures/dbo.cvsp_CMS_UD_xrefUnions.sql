SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefUnions]

AS

if not exists (select name from Viewpoint.dbo.sysobjects where name ='budxrefUnion')
begin
	create table Viewpoint.dbo.budxrefUnion
			(Company		smallint		not null, 
			CMSUnion		varchar(10)		null,
			CMSClass		varchar(10)		null,
			CMSType			varchar(10)		null,
			Craft			varchar(10)		null, 
			Class			varchar(10)		null,
			Description		varchar(30)		null,
			UniqueAttchID uniqueidentifier NULL,
			KeyID bigint IDENTITY(1,1) NOT NULL);
	--create unique clustered index ixrefPRUnions on 
	--	dbo.budxrefUnion(Company, Craft, Class, CMSUnion, CMSClass, CMSType);
end;


/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from vDDFHc where Form='udxrefUnion'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udxrefUnion','Cross Ref: PR Unions','1','Y',NULL,'udxrefUnion',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udxrefUnion','N')
;
--SOURCE: select * from vDDFIc where Form='udxrefUnion'
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from vDDFIc where Form='udxrefUnion'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)

 Values
       ('udxrefUnion','5000','udxrefUnion','Company'     ,'Company'     ,'bHQCo' ,NULL,NULL,NULL,NULL,'Y','6',NULL         ,'2','0','N','Company'      ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udxrefUnion','5005','udxrefUnion','CMSUnion'    ,'CMS Union'   ,NULL    , '0','10',NULL,'1' ,'Y','6',NULL         ,'2','0','N','CMSUnion'     ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
	  ,('udxrefUnion','5010','udxrefUnion','CMSClass'    ,'CMS Class'   ,NULL    , '0','10',NULL,'1' ,'Y','6',NULL         ,'2','0','N','CMSClass'     ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
 	  ,('udxrefUnion','5015','udxrefUnion','CMSType'     ,'CMS Type'    ,NULL    , '0','10',NULL,'1' ,'Y','6',NULL         ,'2','0','N','CMSType'      ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udxrefUnion','5020','udxrefUnion','Craft'       ,'Craft'       ,'bCraft',NULL,NULL,NULL,'1' ,'N','6','0,0,113,20' ,'4','0','N','Craft'        ,'Y','Y',NULL,NULL,'Y' ,'-1','0')
      ,('udxrefUnion','5025','udxrefUnion','Class'       ,'Class'       ,'bClass',NULL,NULL,NULL,'1' ,'N','6','25,0,113,20','4','0','N','Class'        ,'Y','Y',NULL,NULL,'Y' ,'-1,5020','0')
	  ,('udxrefUnion','5030','udxrefUnion','Description' ,'Description' ,'bDesc' ,NULL,NULL,NULL,'1' ,'N','6','51,0,339,20','4','0','N','Description'  ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
	 
 	  ;
 	  	  --SOURCE:  select Form, Tab, Title, LoadSeq from vDDFTc where Form='udxrefUnion'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udxrefUnion', 0,    'Grid',     0)
      ,('udxrefUnion', 1,    'Info',     1);
      

      --SOURCE:  select Form, Seq, GridCol, VPUserName from vDDUI where Form='udxrefUnion'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ( 'udxrefUnion', 5000, 0,    'viewpointcs')
      ,('udxrefUnion', 5005, 1,    'viewpointcs')
      ,('udxrefUnion', 5010, 2,    'viewpointcs')
      ,('udxrefUnion', 5015, 3,    'viewpointcs')
      ,('udxrefUnion', 5020, 4,    'viewpointcs')
      ,('udxrefUnion', 5025, 5,    'viewpointcs')
      ,('udxrefUnion', 5030, 6,    'viewpointcs');
      

      
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
       ( 'udxrefUnion','Company'    ,'Company'    ,'1' ,'bHQCo' ,NULL,NULL ,NULL,'6','5000',NULL,NULL)
      ,( 'udxrefUnion','CMSUnion'   ,'CMS Union'  ,'2' ,NULL    ,'0' ,'10' ,NULL,'6','5005',NULL,NULL)
      ,( 'udxrefUnion','CMSClass'   ,'CMS Class'  ,'3' ,NULL    ,'0' ,'10' ,NULL,'6','5010',NULL,NULL)
      ,( 'udxrefUnion','CMSType'    ,'CMS Type'   ,'4' ,NULL    ,'0', '10' ,NULL,'6','5015',NULL,NULL)
      ,( 'udxrefUnion','Craft'      ,'Craft'      ,NULL,'bCraft',NULL ,NULL,NULL,'6','5020',NULL,NULL)
      ,( 'udxrefUnion','Class'      ,'Class'      ,NULL,'bClass',NULL ,NULL,NULL,'6','5025',NULL,NULL)
      ,( 'udxrefUnion','Description','Description',NULL,'bDesc' ,NULL ,NULL,NULL,'6','5030',NULL,NULL);
      
      
      
--SOURCE:  select * from bUDTH where TableName='udxrefUnion'
declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, UseNotesTab, AuditTable)
values
      ('udxrefUnion', 'Cross Ref: PR Unions', 'udxrefUnion', 'N', 'viewpointcs', @datecreated, 'Y', 'N', 0, 'Y');
      
--SOURCE:  select Mod, Form, Active from vDDMFc where Form='udxrefUnion'
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udxrefUnion','Y');
      
--SOURCE:  select Seq, CustomControlSize from DDFIc where Form='udxrefUnion'
update Viewpoint.dbo.DDFIc 
set   CustomControlSize=
      case
            when Seq=5020 then '41,72'
            when Seq=5030 then '73,266'
            else null
      end
where Viewpoint.dbo.DDFIc.Form='udxrefUnion'
  
  
      
insert into Viewpoint.dbo.budxrefUnion  (Company, CMSUnion, CMSClass, CMSType) 
select distinct COMPANYNUMBER, UNIONNO , convert(varchar(max),EMPLOYEECLASS), EMPLTYPE 
from CV_CMS_SOURCE.dbo.PRTTCH 
where COMPANYNUMBER = 1
      
GO
