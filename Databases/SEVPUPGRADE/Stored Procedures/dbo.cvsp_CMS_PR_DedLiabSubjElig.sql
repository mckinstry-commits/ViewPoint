SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PR_DedLiabSubjElig] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:			Updates Ded/Liab "temp" table with subj and elig amounts
	Created:		11.24.09	
	Created by:		JJH  
	Notes:			This relies on the customer's setups for ded/liab codes
	Revisions:		1. None

**/



set @errmsg=''
set @rowcount=0



-- add new trans
BEGIN TRAN
BEGIN TRY

--Make sure all records have a paid date
alter table bPRDT disable trigger all;
update bPRDT set bPRDT.udPaidDate=t.PaidDate
from bPRDT
	join (select PRCo, PREndDate, PaySeq, Employee, PaidDate=max(isnull(udPaidDate, PREndDate))
		from bPRDT
		group by PRCo, PREndDate, PaySeq, Employee)
		as t
		on bPRDT.PRCo=t.PRCo and bPRDT.PREndDate=t.PREndDate and bPRDT.PaySeq=t.PaySeq
			and bPRDT.Employee=t.Employee
where bPRDT.udPaidDate is null;
alter table bPRDT enable trigger all;

--Update Subject Amounts based on PRDT Earnings and PRDL setups (earnings subj to ded/liab)
--Update Eligible Amounts on non-limit codes
update CV_CMS_SOURCE.dbo.DedLiabByEmp 
	set SubjectAmt=isnull(subjST.SubjectAmt, subj.SubjectAmt)+isnull(pretax.SubjectAmt,0), 
		EligibleAmt=isnull(subjST.EligibleAmt, subj.EligibleAmt)+ISNULL(pretax.EligibleAmt,0)
from CV_CMS_SOURCE.dbo.DedLiabByEmp 
	join (select PRCo=d.Company, d.Employee, d.PREndDate, d.PaySeq, 
				d.EDLType, d.EDLCode, 
				SubjectAmt=sum(e.Amount),
				EligibleAmt=sum(case when d.LimitYN='N' and isnull(b.SubjectOnly,'N')='N'
						then e.Amount else 0 end)
			from CV_CMS_SOURCE.dbo.DedLiabByEmp d
				--join to the DLCode setup to restrict to just the earnings that
				--are subject to this ded/liab code
				join bPRDB b on d.Company=b.PRCo and d.EDLCode=b.DLCode and b.EDLType = 'E'
				--pull all subject earnings from PRDT
				join bPRDT e on e.PRCo=b.PRCo and e.EDLType='E' and b.EDLType = 'E'
					and d.PREndDate=e.PREndDate and d.Employee=e.Employee 
					and d.PaySeq=e.PaySeq
					and b.EDLCode=e.EDLCode 
				left join bPREC PREC on e.PRCo=PREC.PRCo and e.EDLCode=PREC.EarnCode and e.EDLType='E'
			group by d.Company, d.Employee, d.PREndDate, d.PaySeq, d.EDLType, d.EDLCode)
			as subj
			on subj.PRCo=CV_CMS_SOURCE.dbo.DedLiabByEmp.Company
				and subj.Employee=CV_CMS_SOURCE.dbo.DedLiabByEmp.Employee
				and subj.PREndDate=CV_CMS_SOURCE.dbo.DedLiabByEmp.PREndDate
				and subj.PaySeq=CV_CMS_SOURCE.dbo.DedLiabByEmp.PaySeq
				and subj.EDLType=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLType
				and subj.EDLCode=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLCode
	--The next join is used to calculate state based ded/lib subj amounts
	--It can't look at PRDT for earnings since that is not state specific
	--It goes out to PRTH and finds the timecards with the matching state info.
	left join (select PRCo=d.Company, d.Employee, d.PREndDate, d.PaySeq, 
				d.EDLType, d.EDLCode, 
				SubjectAmt=sum(e.Amt),
				EligibleAmt=sum(case when d.LimitYN='N' and isnull(b.SubjectOnly,'N')='N'
						then e.Amt else 0 end)
			from CV_CMS_SOURCE.dbo.DedLiabByEmp d
				--find the state code for state tax ded 
				left join PRSI s on d.Company=s.PRCo and d.EDLCode=s.TaxDedn and d.EDLType='D'
				--find the state code for state SUTA
				left join PRSI u on d.Company=u.PRCo and d.EDLCode=u.SUTALiab and d.EDLType='L'
				--join to the DLCode setup to restrict to just the earnings that
				--are subject to this ded/liab code
				join bPRDB b on d.Company=b.PRCo and d.EDLCode=b.DLCode and b.EDLType = 'E'
				--pull all subject earnings from PRTH
				join bPRTH e on e.PRCo=b.PRCo 
					and d.PREndDate=e.PREndDate and d.Employee=e.Employee 
					and d.PaySeq=e.PaySeq
					and b.EDLCode=e.EarnCode and b.EDLType='E'
					and isnull(s.State,u.State)=e.TaxState 
				left join bPREC PREC on e.PRCo=PREC.PRCo and e.EarnCode=PREC.EarnCode 
			where d.StateYN='Y'
			group by d.Company, d.Employee, d.PREndDate, d.PaySeq, d.EDLType, d.EDLCode)
			as subjST
			on subjST.PRCo=CV_CMS_SOURCE.dbo.DedLiabByEmp.Company
				and subjST.Employee=CV_CMS_SOURCE.dbo.DedLiabByEmp.Employee
				and subjST.PREndDate=CV_CMS_SOURCE.dbo.DedLiabByEmp.PREndDate
				and subjST.PaySeq=CV_CMS_SOURCE.dbo.DedLiabByEmp.PaySeq
				and subjST.EDLType=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLType
				and subjST.EDLCode=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLCode

----  Pre-Tax Deductions		
		
left join (select PRCo=d.Company, d.Employee, d.PREndDate, d.PaySeq, 
				d.EDLType, b.DLCode,
				SubjectAmt=sum(d.Amount*-1),
				EligibleAmt=sum(case when /*d.LimitYN='N' and*/ isnull(b.SubjectOnly,'N')='N'
						then d.Amount*-1 else 0 end)
			from CV_CMS_SOURCE.dbo.DedLiabByEmp d
				--join to the DLCode setup to restrict to just the earnings that
				--are subject to this ded/liab code
			 left join bPRDB b on d.Company=b.PRCo and d.EDLCode=b.EDLCode and b.EDLType='D'
	--/*added*/join bPRDL PRDL on b.PRCo=PRDL.PRCo and b.EDLCode=PRDL.DLCode and PRDL.PreTax='Y'
			group by d.Company, d.Employee, d.PREndDate, d.PaySeq, d.EDLType,  b.DLCode)
			as pretax
			on pretax.PRCo=CV_CMS_SOURCE.dbo.DedLiabByEmp.Company
						and pretax.Employee=CV_CMS_SOURCE.dbo.DedLiabByEmp.Employee
						and pretax.PREndDate=CV_CMS_SOURCE.dbo.DedLiabByEmp.PREndDate
						and pretax.PaySeq=CV_CMS_SOURCE.dbo.DedLiabByEmp.PaySeq
						--and pretax.EDLType=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLType
/* changed this link*/  and pretax.DLCode=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLCode






--Update Running total fields that will be used to calculate when limits have been reached
update CV_CMS_SOURCE.dbo.DedLiabByEmp 
	set CurrentRT=rt.CurrentRT, PriorRT=rt.PriorRT
from CV_CMS_SOURCE.dbo.DedLiabByEmp 
	join (select PRCo=d.Company, d.Employee, d.PREndDate, d.PaySeq, 
				d.EDLType, d.EDLCode, 
				CurrentRT=(select sum(e.SubjectAmt) 
							from CV_CMS_SOURCE.dbo.DedLiabByEmp e
							where e.Company=d.Company
								and e.PREndDate<=d.PREndDate
								--only want to restrict by pay sequence when it's the same pay period
								and e.PaySeq<=case when e.PREndDate=d.PREndDate then d.PaySeq else 255 end
								and e.Employee=d.Employee
								and e.EDLCode=d.EDLCode
								and e.EDLType=d.EDLType
								and year(e.PaidDate)=year(d.PaidDate)),
				PriorRT=(select sum(e.SubjectAmt) 
							from CV_CMS_SOURCE.dbo.DedLiabByEmp e
							where e.Company=d.Company
								--need to pick up prior pay sequences in the same pay period too
								and e.PREndDate< case when e.PREndDate=d.PREndDate then 
														case when e.PaySeq=d.PaySeq then d.PREndDate 
														else dateadd(d,1,d.PREndDate) end 
												else d.PREndDate end
								--only want to restrict by pay sequence when it's the same pay period
								and e.PaySeq<case when e.PREndDate=d.PREndDate then d.PaySeq else 255 end
								and e.Employee=d.Employee
								and e.EDLCode=d.EDLCode
								and e.EDLType=d.EDLType
								and year(e.PaidDate)=year(d.PaidDate))
			from CV_CMS_SOURCE.dbo.DedLiabByEmp d
			where d.LimitYN='Y') 
			as rt
			on rt.PRCo=CV_CMS_SOURCE.dbo.DedLiabByEmp.Company
				and rt.Employee=CV_CMS_SOURCE.dbo.DedLiabByEmp.Employee
				and rt.PREndDate=CV_CMS_SOURCE.dbo.DedLiabByEmp.PREndDate
				and rt.PaySeq=CV_CMS_SOURCE.dbo.DedLiabByEmp.PaySeq
				and rt.EDLType=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLType
				and rt.EDLCode=CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLCode
where CV_CMS_SOURCE.dbo.DedLiabByEmp.LimitYN='Y'


--Update Eligible Amounts on codes with limits
update CV_CMS_SOURCE.dbo.DedLiabByEmp 
set EligibleAmt=case when l.LimitAmt is null then isnull(CV_CMS_SOURCE.dbo.DedLiabByEmp.SubjectAmt,0)
	else 
		case when isnull(CV_CMS_SOURCE.dbo.DedLiabByEmp.CurrentRT,0) >= isnull(l.LimitAmt,0) 
				then
						(case when isnull(CV_CMS_SOURCE.dbo.DedLiabByEmp.PriorRT,0)< isnull(l.LimitAmt,0)
							then isnull(l.LimitAmt,0)-isnull(CV_CMS_SOURCE.dbo.DedLiabByEmp.PriorRT,0) 
							else 0 end)
				else isnull(CV_CMS_SOURCE.dbo.DedLiabByEmp.SubjectAmt,0) end 
	end
from CV_CMS_SOURCE.dbo.DedLiabByEmp
	left join CV_CMS_SOURCE.dbo.TaxLimits l on CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLType=l.EDLType
			and CV_CMS_SOURCE.dbo.DedLiabByEmp.EDLCode=l.EDLCode
			and year(CV_CMS_SOURCE.dbo.DedLiabByEmp.PaidDate)=l.Year
where CV_CMS_SOURCE.dbo.DedLiabByEmp.LimitYN='Y'  

select @rowcount=@@rowcount


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;



return @@error

GO
