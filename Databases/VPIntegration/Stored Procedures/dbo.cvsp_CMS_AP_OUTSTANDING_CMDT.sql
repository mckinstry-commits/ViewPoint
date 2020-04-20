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
	Title:		CM Detail - AP (CMDT)
	Created:	09.15.11
	Created by:	Craig R    
	Revisions:	
	Notes:		Inserts AP Outstanding Checks Only into CMDT
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_AP_OUTSTANDING_CMDT] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

as

set @errmsg=''
set @rowcount=0



ALTER Table bCMDT disable trigger all;

--delete trans
BEGIN TRAN
alter table bCMAC NOCHECK CONSTRAINT FK_bCMAC_bCMCO
alter table bCMDT NOCHECK CONSTRAINT FK_bCMDT_bCMAC
alter table bCMST NOCHECK CONSTRAINT FK_bCMST_bCMAC

delete bCMDT where Source='AP Payment' and CMCo=@toco;



COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bCMDT (CMCo, Mth,CMTrans,CMAcct,StmtDate,CMTransType,SourceCo,Source,ActDate,PostedDate,Amount,ClearedAmt,BatchId,CMRef,
CMRefSeq,Payee,GLCo,CMGLAcct,Void,Purge,ClearDate,Description,udSource,udConv,udCGCTable,udCGCTableID)

select  CMCo=@toco
, Mth= max(p.PaidMth)
, CMTrans=isnull(max(t.LastTrans),1) + ROW_NUMBER() over (PARTITION BY p.JCONO
		ORDER BY p.JCONO, p.PaidMth )
, CMAcct=m.CMAcct
, StmtDate = null    
, CMTransType=1
, SourceCo=max(m.VendorGroup)
, Source='AP Payment'
, ActDate=max(substring(convert(nvarchar(max),p.JDTCK),5,2) 
+'/'+ substring(convert(nvarchar(max),p.JDTCK),7,2) +  '/'+
substring(convert(nvarchar(max),p.JDTCK),1,4))
, PostedDate=max(substring(convert(nvarchar(max),p.JDTCK),5,2) 
+'/'+ substring(convert(nvarchar(max),p.JDTCK),7,2) +  '/'+
substring(convert(nvarchar(max),p.JDTCK),1,4))
, Amount=p.JAMCK * -1
, ClearedAmt=0    
, BatchId=1
, CMRef=space(10-datalength(rtrim(p.JCKNO))) + rtrim(p.JCKNO)
, CMRefSeq=1
, Payee=max(x.Vendor)
, GLCo=@toco 
, CMGLAcct=max(a.GLAcct)
, Void='N'
, Purge='N'
, ClearDate=null 
, Description=convert(nvarchar(10),max(x.Vendor)) + '; ' + substring(max(m.Name),1,20)
, udSource='AP_OUTSTANDING_CMDT'
, udConv='Y'
,udCGCTable='APPCHK'
,udCGCTableID=p.APPCHKID
from CV_CMS_SOURCE.dbo.APPCHK p 
	left join Viewpoint.dbo.budxrefAPVendor x on x.NewCo=p.JCONO and x.OldVendorID=p.JVNNO
	LEFT join bAPVM m on m.Vendor=x.Vendor
	left join HQTC t on @toco=t.Co and p.PaidMth=t.Mth and t.TableName='bCMDT'
	join CMAC a on @toco=a.CMCo and m.CMAcct=a.CMAcct
where  p.JCONO =@fromco  
group by  p.JCONO,p.PaidMth, m.CMAcct, p.JCKNO, p.JAMCK;


select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bCMST CHECK CONSTRAINT FK_bCMST_bCMAC
alter table bCMDT CHECK CONSTRAINT FK_bCMDT_bCMAC
alter table bCMAC CHECK CONSTRAINT FK_bCMAC_bCMCO

ALTER Table bCMDT enable trigger all;

return @@error
GO
