
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_JC_AddColsIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as




/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Add Columns and Indexes to JC tables 
	Created:	10/15/2009
	Created by: JJH
	Revisions:	1. none
**/


set @errmsg=''
set @rowcount=0


-- add new columns on Viewpoint tables
BEGIN try


if not exists (select name from dbo.syscolumns 
  where id=OBJECT_ID('bJCJM')and name='udCGCJob')
alter table bJCJM add udCGCJob varchar(20)

--------------------------------------------------
--create indexes 
-------------------------------------------------


if not exists (select name from CV_CMS_SOURCE.sys.indexes  
	where  name='cviJCTCGO')
create nonclustered index cviJCTCGO ON CV_CMS_SOURCE.dbo.JCTCGO (COMPANYNUMBER, JOBNUMBER, SUBJOBNUMBER, GROUPNO)


if not exists (select name from CV_CMS_SOURCE.sys.indexes  
	where  name='cviJCTCGH')
create nonclustered index cviJCTCGH ON CV_CMS_SOURCE.dbo.JCTCGH (RHCONO, JOBNUMBER, SUBJOBNUMBER, RHGP05)

if not exists (select name from CV_CMS_SOURCE.sys.indexes  
	where  name='cviJCTMST')
create nonclustered index cviJCTMST ON CV_CMS_SOURCE.dbo.JCTMST (COMPANYNUMBER, JOBNUMBER, 
		SUBJOBNUMBER, JCDISTRIBTUION, COSTTYPE)
		
if not exists (select name from CV_CMS_SOURCE.sys.indexes  
	where  name='cviJCTDSC')
create nonclustered index cviJCTDSC ON CV_CMS_SOURCE.dbo.JCTDSC (COMPANYNUMBER, JOBNUMBER, 
		SUBJOBNUMBER)

if not exists (select name from Viewpoint.dbo.sysindexes 
   where  id=OBJECT_ID('Viewpoint.dbo.budxrefPhase') and name ='ixrefPhase')    
create unique clustered index ixrefPhase on 
   Viewpoint.dbo.budxrefPhase(Company, oldPhase, newPhase);
   
if not exists (select name from Viewpoint.dbo.sysindexes 
   where  id=OBJECT_ID('Viewpoint.dbo.budxrefJCDept') and name ='ixrefJCDept')     
create unique clustered index ixrefJCDept on 
	Viewpoint.dbo.budxrefJCDept (Company, CMSDept, VPDept);
	
if not exists (select name from Viewpoint.dbo.sysindexes 
   where  id=OBJECT_ID('Viewpoint.dbo.budxrefCostType') and name ='ixrefCostType')    
create unique clustered index ixrefCostType on 
	Viewpoint.dbo.budxrefCostType(Company, CMSCostType, CostType);
		
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')

END CATCH;


return @@error

GO
