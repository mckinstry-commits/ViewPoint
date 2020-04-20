SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRCA] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PR Craft Accumulations (PRCA)
	Created:	06.30.09
	Created by:	CR   
	Revisions:	1. None

**/



set @errmsg=''
set @rowcount=0

alter table bPRCA disable trigger all; 

--delete existing records
delete bPRCA where PRCo=@toco


-- add new trans
BEGIN TRAN
BEGIN TRY

insert bPRCA (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, 
	Class, EDLType, EDLCode, Basis, Amt, EligibleAmt, OldAPAmt, udRate, udSource,udConv
	,udCGCTable,udCGCTableID)

--Liabilities 
select PRCo=@toco
	, PRGroup=e.PRGroup
	, PREndDate=u.WkEndDate
	, Employee=u.EMPLOYEENUMBER
	, PaySeq=dense_rank()over (partition by u.COMPANYNUMBER, u.WkEndDate, u.EMPLOYEENUMBER
				order by u.COMPANYNUMBER, u.WkEndDate, u.CHECKDATE, u.EMPLOYEENUMBER,
								u.CHECKNUMBER)
	, Craft=x.Craft
	, Class=x.Class
	, EDLType=isnull(prd.VPType,'L')
	, EDLCode=isnull(prd.DLCode,0)
	, Basis=sum(u.REGHOURS+u.OVTHRS+u.OTHHRS)
	, Amt=sum(u.NUDEA)
	, EligibleAmt=sum(u.REGHOURS+u.OVTHRS+u.OTHHRS)
	, OldAPAmt=0
	, udRate=max(u.NRGDR)
	, udSource ='PRCA'
	, udConv='Y'
	,udCGCTable='PRTMUN',udCGCTableID=max(PRTMUNID)
from CV_CMS_SOURCE.dbo.PRTMUN u
	left join PREH e on e.PRCo=@toco and u.EMPLOYEENUMBER=e.Employee
	left join Viewpoint.dbo.budxrefPRDedLiab prd on prd.Company=@fromco
			--Add this link if there are different ded/liab by union 
			--and u.UNIONNO=prd.Craft 
			and convert(varchar(10),u.NUDTY)=prd.CMSDedCode
	join Viewpoint.dbo.budxrefUnion x on x.Company=@fromco and u.UNIONNO=x.CMSUnion
			and u.EMPLOYEECLASS=x.CMSClass and u.EMPLTYPE=x.CMSType
where u.COMPANYNUMBER=@fromco
	and x.Craft is not null 
	and x.Class is not null
group by u.COMPANYNUMBER, e.PRGroup, u.WkEndDate, u.EMPLOYEENUMBER, u.CHECKDATE, u.CHECKNUMBER,
	x.Craft, x.Class, prd.VPType, prd.DLCode


union all

--Earnings 
select PRCo=@toco
	, PRGroup=t.PRGroup
	, PREndDate=t.PREndDate
	, Employee = t.Employee
	, PaySeq = t.PaySeq
	, Craft = h.Craft
	, Class = h.Class
	, EDLType = t.EDLType
	, EDLCode = t.EDLCode
	, Basis = sum(h.Hours)
	, Amt = sum(h.Amount)
	, EligibleAmt=sum(t.EligibleAmt) 
	, OldAPAmt=0
	, udRate=0.000
	, udSource ='PRCA'
	, udConv='Y'
	,udCGCTable=null,udCGCTableID=null
from bPRDT t
	left outer join (select PRCo, PRGroup, PREndDate, Employee, 
							PaySeq, Craft, Class, EarnCode, Hours=sum(Hours), Amount=sum(Amt) 
						from bPRTH 
						group by PRCo, PRGroup, PREndDate, Employee, PaySeq, 
								Craft, Class, EarnCode/*, Hours*/) 
						as h 
						on t.PRCo=h.PRCo and t.PRGroup=h.PRGroup 
							and t.PREndDate=h.PREndDate and t.Employee=h.Employee 
							and t.PaySeq=h.PaySeq and h.EarnCode=t.EDLCode
where t.PRCo=h.PRCo and t.PRCo=@toco and t.EDLType ='E' 
	and h.Craft is not null 
	and h.Class is not null
group by t.PRCo, t.PRGroup, t.PREndDate, t.Employee, t.PaySeq, h.Craft, h.Class, 
	t.EDLType, t.EDLCode, h.EarnCode


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bPRCA enable trigger all;

return @@error

GO
