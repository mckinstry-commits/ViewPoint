
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright © 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:		AR Receipts to CM (CMDT)
	Created:	10.12.09
	Created by:	VCS Technical Services - AB    
	Revisions:	1. 03/19/2012 BBA - Added drip code and changed to use CREATE PROC instead
					alter.
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_AR_CMDT] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 
as

set @errmsg=''
set @rowcount=0


declare @CMCo int
select @CMCo=CMCo
from ARCO where ARCo=@toco

alter table bCMDT disable trigger all;
exec cvsp_Disable_Foreign_Keys;


-- delete existing trans
BEGIN tran
delete from bCMDT where CMCo=@CMCo and SourceCo=@toco and CMTransType=2
	and udConv = 'Y';
COMMIT TRAN;


-- add new trans
BEGIN TRAN
BEGIN TRY

Insert bCMDT (CMCo, Mth, CMTrans, CMAcct, CMTransType, 
	SourceCo, Source, ActDate, PostedDate, 
	Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, 
	GLCo, CMGLAcct, Void, Purge,udSource,udConv)	

select CMCo=h.CMCo
	, Mth=h.Mth
	, CMTrans=isnull(t.LastTrans,0)+row_number()over(Partition by h.CMCo, h.Mth Order by h.CMCo, h.Mth)
	, CMAcct=h.CMAcct
	, CMTransType=2
	, SourceCo=h.ARCo
	, Source='AR Receipt'
	, ActDate=h.TransDate
	, PostedDate=h.TransDate
	, Description=h.Description
	, Amount=h.CreditAmt
	, ClearedAmt=0
	, BatchId=1
	, CMRef=h.CMDeposit
	, CMRefSeq=row_number()over(Partition by h.CMDeposit Order by h.CMCo, h.Mth, h.CMAcct, h.CMDeposit)
	, GLCo=c.GLCo
	, CMGLAcct=c.GLAcct
	, Void='N'
	, Purge='N' 
	, udSource ='AR_CMDT'
	, udConv='Y'
	
from bARTH h
	left join bHQTC t on h.ARCo=t.Co and h.Mth=t.Mth and t.TableName='bCMDT'
	left join bCMAC c on h.CMCo=c.CMCo and h.CMAcct=c.CMAcct
where h.ARCo=@toco
	and h.ARTransType ='P' 
	and h.CreditAmt<>0 ;
	

alter table bCMDT enable trigger all;
 exec cvsp_Enable_Foreign_Keys;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bCMDT enable trigger all;

return @@error

GO
