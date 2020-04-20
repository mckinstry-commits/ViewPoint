SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




CREATE proc [dbo].[cvsp_CMS_PR_AddColsIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as




/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Add Columns and Indexes to PR tables 
	Created:	10/27/2009
	Created by: JJH
	Revisions:	1. none
**/


set @errmsg=''
set @rowcount=0


BEGIN try


--Update CMS Tables
if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCH')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRTTCH add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTHST')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRTHST add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMUN')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRTMUN add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMAJ')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRTMAJ add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.HRTMBN')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.HRTMBN add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMED')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRTMED add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCE')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRTTCE add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTWCH')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRTWCH add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRPDED')and name='WkEndDate')
alter table CV_CMS_SOURCE.dbo.PRPDED add WkEndDate smalldatetime null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTWCH')and name='PREndDate')
alter table CV_CMS_SOURCE.dbo.PRTWCH add PREndDate smalldatetime null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRPDED')and name='PaySeq')
alter table CV_CMS_SOURCE.dbo.PRPDED add PaySeq tinyint null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMUN')and name='Job')
alter table CV_CMS_SOURCE.dbo.PRTMUN add Job varchar(10) null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCH')and name='Job')
alter table CV_CMS_SOURCE.dbo.PRTTCH add Job varchar(10) null
--------------------------------------------------
--create indexes 
-------------------------------------------------
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMUN') and name='ciPRTMUN')
create index ciPRTMUN on CV_CMS_SOURCE.dbo.PRTMUN (COMPANYNUMBER, CHECKDATE, CHECKNUMBER, EMPLOYEENUMBER);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMUN') and name='ciPRTMUNEndDate')
create index ciPRTMUNEndDate on CV_CMS_SOURCE.dbo.PRTMUN (COMPANYNUMBER, EMPLOYEENUMBER, 
	CHECKNUMBER, WkEndDate);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMUN') and name='ciPRTMUNPaySeq')
create index ciPRTMUNPaySeq on CV_CMS_SOURCE.dbo.PRTMUN (COMPANYNUMBER, EMPLOYEENUMBER, 
	CHECKNUMBER, WkEndDate, PaySeq);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMUN') and name='ciPRTMUNJob')
create index ciPRTMUNJob on CV_CMS_SOURCE.dbo.PRTMUN (COMPANYNUMBER, EMPLOYEENUMBER, 
	CHECKNUMBER, WkEndDate, Job);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTHST') and name='ciPRTHST')
create index ciPRTHST on CV_CMS_SOURCE.dbo.PRTHST (COMPANYNUMBER, EMPLOYEENUMBER, CHECKNUMBER, WkEndDate);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCH') and name='ciPRTTCH')
create index ciPRTTCH on CV_CMS_SOURCE.dbo.PRTTCH (COMPANYNUMBER, EMPLOYEENUMBER, WkEndDate, 
	CHECKNUMBER, CHECKDATE);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCH') and name='ciPRTTCHPaySeq')
create index ciPRTTCHPaySeq on CV_CMS_SOURCE.dbo.PRTTCH (COMPANYNUMBER, EMPLOYEENUMBER, 
	WkEndDate, CHECKDATE, CHECKNUMBER, PaySeq);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTHST') and name='ciPRTHSTPaySeq')
create index ciPRTHSTPaySeq on CV_CMS_SOURCE.dbo.PRTHST (COMPANYNUMBER, EMPLOYEENUMBER, 
	WkEndDate, CHECKDATE, CHECKNUMBER, PaySeq);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCH') and name='ciPRTTCHJob')
create index ciPRTTCHJob on CV_CMS_SOURCE.dbo.PRTTCH (COMPANYNUMBER, EMPLOYEENUMBER, 
	CHECKNUMBER, WkEndDate, Job);

if not exists (select name from sysindexes 
  where id=OBJECT_ID('bPRTH') and name='ciPRTHJobCMRef')
create index ciPRTHJobCMRef on bPRTH (PRCo,PREndDate,Employee,PaySeq,Job,udCMRef);

if not exists (select name from sysindexes
	where id=OBJECT_ID('bPRTH') and name='ciPRTHCMRef')
create index ciPRTHCMRef on bPRTH (PRCo, PREndDate, Employee, PaySeq, udCMRef) ;

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMUN') and name='ciPRTMUNAll')
create index ciPRTMUNAll on CV_CMS_SOURCE.dbo.PRTMUN (COMPANYNUMBER, WkEndDate, EMPLOYEENUMBER, 
	Job, CHECKNUMBER, PaySeq);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCH') and name='ciPRTTCHAll')
create index ciPRTTCHAll on CV_CMS_SOURCE.dbo.PRTTCH (COMPANYNUMBER, WkEndDate, EMPLOYEENUMBER, 
	Job, CHECKNUMBER, PaySeq);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMAJ') and name='ciPRTMAJPaySeq')
create index ciPRTMAJPaySeq on CV_CMS_SOURCE.dbo.PRTMAJ (COMPANYNUMBER, EMPLOYEENUMBER, 
	WkEndDate, CHECKDATE, CHECKNUMBER, PaySeq);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.HRTMBN') and name='ciHRTMBNPaySeq')
create index ciHRTMBNPaySeq on CV_CMS_SOURCE.dbo.HRTMBN (COMPANYNUMBER, EMPLOYEENUMBER, 
	WkEndDate, CHECKDATE, CHECKNUMBER, PaySeq);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTTCE') and name='ciPRTTCEPaySeq')
create index ciPRTTCEPaySeq on CV_CMS_SOURCE.dbo.PRTTCE (COMPANYNUMBER, EMPLOYEENUMBER, 
	WkEndDate, CHECKNUMBER, PaySeq);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTMED') and name='ciPRTMEDPaySeq')
create index ciPRTMEDPaySeq on CV_CMS_SOURCE.dbo.PRTMED (COMPANYNUMBER, EMPLOYEENUMBER, 
	WkEndDate, CHECKDATE, CHECKNUMBER, PaySeq);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRPDED') and name='ciPRPDEDPaySeq')
create index ciPRPDEDPaySeq on CV_CMS_SOURCE.dbo.PRPDED (DCONO, DEENO, 
	WkEndDate, PaySeq);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRTWCH') and name='ciPRTWCHPaySeq')
create index ciPRTWCHPaySeq on CV_CMS_SOURCE.dbo.PRTWCH (COMPANYNUMBER, EMPLOYEENUMBER, 
	WkEndDate, PaySeq);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.PRPDED') and name='ciPRPDEDDate')
create index ciPRPDEDDate on CV_CMS_SOURCE.dbo.PRPDED (DDTUL);

/**
Indexes on UD Tables
**/

--if not exists (select name from Viewpoint.dbo.sysindexes 
--  where id=OBJECT_ID('Viewpoint.dbo.budxrefPRDedLiab') and name='ixrefPRDedLiab')
--create unique clustered index ixrefPRDedLiab on Viewpoint.dbo.budxrefPRDedLiab
--	(Company, CMSDedType, CMSDedCode, CMSUnion, DLCode, VPType);
	
--if not exists (select name from Viewpoint.dbo.sysindexes 
--  where id=OBJECT_ID('Viewpoint.dbo.budxrefUnion') and name='ixrefPRUnions')
--create unique clustered index ixrefPRUnions on 
--		Viewpoint.dbo.budxrefUnion(Company, Craft, Class, CMSUnion, CMSClass, CMSType);
		
--if not exists (select name from Viewpoint.dbo.sysindexes 
--  where id=OBJECT_ID('Viewpoint.dbo.budxrefPRGroup') and name='ixrefPRGroup')		
--create unique clustered index ixrefPRGroup on 
--   Viewpoint.dbo.budxrefPRGroup(Company, CMSCode, PRGroup);
   
--if not exists (select name from Viewpoint.dbo.sysindexes 
-- where  id=OBJECT_ID('Viewpoint.dbo.budxrefInsState') and name ='ixrefInsState')
--create unique clustered index ixrefInsState on 
--  Viewpoint.dbo.budxrefInsState(Company, InsCode, VPInsState);

--if not exists (select name from Viewpoint.dbo.sysindexes 
--   where  id=OBJECT_ID('Viewpoint.dbo.budxrefPREarn') and name ='ixrefPREarn')
--create unique clustered index ixrefPREarn on 
--    Viewpoint.dbo.budxrefPREarn (Company, CMSCode, CMSDedCode, VPType, EarnCode);

--if not exists (select name from Viewpoint.dbo.sysindexes 
--   where  id=OBJECT_ID('Viewpoint.dbo.budxrefPRDept') and name ='ixrefPRDept')    
--create unique clustered index ixrefPRDept on 
--    Viewpoint.dbo.budxrefPRDept (Company, CMSCode, PRDept);


END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')

END CATCH;


return @@error


GO
