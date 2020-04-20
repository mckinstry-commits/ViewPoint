SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_PRIA] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

/**
=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS
=========================================================================
	Title:			PR Insurance Accum's (PRIA)
	Created:		10.01.09
	Created by:		JJH
	Revisions:		1. None
	Notes:			had a customer also use XPDPR in addition to XWCPR for the WC Amout, needed to add together.  CR
**/

set @errmsg=''
set @rowcount=0

-- delete existing trans
delete bPRIA where PRCo=@toco

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bPRIA (PRCo, PRGroup, PREndDate, Employee, PaySeq, State, InsCode,
	DLCode, Earnings, SubjectAmt, Rate, Amt, EligibleAmt, BasisEarnings, CalcBasis,udSource,udConv)
select h.PRCo
	, h.PRGroup
	, h.PREndDate
	, h.Employee
	, h.PaySeq
	, h.InsState
	, h.InsCode
	, DLCode=i.DLCode
	, Earnings = sum(case when h.EarnCode <> 150 then Amt else 0 end)
	, SubjectAmt = sum(case when h.EarnCode <> 150 then Amt else 0 end)
	, Rate = WC.Rate
	, Amt = WC.Amount
	, EligibleAmt = cast(round(sum(case when isnull(e.Factor,0)=0 then 0 else
				Amt/e.Factor end),2) as decimal(12,2))
	, BasisEarnings = sum(case when e.TrueEarns = 'Y' then Amt else 0 end)
	, CalcBasis = cast(round(sum(case when e.TrueEarns = 'Y' then 
				case when isnull(e.Factor,0)=0 then 0 else Amt/Factor end end),2) as decimal(12,2))
	, udSource ='PRIA'
	, udConv='Y'
from bPRTH h
	--Can't join to the table directly since there may be add'l codes on the state ins setup
	--Need to restrict to just one ded/liab code per state/ins code combo.
	join (select PRCo, State, InsCode, DLCode=max(DLCode)
			from bPRID 
			group by PRCo, State, InsCode)
			as i
			on h.PRCo=i.PRCo and h.InsState=i.State and h.InsCode=i.InsCode
	--Restrict earnings to just those that are subject to the ded/liab code
	join bPRDB PRDB on h.PRCo=PRDB.PRCo and i.DLCode=PRDB.DLCode and h.EarnCode=PRDB.EDLCode and PRDB.EDLType ='E'
	join bPREC e with(nolock) on h.PRCo=e.PRCo and h.EarnCode=e.EarnCode
	
	join (select COMPANYNUMBER, EMPLOYEENUMBER, WkEndDate, PaySeq,
				WCCODE, Rate=max(XWCRT/100), Amount=sum(XWCPR)  -- check XPDPR also.
		from CV_CMS_SOURCE.dbo.PRTWCH PRTWCH
		where PRTWCH.COMPANYNUMBER=@fromco
		group by COMPANYNUMBER, EMPLOYEENUMBER, WkEndDate, PaySeq, WCCODE)
		as WC 
		on WC.COMPANYNUMBER=@fromco and h.Employee=WC.EMPLOYEENUMBER 
			and h.PREndDate=WC.WkEndDate and h.PaySeq=WC.PaySeq
			and case when left(h.InsCode,1) = 0 
				then right(h.InsCode,3) 
				else h.InsCode end = WC.WCCODE 
	join bPREH p with(nolock) on h.PRCo=p.PRCo and h.Employee=p.Employee
where h.PRCo=@toco 
	and h.InsState is not null
group by h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, 
	h.InsState, h.InsCode, i.DLCode, WC.Rate, WC.Amount;



select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPRIA enable trigger ALL;

return @@error




GO
