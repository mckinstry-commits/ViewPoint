SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRDT_DedLiab] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:				PR Transaction Detail (PRDT) - Deductions and Liabilities
	Created:			10.12.09
	Created by:	CR   
	Notes:			The deductions and liabilities build off of the earnings inserted previously and the amounts from the CMS tables.
	Revisions:		1. None

**/



set @errmsg=''
set @rowcount=0




ALTER Table bPRDT disable trigger all;


-- delete existing trans
BEGIN tran
delete from bPRDT where PRCo=@toco and EDLType in ('D','L');
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert into bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, 
		EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt, 
		UseOver, OverAmt, OverProcess, VendorGroup, 
		Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, 
		OldMth, OldVendor, OldAPMth, OldAPAmt, udPaidDate, udCMCo, udCMAcct, udCMRef, udSource,udConv
		,udCGCTable,udCGCTableID)


select d.Company
	, e.PRGroup
	, d.PREndDate
	, d.Employee
	, d.PaySeq
	, d.EDLType
	, d.EDLCode
	, Hours=0
	, sum(d.Amount)
	, SubjectAmt=sum(isnull(d.SubjectAmt,0))
	, EligibleAmt=sum(isnull(d.EligibleAmt,0))
	, UseOver='N'
	, OverAmt=0
	, OverProcess='N'
	, VendorGroup=null
	, Vendor=null
	, APDesc=null
	, OldHours=0
	, OldAmt=sum(d.Amount)
	, OldSubject=sum(isnull(d.SubjectAmt,0))
	, OldEligible=sum(isnull(d.EligibleAmt,0))
	, OldMth=null
	, OldVendor=null
	, OldAPMth=null
	, OldAPAmt=0
	, udPaidDate=max(d.PaidDate)
	, udCMCo=max(g.CMCo)
	, udCMAcct=max(g.CMAcct)
	, udCMRef=max(d.CMRef)
	, udSource ='PRDT_DedLiab'
	, udConv='Y'
	,max(d.udCGCTable)
	,max(d.udCGCTableID)
from CV_CMS_SOURCE.dbo.DedLiabByEmp d
	join bPREH e on d.Company=e.PRCo and d.Employee=e.Employee
	join bPRGR g on e.PRCo=g.PRCo and e.PRGroup=g.PRGroup
where d.Company=@toco 
group by d.Company, e.PRGroup, d.PREndDate, d.Employee, d.PaySeq
	,d.EDLType, d.EDLCode

select @rowcount=@@rowcount


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bPRDT enable trigger all;

return @@error

GO
