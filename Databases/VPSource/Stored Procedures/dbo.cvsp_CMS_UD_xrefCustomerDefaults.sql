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
      Title:      UD table setup for Cross Reference: Customer Defaults
      Created: 03/10/2011
      Created by: VCS Technical Services - Bryan Clark/Craig Rutter
      Revisions:  
			1. 04/27/2011 BBA - In bUDTH set UseNotes & Auding to Y and added
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

CREATE PROCEDURE [dbo].[cvsp_CMS_UD_xrefCustomerDefaults]
(@datecreated smalldatetime)

AS

if not exists(select name from Viewpoint.dbo.sysobjects where name ='budCustomerDefaults')
BEGIN
	create table Viewpoint.dbo.budCustomerDefaults(
		Company tinyint not null, -- 0=all companies, otherwise co #
		TableName varchar(30) not null ,
		ColName varchar(30) not null,
		DefaultString varchar(max)  null,
		DefaultNumeric decimal(20,8) null,
		DefaultDate smalldatetime null,
		DefaultDesc varchar(60)  null,
		UniqueAttchID uniqueidentifier NULL,
		KeyID bigint IDENTITY(1,1) Not Null
	)

	--create unique clustered index iCustomerDefaults on budCustomerDefaults(Company, TableName,ColName)
end;




/* Insert values to the Viewpoint tables relating to the ud table*/

--SOURCE:  select * from Viewpoint.dbo.vDDFHc where Form='udCustomerDefaults'
insert into Viewpoint.dbo.vDDFHc 
      (Form,Title,FormType,ShowOnMenu,IconKey,ViewName,JoinClause,WhereClause,AssemblyName
      ,FormClassName,ProgressClip,FormNumber,NotesTab,LoadProc,PostedTable,AllowAttachments
      ,Version,Mod,CoColumn,OrderByClause,DefaultTabPage,SecurityForm,DetailFormSecurity)
values
      ('udCustomerDefaults','Cross Ref: Customer Defaults','1','Y',NULL,'udCustomerDefaults',NULL,NULL,'UD',
      'frmUDUserGeneratedForm',NULL,NULL,'2',NULL,NULL,'Y',NULL,'UD',NULL,NULL,NULL,'udCustomerDefaults','N')


--SOURCE: select * from budCustomerDefaults
--  select * from budCustomerDefaults
/* 
select Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
      ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
      AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq 
from Viewpoint.dbo.vDDFIc where Form='udCustomerDefaults'
*/
insert into Viewpoint.dbo.vDDFIc
      (Form, Seq, ViewName, ColumnName, Description, Datatype, InputType, InputLength, Prec, Tab, Req,
            ControlType, ControlPosition, FieldType, DefaultType, InputSkip, Label, ShowGrid, ShowForm,
            AutoSeqType, ComboType, ActiveLookup, LookupParams, LookupLoadSeq)

 Values
       ('udCustomerDefaults','5000','udCustomerDefaults','Company'       ,'Company'        ,'bHQCo',NULL,NULL,NULL,NULL,'Y','6',NULL,'2','0','N','Company'        ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udCustomerDefaults','5005','udCustomerDefaults','TableName'     ,'Table Name'     ,NULL   , '0','30',NULL,NULL,'Y','6',NULL,'2','0','N','TableName'      ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
      ,('udCustomerDefaults','5010','udCustomerDefaults','ColName'       ,'Columnn Name'   ,NULL   , '0','30',NULL,NULL,'Y','6',NULL,'2','0','N','ColName'        ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
	  ,('udCustomerDefaults','5015','udCustomerDefaults','DefaultString' ,'Default String' ,NULL   , '0','30',NULL,'1' ,'N','6','0,0,287,20','4','0','N','DefaultString'  ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
	  ,('udCustomerDefaults','5020','udCustomerDefaults','DefaultNumeric','Default Numeric',NULL   , '1', '0', '4','1' ,'N','6','21,0,288,20','4','0','N','DefaultNumberic','Y','Y',NULL,NULL,NULL,NULL,NULL)
	  ,('udCustomerDefaults','5025','udCustomerDefaults','DefaultDate'   ,'DefaultDate'    ,NULL   , '2', '0',NULL,'1' ,'N','6','42,0,288,20','4','0','N','DefaultDate'    ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
 	  ,('udCustomerDefaults','5030','udCustomerDefaults','DefaultDesc'   ,'DefaultDesc'    ,NULL   , '0','60',NULL,'1' ,'N','6','65,1,289,20','4','0','N','DefaultDesc'    ,'Y','Y',NULL,NULL,NULL,NULL,NULL)
 	  
 	  	  --SOURCE:  select Form, Tab, Title, LoadSeq from Viewpoint.dbo.vDDFTc where Form='udCustomerDefaults'
insert into Viewpoint.dbo.vDDFTc
      (Form, Tab, Title, LoadSeq)
values
      ('udCustomerDefaults', 0,    'Grid',     0)
      ,('udCustomerDefaults', 1,    'Info',     1)
      
      --SOURCE:  select Form, Seq, GridCol, VPUserName from Viewpoint.dbo.vDDUI where Form='udCustomerDefaults'
insert into Viewpoint.dbo.vDDUI
      (Form, Seq, GridCol, VPUserName)
values
      ( 'udCustomerDefaults', 5000, 0,    'viewpointcs')
      ,('udCustomerDefaults', 5005, 1,    'viewpointcs')
      ,('udCustomerDefaults', 5010, 2,    'viewpointcs')
      ,('udCustomerDefaults', 5015, 3,    'viewpointcs')
      ,('udCustomerDefaults', 5020, 4,    'viewpointcs')
      ,('udCustomerDefaults', 5025, 5,    'viewpointcs')
      ,('udCustomerDefaults', 5030, 6,    'viewpointcs')
      
      
      
insert into Viewpoint.dbo.bUDTC 
      (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputLength, Prec, ControlType, DDFISeq,
            AutoSeqType, ComboType)
values
       ( 'udCustomerDefaults','Company','Company'               ,'1' ,'bHQCo',NULL,NULL,NULL,'6','5000',NULL,NULL)
      ,( 'udCustomerDefaults','TableName','Table Name'          ,'2' ,NULL   ,'0' ,'30',NULL,'6','5005',NULL,NULL)
      ,( 'udCustomerDefaults','ColName','Column Name'           ,'3' ,NULL   ,'0' ,'30',NULL,'6','5010',NULL,NULL)
      ,( 'udCustomerDefaults','DefaultString','Default String'  ,NULL,NULL   ,'0', '30',NULL,'6','5015',NULL,NULL)
      ,( 'udCustomerDefaults','DefaultNumeric','Default Numeric',NULL,NULL   ,'1' , '0', '4','6','5020',NULL,NULL)
      ,( 'udCustomerDefaults','DefaultDate','Default Date'      ,NULL,NULL   ,'2' , '0',NULL,'6','5025',NULL,NULL)
      ,( 'udCustomerDefaults','DefaultDesc','Default Desc'      ,NULL,NULL   ,'0' ,'60',NULL,'6','5030',NULL,NULL)
      
      
      
      
--SOURCE:  select * from Viewpoint.dbo.bUDTH where TableName='udCustomerDefaults'
--declare @datecreated smalldatetime set @datecreated=getdate()
insert into Viewpoint.dbo.bUDTH
      (TableName, Description, FormName, CompanyBasedYN, CreatedBy, DateCreated, Created, Dirty, /*UseNotes,*/ AuditTable)
values
      ('udCustomerDefaults', 'Cross Ref: Customer Defaults', 'udCustomerDefaults', 'N', 'viewpointcs', @datecreated, 'Y', 'N', /*'Y',*/ 'Y');
      
      --SOURCE:  select Mod, Form, Active from Viewpoint.dbo.vDDMFc where Form='udxrefPhase'
alter table vDDMFc disable trigger all;
INSERT INTO Viewpoint.dbo.vDDMFc
      (Mod, Form, Active)
values
      ('UD','udCustomerDefaults','Y');
 alter table vDDMFc enable trigger all;     
      
  --SOURCE:  select Seq, CustomControlSize from Viewpoint.dbo.DDFIc where Form='udCustomerDefaults'
update Viewpoint.dbo.DDFIc 
set   CustomControlSize=
      case
			when Seq=5015 then '100,186'
            when Seq=5025 then '102,186'
            when Seq=5030 then '101,188'
            else null
      end
where dbo.DDFIc.Form='udCustomerDefaults'    
      
      
      
-- APVM
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bAPVM','OverrideMinAmtYN','N' ,null,null,'Default Override Minimum Amount',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bAPVM','V1099Type','MISC' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bAPVM','V1099Box', null ,7,null,'',NULL);

-- ARCM
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','TaxCode',null ,null,null,'',NULL); -- null default
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','SelPurge','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','StmtType','O' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','FCType','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','FCPct',null,0,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','MarkupDiscPct',null,0,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','HaulTaxOpt',null,0,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','InvLvl',null,0,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','MiscOnInv','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','MiscOnPay','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','PrintLvl',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','SubtotalLvl',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','SepHaul','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARCM','ExclContFromFC','N' ,null,null,'',NULL);

--ARTH
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARTH','PayTerms','30' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bARTH','RecType',null ,1,null,'',NULL);

--PMSL
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPMSL','UM','LS' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPMSL','ACOItem','         1' ,null,null,'',NULL);

--APTH
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bAPTH','DueDate','LS' ,null,'12/31/2009','Open Retg Default Due Date',NULL);

--APTL
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bAPTL','UM','LS' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bAPTL','GLAcct','9999.999.999' ,null,null,'',NULL);


--APPH
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bAPPH','Country','US' ,null,null,'',NULL);


-- GLFY
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bGLFY','YearEndMth',null,12,null,'',NULL);  -- usually 12, must be between 1 and 12

-- JCCM
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','RetainPCT',null,0.00,null,'Default Retainage Percentage for Contracts',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','Department','100' ,null,null,'Default Department if null',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','PayTerms','30',null,null,'Default PayTerms',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','TaxInterface','Y',null,null,'Default TaxInterface',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','CompleteYN','N',null,null,'Default CompleteYN',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','BillOnCompletionYN','N',null,null,'Default BillOnCompletionYN',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','RoundOpt','N',null,null,'Default RoundOpt',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','ReportRetgItemYN','N',null,null,'Default ReportRetgItemYN',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','JBLimitOpt','N',null,null,'Default JBLimitOpt',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','UpdateJCCI','Y',null,null,'Default UpdateJCCI',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCM','RecType',null,'1',null,'Default RecType',NULL);

-- JCCI
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCI','Item',space(15)+'1' ,null,null,'Default Contract Item if null',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCI','UM','LS' ,null,null,'Default Unit of Measure if null',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCI','InitSubs','Y' ,null,null,'Default Init Subs',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCI','MarkUpRate',null ,0,null,'Default MarkUpRate',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCI','ProjPlug','N' ,null,null,'Default ProjPlug',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCI','DefaultUM','LS' ,null,null,'Default UM',NULL);
set nocount off

-- JCJM
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','LockPhases','Y' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','BaseTaxOn','J' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','UpdatePlugs','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','AutoAddItemYN','Y' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','WghtAvgOT','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','AutoGenSubNo','P' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','UpdateAPActualsYN','Y' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','UpdateMSActualsYN','Y' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','AutoGenPCONo','P' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','AutoGenMTGNo','P' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','AutoGenRFINo','P' ,null,null,'',NULL);
-- use HQCO State for default TaxCode
insert into Viewpoint.dbo.budCustomerDefaults  
select 0,'bJCJM','TaxCode',State ,null,null,'',NULL
from HQCO where HQCo=1;
insert into Viewpoint.dbo.budCustomerDefaults  
select HQCo,'bJCJM','TaxCode',State ,null,null,'',NULL
from HQCO where [State] is not null;
-- use HQCO State for default PRState
insert into Viewpoint.dbo.budCustomerDefaults  
select 0,'bJCJM','PRStateCode',State ,null,null,'',NULL
from HQCO where HQCo=1;
insert into Viewpoint.dbo.budCustomerDefaults  
select HQCo,'bJCJM','PRStateCode',State ,null,null,'',NULL
from HQCO where [State] is not null; -- or GSTCD

insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','MarkUpDiscRate',null ,0,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','ProjMinPct',null ,0,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','HaulTaxOpt',null ,0,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','HrsPerManDay',null ,8,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','InsTemplate',null ,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','LiabTemplate',null ,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCJM','FixedRateTemp',null,null,null,'',NULL);

-- JCPM
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCPM','ProjMinPct',null ,.10,null,'',NULL);

--JCCH
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','BillFlag','C' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','ItemUnitFlag','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','PhaseUnitFlag','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','BuyOutYN','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','Plugged','N' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','ActiveYN','Y' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','SourceStatus','J' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','DefaultUM','LS' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCCH','DefaultUMUnits','EA' ,null,null,'',NULL);
	

--JCOH
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCOH','DefaultACO','       999' ,null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bJCOH','DefaultACODesc','Misc./Internal Change Orders' ,null,null,'',NULL);

--PMOI
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPMOI','Status','A' ,null,null,'',NULL);

--PMOL
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPMOL','ECM','E' ,null,null,'',NULL);

--JCCD
insert into Viewpoint.dbo.budCustomerDefaults values
(0, 'bJCCD','EarnFactor',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values
(0, 'bJCCD','EarnType',null,1,null,'',NULL);

--CMDT
--This date will be used to clear all checks up to and including the default date.
--The checks will have a statement date and clear date that also uses this default.
insert into Viewpoint.dbo.budCustomerDefaults values
(0, 'bCMDT','ClearDate',null,null,'12/31/11','',NULL);

--PREH
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','PRGroup',null ,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','InsCode','5403',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','TaxState','PA',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','InsState','PA',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','UnempState','PA',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','UseState','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','UseLocal','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','UseIns','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','HrlyEarnCode',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','SalEarnCode',null,4,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','OTOpt','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','PostToAll','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','AuditYN','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','DefaultPaySeq','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPREH','Shift',null,1,null,'',NULL);


--PRDD
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRDD','Seq',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRDD','Status','A',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRDD','Frequency','A',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRDD','Method','A',null,null,'',NULL);


--PRED
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRED','EmplBased','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRED','Frequency','A',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRED','ProcessSeq',null,1,null,'',NULL);

--PRTH
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRTH','PaySeq',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRTH','JCDept','1',null, null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRTH','Craft',null,null,null,'',NULL);--letting it default in as null 
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRTH','Class',null,null,null,'',NULL);--letting it default in as null 

--PRAF
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRAF','FreqCode','A',null,null,'',NULL);

--PRDT
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRDT','EXCL_UNION','999',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRDT', 'StateCode', null, 1,null,'',NULL); -- insert State Tax Code, replace 1


--PRAE
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRAE','Seq',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRAE','PaySeq',null,1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRAE','StdHours','Y',1,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRAE','Frequency','A',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bPRAE','OvrStdLimitYN','N',null,null,'',NULL);

--EMEM
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bEMEM','UpdateYN','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bEMEM','FuelCapUM','GAL',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bEMEM','Capitalized','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bEMEM','AttachPostRevenue','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bEMEM','PostCostToComp','N',null,null,'',NULL);
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bEMEM','RevenueCode','1',null,null,'',NULL);

--Open Jobs Only
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'OpenJobs','OpenJobYN','N',null,null,'',NULL);

--EMCD
insert into Viewpoint.dbo.budCustomerDefaults values 
(0,'bEMCD','CostCode','1',null,null,'',NULL);


/* Create View */
--create view udCustomerDefaults as select a.* from Viewpoint.dbo.budCustomerDefaults a;
----select * from Viewpoint.dbo.budCustomerDefaults order by KeyID
GO
