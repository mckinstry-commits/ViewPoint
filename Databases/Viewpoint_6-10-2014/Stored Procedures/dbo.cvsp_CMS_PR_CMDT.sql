SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_PR_CMDT] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		CM Detail - PR (CMDT)
	Created:	06.01.09
	Created by:	CR    
	Revisions:	1. None
	Notes:		Inserts PR Checks into CMDT
**/


set @errmsg=''
set @rowcount=0



ALTER Table bCMDT disable trigger all;
exec dbo.cvsp_Disable_Foreign_Keys
--delete trans
BEGIN TRAN
delete bCMDT where CMCo=@toco and Source='PR Update';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bCMDT (CMCo, Mth,CMTrans,CMAcct,CMTransType,SourceCo,Source
,ActDate,PostedDate,Amount,ClearedAmt,BatchId,CMRef,CMRefSeq,Payee
,GLCo,CMGLAcct,Void,Purge,Description,udSource,udConv)


select CMCo= p.CMCo
	, Mth=p.PaidMth
	, CMTrans=isnull(t.LastTrans,1)+row_number()over
			(partition by p.CMCo, p.PaidMth order by p.CMCo, p.PaidMth)
	, CMAcct=p.CMAcct
	, CMTransType=1
	, SourceCo=p.PRCo
	, Source='PR Update'
	, ActDate=p.PaidDate
	, PostedDate=p.PaidDate
	, Amount=p.PaidAmt*-1
	, ClearedAmount=0
	, BatchId=0
	, CMRef=p.CMRef
	, CMRefSeq=p.CMRefSeq
	, Payee=p.Employee
	, GLCo=p.PRCo
	, CMGLAcct=isnull(c.GLAcct,'')
	, Void='N'
	, Purge='N'
	, Description=convert(varchar(10),PREndDate,101)+ '  '+ preh.LastName 
	, udSource ='PR_CMDT'
	, udConv='Y'
from bPRPH p 
	left join bCMAC c on p.CMCo=c.CMCo and p.CMAcct=c.CMAcct
	left join bHQTC t on p.CMCo=t.Co and p.PaidMth=t.Mth and t.TableName='bCMDT'
	left join bPREH preh on p.CMCo=preh.PRCo and p.Employee=preh.Employee
where p.CMCo=@toco
  and p.PaidMth >= '01/01/2014'



select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bCMDT enable trigger all;
exec dbo.cvsp_Enable_Foreign_Keys
return @@error


GO
