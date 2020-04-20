SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_AP_CMDT] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		CM Detail - AP (CMDT)
	Created:	07.27.09
	Created by:	JJH    
	Revisions:	1. 8/01/09 Added Description - ADB
	Notes:		Inserts AP Checks into CMDT
**/


set @errmsg=''
set @rowcount=0



ALTER Table bCMDT disable trigger all;

--delete trans
BEGIN TRAN
--alter table bCMAC NOCHECK CONSTRAINT FK_bCMAC_bCMCO
--alter table bCMDT NOCHECK CONSTRAINT FK_bCMDT_bCMAC
--alter table bCMST NOCHECK CONSTRAINT FK_bCMST_bCMAC

delete bCMDT where CMCo=@toco and Source='AP Payment';

exec dbo.cvsp_Disable_Foreign_Keys

COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bCMDT (CMCo, Mth,CMTrans,CMAcct,StmtDate,CMTransType,SourceCo,Source,ActDate,PostedDate,Amount,ClearedAmt,BatchId,CMRef,
CMRefSeq,Payee,GLCo,CMGLAcct,Void,Purge,ClearDate,Description, udSource,udConv)

select distinct CMCo=p.CMCo
, Mth=p.PaidMth
, CMTrans=isnull(max(t.LastTrans),1) + ROW_NUMBER() over (PARTITION BY p.CMCo
		ORDER BY p.CMCo, p.PaidMth )
, CMAcct=p.CMAcct
, StmtDate = null    
, CMTransType=1
, SourceCo=p.CMCo
, Source='AP Payment'
, ActDate=p.PaidDate
, PostedDate=p.PaidDate
, Amount=p.Amount * -1
, ClearedAmt=0    
, BatchId=1
, CMRef=p.CMRef -- checks
, CMRefSeq=p.CMRefSeq
, Payee=max(p.Vendor)
, GLCo=max(p.APCo)
, CMGLAcct=max(a.GLAcct)
, Void='N'
, Purge='N'
, ClearDate=null 
, Description=convert(varchar(10),max(p.Vendor)) + '; ' + max(appd.Description)
, udSource = 'AP_CMDT'
, udConv='Y'
from APPH p 
	left join HQTC t on p.APCo=t.Co and p.PaidMth=t.Mth and t.TableName='bCMDT'
	left join CMDT c on p.CMCo=c.CMCo and p.CMAcct=c.CMAcct and p.CMRef=c.CMRef and p.CMRefSeq=c.CMRefSeq
	left join bAPPD appd on p.APCo=appd.APCo and p.CMCo=appd.CMCo and p.CMRef=appd.CMRef and p.CMRefSeq=appd.CMRefSeq
	join CMAC a on p.CMCo=a.CMCo and p.CMAcct=a.CMAcct
where p.APCo=@toco
  and p.PaidMth >= '01/01/2014'
group by p.CMCo, p.PaidMth, p.CMAcct, p.CMRef, p.CMRefSeq, p.PaidDate, p.Amount;



select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

--alter table bCMST CHECK CONSTRAINT FK_bCMST_bCMAC
--alter table bCMDT CHECK CONSTRAINT FK_bCMDT_bCMAC
--alter table bCMAC CHECK CONSTRAINT FK_bCMAC_bCMCO

ALTER Table bCMDT enable trigger all;
exec dbo.cvsp_Enable_Foreign_Keys
return @@error



GO
