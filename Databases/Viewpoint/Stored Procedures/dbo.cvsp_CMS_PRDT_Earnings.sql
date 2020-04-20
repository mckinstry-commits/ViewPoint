SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRDT_Earnings] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PR Transaction Detail (PRDT) - Earnings
	Created:	10.26.09
	Created by:	JJH   
	Revisions:	1. None
**/



set @errmsg=''
set @rowcount=0



ALTER Table bPRDT disable trigger all;


-- delete existing trans
BEGIN tran
delete from bPRDT where PRCo=@toco and EDLType='E';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert into bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, 
		EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt, 
		UseOver, OverAmt, OverProcess, VendorGroup, 
		Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, 
		OldMth, OldVendor, OldAPMth, OldAPAmt, udPaidDate, udCMCo, udCMAcct, udCMRef, udSource,udConv )

select h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq,
	EDLType='E', h.EarnCode, Hours=sum(h.Hours), Amount=sum(h.Amt), SubjectAmt=0,
	EligibileAmt=0, UseOver='N', OverAmt=0, OverProcess='N', VendorGroup=null,
	Vendor=null, APDesc=null, OldHours=sum(h.Hours), OldAmt=sum(h.Amt), OldSubject=0,
	OldEligible=0, OldMth=null, OldVendor=null, OldAPMth=null, OldAPAmt=0,
	udPaidDate=max(h.udPaidDate), udCMCo=max(h.udCMCo), udCMAcct=max(h.udCMAcct),
	udCMRef=max(h.udCMRef), udSource ='PRDT_Earnings', udConv='Y'
from bPRTH h
where h.PRCo=@toco
group by h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq,h.EarnCode

select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bPRDT enable trigger all;

return @@error


	




GO
