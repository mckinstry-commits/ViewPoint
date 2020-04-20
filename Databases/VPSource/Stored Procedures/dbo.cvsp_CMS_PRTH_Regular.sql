
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRTH_Regular] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:				Regular Time (PRTH)
	Created:			05.01.09
	Created by:			CR   
	Notes:				The deductions and liabilities build off of the earnings inserted previously 
							and the amounts from the CMS tables.
	Revisions:			1. 8.10.09 = CR changed InsState and InsCode, added nolocks, changed PostedDate 
								to use WEEKENDDATE instead of JOURNALDATE.
								2. 8.19.10 - JH - Added TC source as ud field to PRTH 

**/



set @errmsg=''
set @rowcount=0


--Declare Variables for functions
Declare @JobFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob')

--Get Customer Defaults
declare @defaultJCDept varchar(5), @defaultCraft varchar(10), @defaultClass varchar(10)

select @defaultJCDept=isnull(b.DefaultString,a.DefaultString) 
from  Viewpoint.dbo.budCustomerDefaults a
	full outer join  Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='JCDept' and a.TableName='bPRTH';

select @defaultCraft=isnull(b.DefaultString,a.DefaultString) 
from  Viewpoint.dbo.budCustomerDefaults a
	full outer join  Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Craft' and a.TableName='bPRTH';

select @defaultClass=isnull(b.DefaultString,a.DefaultString) 
from  Viewpoint.dbo.budCustomerDefaults a
	full outer join  Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Class' and a.TableName='bPRTH';

--Get earnings codes
declare @HrlyRegEC tinyint, @SalRegEC tinyint
select @HrlyRegEC=x.EarnCode 
from Viewpoint.dbo.budxrefPREarn x
	join bPREC e on e.PRCo=@toco and x.EarnCode=e.EarnCode
where e.Method='H' and Factor=1 and e.TrueEarns='Y'

select @SalRegEC=x.EarnCode 
from Viewpoint.dbo.budxrefPREarn x
	join bPREC e on e.PRCo=@toco and x.EarnCode=e.EarnCode
where e.Method='A' and Factor=1 and e.TrueEarns='Y'

--Get HQCO defaults
declare @PhaseGroup tinyint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco

-- Job formatting
declare @JobLen smallint, @SubJobLen smallint
select @JobLen = left(InputMask,1) from vDDDTc where Datatype = 'bJob';
select @SubJobLen = substring(InputMask,4,1) from vDDDTc where Datatype = 'bJob';


ALTER Table bPRTH disable trigger all;


-- delete existing trans
BEGIN tran
delete from bPRTH where PRCo=@toco;
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bPRTH (PRCo, PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate
,JCCo, Job, PhaseGroup, Phase, JCDept,GLCo,TaxState,UnempState,InsState,PRDept
,Cert,Craft,Class,Shift,EarnCode,Hours,Rate,Amt, BatchId, InsCode,
	udPaidDate, udCMCo, udCMAcct, udCMRef, udTCSource, udSchool,udSource,udConv,udCGCTable,udCGCTableID)

--Regular Earnings
select PRCo=@toco
	, PRGroup=e.PRGroup
	, PREndDate=PRTTCH.WkEndDate
	, Employee=PRTTCH.EMPLOYEENUMBER
	, PaySeq=PRTTCH.PaySeq
	, PostSeq=isnull((select max(PostSeq) 
			from PRTH b 
			where b.PRCo=@toco
					and b.PREndDate=PRTTCH.WkEndDate
					and b.Employee=PRTTCH.EMPLOYEENUMBER),0) 
				+ row_number() over(partition by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,PRTTCH.EMPLOYEENUMBER 
									order by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,PRTTCH.EMPLOYEENUMBER)
	, Type = 'J'
	, PostDate = PRTTCH.WkEndDate
	, JCCo=DISTCOMPANY+@toco-PRTTCH.COMPANYNUMBER
	, Job=case when PRTTCH.JOBNUMBER='' 
			then null 
			else 
				xj.VPJob
				--dbo.bfMuliPartFormat(right(space(@JobLen) + ltrim(rtrim(PRTTCH.JOBNUMBER)),@JobLen) + 
				--			left(PRTTCH.SUBJOBNUMBER,@SubJobLen),@JobFormat)
			end
	, PhaseGroup=@PhaseGroup
	, Phase=p.newPhase
	, JCDept=@defaultJCDept
	, GLCo=@toco
	, TaxState = isnull(s.TaxState,e.TaxState)
	, UnempState=isnull(s.TaxState,e.UnempState)
	, InsState = isnull(s.TaxState,e.InsState)
	, PRDept = e.PRDept
	, Cert=EXEMPTCERTPR
	, Craft=case when x.Class is not null and x.Craft is null then @defaultCraft else
				x.Craft end 
	, Class=case when x.Class is null and x.Craft is not null then @defaultClass else
				x.Class end 
	, Shift=SHIFTNO
	, EarnCode=case when e.HrlyRate=0 then @SalRegEC else @HrlyRegEC end
	, Hours = PRTTCH.REGHOURS
	, Rate = PRTTCH.REGRATE
	, Amt = PRTTCH.REGGROSS
	, BatchId = 0
	, InsCode = right('0000'+convert(varchar,PRTTCH.WCCODE),4) 
	, udPaidDate=substring(convert(nvarchar(max),PRTTCH.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),PRTTCH.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),PRTTCH.CHECKDATE),1,4)
	, udCMCo=g.CMCo
	, udCMAcct=g.CMAcct
	, udCMRef = PRTTCH.CHECKNUMBER
	, udTCSource='REG'
	, udSchoolDistrict = case when PRTTCH.CHLCD2=0 then NULL else PRTTCH.CHLCD2 end
	, udSource ='PRTH_Regular'
	, udConv='Y'
	,udCGCTable='PRTTCH',udCGCTableID=PRTTCHID
from CV_CMS_SOURCE.dbo.PRTTCH PRTTCH
	left join bPREH e with(nolock) on e.PRCo=@toco and EMPLOYEENUMBER=e.Employee
	left join bPRGR g on e.PRCo=g.PRCo and e.PRGroup=g.PRGroup
	left join Viewpoint.dbo.budxrefUnion x on x.Company=@fromco 
				and PRTTCH.UNIONNO=x.CMSUnion and PRTTCH.EMPLOYEECLASS=x.CMSClass 
				and PRTTCH.EMPLTYPE=x.CMSType
	left join Viewpoint.dbo.budxrefJCJobs xj
		on xj.COMPANYNUMBER = PRTTCH.COMPANYNUMBER and xj.DIVISIONNUMBER = PRTTCH.DIVISIONNUMBER and xj.JOBNUMBER = PRTTCH.JOBNUMBER
			and xj.SUBJOBNUMBER = PRTTCH.SUBJOBNUMBER
	left join Viewpoint.dbo.budxrefPhase p on p.Company=@fromco and PRTTCH.JCDISTRIBTUION=p.oldPhase
	left join (select StateCode, TaxState=max(Abbr) 
				from CV_CMS_SOURCE.dbo.TaxLimits
				group by StateCode)
				as s 
				on s.StateCode=convert(varchar(max),PRTTCH.STIDCODE)
where PRTTCH.REGGROSS<>0  
	and PRTTCH.COMPANYNUMBER=@fromco
order by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate, PRTTCH.CHECKDATE

select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPRTH enable trigger ALL;

return @@error

GO
