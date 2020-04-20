SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




CREATE proc [dbo].[cvsp_CMS_AR_AddColsIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as




/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Add Columns and Indexes to AR tables 
	Created:	April 7, 2009	
	Created by: Jim Emery
	Revisions:	1. 6/29/10 - Added ud fields to track AR historical invoices
**/


set @errmsg=''
set @rowcount=0


-- add new trans
BEGIN try


/*******  ARTOPD   *******/


if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and name='udMth')
alter table CV_CMS_SOURCE.dbo.ARTOPD add udMth smalldatetime null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and name='udContract')
alter table CV_CMS_SOURCE.dbo.ARTOPD add udContract varchar(10) null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and name='udItem')
alter table CV_CMS_SOURCE.dbo.ARTOPD add udItem varchar(16) null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and name='udARTOPCID')
alter table CV_CMS_SOURCE.dbo.ARTOPD add udARTOPCID int null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and name='udPaidMth')
alter table CV_CMS_SOURCE.dbo.ARTOPD add udPaidMth smalldatetime null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and  name='udPayARTrans ')
alter table CV_CMS_SOURCE.dbo.ARTOPD add udPayARTrans int null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and  name='Source')
alter table CV_CMS_SOURCE.dbo.ARTOPD add Source varchar(7) null

/******  ARTOPC  ******/


if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPC')and name='Source')
alter table CV_CMS_SOURCE.dbo.ARTOPC add Source varchar(7) null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPC')and name='udPaidMth')
alter table CV_CMS_SOURCE.dbo.ARTOPC add udPaidMth smalldatetime null

/******  ARPCSD  *********/

--if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
--  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARPCSD') and name='udMth')
--alter table CV_CMS_SOURCE.dbo.ARPCSD add udMth smalldatetime null

--if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
--  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARPCSD') and name='udContract')
--alter table CV_CMS_SOURCE.dbo.ARPCSD add udContract varchar(10) null

--if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
--  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARPCSD') and name='udItem')
--alter table CV_CMS_SOURCE.dbo.ARPCSD add udItem varchar(16) null

--if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
--  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARPCSD')and name='udCashRcptsDate')
--alter table CV_CMS_SOURCE.dbo.ARPCSD add udCashRcptsDate smalldatetime null;

--if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
--  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARPCSD')and name='udPaidMth')
--alter table CV_CMS_SOURCE.dbo.ARPCSD add udPaidMth smalldatetime null;

--if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
--  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARPCSD')and name='udPaidDate')
--alter table CV_CMS_SOURCE.dbo.ARPCSD add udPaidDate smalldatetime null;


--------------------------------------------------
--create index on newly created columns
-------------------------------------------------
if not exists (select name from sysindexes 
  where id=OBJECT_ID('bARTH') and name='biARTHudARTOPCID')
create index biARTHudARTOPCID on bARTH (udARTOPCID)

if not exists (select name from sysindexes 
  where id=OBJECT_ID('bARTH') and name='biARTHudPAYARTOPCID')
create index biARTHudPAYARTOPCID on bARTH (udPAYARTOPCID)

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD') and name='ARTOPDIDi')
create index ARTOPDIDi on CV_CMS_SOURCE.dbo.ARTOPD (udARTOPCID)

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPC') and name='ARTOPCIDi')
create index ARTOPCIDi on CV_CMS_SOURCE.dbo.ARTOPC (ARTOPCID)

if not exists (select name from sysindexes 
  where id=OBJECT_ID('bARTL') and name='iARTLudARTOPDID')
create index iARTLudARTOPDID on bARTL(udARTOPDID)


END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')

END CATCH;


return @@error


GO
