SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_AP_AddColsIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as




/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Add Columns and Indexes to AP tables 
	Created:	10/14/2009
	Created by: JJH
	Revisions:	1. none
**/


set @errmsg=''
set @rowcount=0


BEGIN try

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPD')and name='udNewVendor')
alter table CV_CMS_SOURCE.dbo.ARTOPD add udNewVendor int NULL

--if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
--  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.ARTOPC')and name='udPaidMth')
--alter table CV_CMS_SOURCE.dbo.ARTOPC add udPaidMth smalldatetime null.

if not exists (select name from CV_CMS_SOURCE.dbo.syscolumns 
  where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD')and name='udPONumber')
alter table CV_CMS_SOURCE.dbo.APTOPD add udPONumber varchar(10)


--------------------------------------------------
--create index on newly created columns
-------------------------------------------------

--if not exists (select name from sysindexes 
--  where id=OBJECT_ID('bARTL') and name='iARTLudARTOPDID')
--create index iARTLudARTOPDID on bARTL(udARTOPDID)

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPC') and name='ciAPTOPC_Co')
CREATE CLUSTERED INDEX ciAPTOPC_Co ON CV_CMS_SOURCE.dbo.APTOPC (COMPANYNUMBER, PAYMENTSELNO, VENDORNUMBER, RECORDCODE);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='APTOPDCo')
CREATE NONCLUSTERED INDEX APTOPDCo ON CV_CMS_SOURCE.dbo.APTOPD(COMPANYNUMBER);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='APTOPDCoVen')
CREATE NONCLUSTERED INDEX APTOPDCoVen ON CV_CMS_SOURCE.dbo.APTOPD (COMPANYNUMBER, VENDORNUMBER);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='APTOPDCoVenJob')
CREATE NONCLUSTERED INDEX APTOPDCoVenJob ON CV_CMS_SOURCE.dbo.APTOPD (COMPANYNUMBER, VENDORNUMBER, JOBNUMBER, SUBJOBNUMBER);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='APTOPDCoVenJobContract')
CREATE CLUSTERED INDEX APTOPDCoVenJobContract ON CV_CMS_SOURCE.dbo.APTOPD
(COMPANYNUMBER, VENDORNUMBER, JOBNUMBER, SUBJOBNUMBER, CONTRACTNO);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='ciAPTOPD_SL')	
CREATE NONCLUSTERED INDEX ciAPTOPD_SL ON CV_CMS_SOURCE.dbo.APTOPD 
(COMPANYNUMBER, VENDORNUMBER, JOBNUMBER, SUBJOBNUMBER, CONTRACTNO, JCDISTRIBTUION, ITEMNUMBER);
	
if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='ciAPTOPD_Vendor')	
CREATE NONCLUSTERED INDEX ciAPTOPD_Vendor ON CV_CMS_SOURCE.dbo.APTOPD 
(COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, JOURNALDATE, RECORDCODE);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPC') and name='ciAPTOPC_Vendor')	
CREATE NONCLUSTERED INDEX ciAPTOPC_Vendor ON CV_CMS_SOURCE.dbo.APTOPC 
(COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, JOURNALDATE, RECORDCODE);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTHCK') and name='iAPTHCK')
create index iAPTHCK on CV_CMS_SOURCE.dbo.APTHCK
(COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, PAYMENTSELNO, RECORDCODE);


if not exists (select name from dbo.sysindexes 
where id=OBJECT_ID('bPMSL') and name='ciPMSLAP')	
CREATE NONCLUSTERED INDEX ciPMSLAP 
ON bPMSL
(PMCo, Project, Vendor, udSLContractNo, udCMSItem, udCGCTable)

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='ciAPTOPD_VendorPO')	
CREATE NONCLUSTERED INDEX ciAPTOPD_VendorPO 
ON CV_CMS_SOURCE.dbo.APTOPD
(JOBNUMBER, udNewVendor, CONTRACTNO, ITEMNUMBER);

if not exists (select name from CV_CMS_SOURCE.dbo.sysindexes 
where id=OBJECT_ID('CV_CMS_SOURCE.dbo.APTOPD') and name='ciAPTOPD_PO')	
CREATE NONCLUSTERED INDEX ciAPTOPD_PO ON CV_CMS_SOURCE.dbo.APTOPD
(udPONumber, POITEMT, SEQUENCENO02);

if not exists (select name from dbo.sysindexes 
where id=OBJECT_ID('vPOItemLine') and name='ciPOudSeq')	
CREATE NONCLUSTERED INDEX ciPOudSeq 
ON vPOItemLine
(POCo, PO, POItem, udCGC_ASQ02)








	
	
			
	
	
	

	

	
	
	
	

END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')

END CATCH;


return @@error

GO
