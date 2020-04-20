SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_PO_AddColsIndexes] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 
as




/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Add Columns and Indexes to PO tables 
	Created:	10/14/2009
	Created by: JJH
	Revisions:	1. none
**/


set @errmsg=''
set @rowcount=0


BEGIN try



if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.POTMCT')and name='udMth')
alter table CV_CMS_SOURCE.dbo.POTMCT add udMth smalldatetime null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.POTMDT')and name='udMth')
alter table CV_CMS_SOURCE.dbo.POTMDT add udMth smalldatetime null

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.POTCDT')and name='udMth')
alter table CV_CMS_SOURCE.dbo.POTCDT add udMth smalldatetime null


if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('vPOItemLine')and name='udCGC_ASQ02')
alter table vPOItemLine add udCGC_ASQ02 numeric null




--------------------------------------------------
--create index on newly created columns
-------------------------------------------------



--if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
--where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPC') and name='ciAPTOPC_Co')
--CREATE CLUSTERED INDEX ciAPTOPC_Co ON CV_CMS_SOURCE.dbo.APTOPC (COMPANYNUMBER, PAYMENTSELNO, VENDORNUMBER, RECORDCODE);


	
	
			
	
	
	

	

	
	
	
	

END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')

END CATCH;


return @@error

GO
