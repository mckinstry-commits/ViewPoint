SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_PRAE] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as






/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:				PR Employee Auto Earnings (PRAE)
	Created:			10.26.09
	Created by:			JJH        
	Revisions:			1. None
**/


set @errmsg=''
set @rowcount=0


--Get Customer defaults
declare @defaultSeq tinyint, @StdHours char(1), @defaultPaySeq tinyint,  @defaultFreq char(1),
	@OvrStdLimitYN char(1), @SalEarnCode int

select @defaultSeq=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Seq' and a.TableName='bPRAE';

select @StdHours=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='StdHours' and a.TableName='bPRAE';

select @defaultPaySeq=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PaySeq' and a.TableName='bPRAE';

select @defaultFreq=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Frequency' and a.TableName='bPRAE';

select @OvrStdLimitYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OvrStdLimitYN' and a.TableName='bPRAE';

select @SalEarnCode=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='SalEarnCode' and a.TableName='bPREH';


ALTER Table bPRAE disable trigger all;

-- delete existing trans
BEGIN tran
delete from bPRAE where PRCo=@toco
COMMIT TRAN;


with PRNegEarn
	(EarnCode, PRCo, Employee, Seq, PRDept, InsCode, Craft, Class,
	StdHours, Hours, PaySeq, RateAmt, OvrStdLimitYN, LimitOvrAmt, Frequency, udSource,udConv,udCGCTable,udCGCTableID)
as
(

--CMS Negative Earnings to VP Negative Earnings
select distinct  prearn.EarnCode 
	,PRCo=@toco
	,Employee=D.DEENO
	,Seq=@defaultSeq
	,PRDept=max(H.PRDept)
	,InsCode=max(H.InsCode)
	,Craft=null--usually not on negative timecards
	,Class=null--usually not on negative timecards
	,StdHours=@StdHours
	,Hours=0
	,PaySeq=@defaultPaySeq
	,RateAmt=case when DDEPC=0 then max(D.DAMDE)*-1 else max(DDEPC)/100*-1 end
	,OvrStdLimitYN = case when max(D.DDELM) <> 0 then 'Y' else 'N' end
	,LimitOvrAmt = max(D.DDELM)*-1
	,Frequency = @defaultFreq
	,udSource ='PRAE'
	, udConv='Y'
	,udCGCTable='PRPDED',udCGCTableID=null
from CV_CMS_SOURCE.dbo.PRPDED D
	join CV_CMS_SOURCE.dbo.PRTMST PRTMST on D.DCONO=PRTMST.COMPANYNUMBER 
			and D.DEENO=PRTMST.EMPLOYEENUMBER
	join Viewpoint.dbo.budxrefPREarn prearn on prearn.Company=@fromco 
		and convert(int, D.DDENO)=prearn.CMSDedCode
	join bPREH H on H.PRCo=@toco and D.DEENO=H.Employee
	join (select DCONO, DEENO, DDENO, DDTCM=max(DDTCM)
			from CV_CMS_SOURCE.dbo.PRPDED
			group by DCONO, DEENO, DDENO) 
			as DED 
			on D.DCONO=DED.DCONO and D.DEENO=DED.DEENO and D.DDENO=DED.DDENO and D.DDTCM=DED.DDTCM
where D.DCONO=@fromco
	and (DDEPC<>0 or DAMDE<>0) and prearn.CMSCode<>'OTH'
group by prearn.EarnCode, D.DCONO, D.DEENO, D.DDENO, DED.DDTCM, D.DDEPC

union all

--HRTMBN Benefit
select distinct prearn.EarnCode
	, PRCo=@toco
	, Employee=hr.EMPLOYEENUMBER
	, Seq=@defaultSeq
	, PRDept=H.PRDept
	, InsCode=H.InsCode
	, Craft=H.Craft
	, Class=H.Class
	, StdHours=@StdHours
	, Hours=0
	, PaySeq=@defaultPaySeq
	, RateAmt=max(DEDUCTIONAMT)
	, OvrStdLimitYN=@OvrStdLimitYN
	, LimitOvrAmt=0
	, Frequency=@defaultFreq
	, udSource ='PRAE'
	, udConv='Y'
	,udCGCTable='HRTMBN',udCGCTableID=max(HRTMBNID)
from CV_CMS_SOURCE.dbo.HRTMBN hr
	join(select COMPANYNUMBER, EMPLOYEENUMBER, PREndDate=Max(PREndDate) 
		from CV_CMS_SOURCE.dbo.HRTMBN 
		group by COMPANYNUMBER, EMPLOYEENUMBER) 
		as Ded 
		on hr.COMPANYNUMBER=Ded.COMPANYNUMBER 
				and hr.EMPLOYEENUMBER=Ded.EMPLOYEENUMBER 
				and hr.PREndDate=Ded.PREndDate 
	join Viewpoint.dbo.budxrefPREarn prearn on prearn.Company=@fromco
		 and hr.BENEFITNUMBER=prearn.CMSDedCode and prearn.CMSCode='H'
	join bPREH H on @toco=H.PRCo and hr.EMPLOYEENUMBER=H.Employee
where hr.COMPANYNUMBER=@fromco
group by prearn.EarnCode, hr.COMPANYNUMBER, hr.EMPLOYEENUMBER, hr.BENEFITNUMBER, 
	H.PRDept, H.InsCode, H.Craft, H.Class


union all

--Salary
select distinct EarnCode=@SalEarnCode
	,PRCo=PREH.PRCo
	,Employee=PREH.Employee
	,Seq=@defaultSeq
	,PRDept=PREH.PRDept
	,InsCode=PREH.InsCode
	,Craft=PREH.Craft
	,Class=PREH.Class
	,StdHours=@StdHours
	,Hours=0
	,PaySeq=@defaultPaySeq
	,RateAmt=PREH.SalaryAmt
	,OvrStdlimitYN=@OvrStdLimitYN
	,LimitOvrAmt=0
	,Frequency=@defaultFreq
	,udSource ='PRAE'
	, udConv='Y'
	,udCGCTable=null,udCGCTableID=null
from bPREH PREH
where PREH.PRCo=@toco
	and PREH.EarnCode=@SalEarnCode
)


insert bPRAE(PRCo, Employee, EarnCode, Seq, 
	PRDept, InsCode, Craft, Class,
	StdHours, Hours, PaySeq,  RateAmt, OvrStdLimitYN, LimitOvrAmt, Frequency, udSource,udConv)
select PRCo
	, Employee
	, EarnCode
	, Seq
	, PRDept=max(PRDept)
	, InsCode=max(InsCode)
	, Craft=max(Craft)
	, Class=max(Class)
	, StdHours=max(StdHours)
	, Hours=sum(Hours)
	, PaySeq=max(PaySeq)
	, RateAmt=max(RateAmt)
	, OvrStdLimitYN=max(OvrStdLimitYN)
	, LimitOvrAmt=max(LimitOvrAmt)
	, Frequency=min(Frequency)
	, udSource = MAX (udSource)
	, udConv=max(udConv)
from PRNegEarn
group by PRCo, Employee, EarnCode, Seq
order by PRCo, Employee, EarnCode



select @rowcount=@@rowcount;

ALTER Table bPRAE enable trigger all;

return @@error

GO
