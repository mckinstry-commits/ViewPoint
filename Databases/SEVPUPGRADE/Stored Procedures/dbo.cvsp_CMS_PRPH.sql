SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRPH] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PR Payment History (PRPH)
	Created:	06.01.09
	Created by:	CR   
	Revisions:	1. None

**/



set @errmsg=''
set @rowcount=0

alter table bPRPH disable trigger all; 

--delete existing records
delete bPRPH where PRCo=@toco;


-- add new trans
BEGIN TRAN
BEGIN TRY

insert bPRPH (PRCo, CMCo, CMAcct, PayMethod,CMRef,CMRefSeq,EFTSeq, PRGroup
	, PREndDate, Employee, PaySeq, ChkType,PaidDate, PaidMth
	,Hours,Earnings,Dedns,	PaidAmt,NonTrueAmt, Void,Purge, udSource,udConv	)



select q.PRCo
	, q.CMCo
	, q.CMAcct
	, q.PayMethod
	, q.CMRef
	--Check to see if this check exists from AP in CMDT, if so, change the seq #
	, CMRefSeq=isnull(q.CMRefSeq,0)
	, EFTSeq=isnull(q.EFTSeq, 0)
	, q.PRGroup
	, q.PREndDate
	, q.Employee
	, q.PaySeq
	, ChkType=q.ChkType
	, q.PaidDate
	, q.PaidMth
	, q.Hours
	, q.Earnings
	, q.Dedns
	, PaidAmt=isnull(q.Earnings,0)-isnull(q.Dedns,0)
	, NonTrueAmt= isnull(dte.SumAmount,0)
	, Void='N'
	, Purge='N'
	, udSource ='PRPH'
	, udConv='Y'
from bPRSQ q
left join ( select te.PRCo, te.PRGroup, te.PREndDate, te.Employee, te.PaySeq, sum(te.Amount) as SumAmount
                  from (      select dt.PRCo, dt.PRGroup, dt.PREndDate, dt.Employee, dt.PaySeq 
                                    ,dt.EDLType, dt.EDLCode, dt.Amount 
                              from bPRDT dt
                  inner join bPREC ec
                        on dt.PRCo=ec.PRCo and dt.EDLCode=ec.EarnCode and ec.TrueEarns='N'
                  ) te
                  group by te.PRCo, te.PRGroup, te.PREndDate, te.Employee, te.PaySeq
                  ) dte
      on q.PRCo=dte.PRCo and q.PRGroup=dte.PRGroup and q.PREndDate=dte.PREndDate
            and q.Employee=dte.Employee and q.PaySeq=dte.PaySeq

where q.CMRef is not null 
	and q.PRCo=@toco
	and q.PaidDate is not null



select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bPRPH enable trigger all; 

return @@error

GO
