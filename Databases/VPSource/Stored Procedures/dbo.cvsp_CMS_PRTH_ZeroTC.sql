
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:			Inserts records to PRTH - $0
	Created:		11.24.09	
	Created by:		VCS Technical Services - JJH  
	Revisions:		
		1. CMS has some liabilities/ded that are stored in a pay period w/out timecards.
			The first part of the code inserts a $0 record for any missing PRTH pay periods
			so PRTL continues to get updated.
		2. 8.19.10 - JH - Added TC source as ud field to PRTH 
		3. 03/19/2012 BBA - Added missing ud columns in the insert statement.
		4. 10/04/2013 BTC - Added JCJobs cross reference
		
**/


CREATE PROCEDURE [dbo].[cvsp_CMS_PRTH_ZeroTC] 
(@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 

as

set @errmsg=''
set @rowcount=0


--Get HQCO defaults
declare @PhaseGroup tinyint, @defaultCraft varchar(10), @defaultClass varchar(10)
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco

declare @defaultJCDept varchar(5)
select @defaultJCDept=isnull(b.DefaultString,a.DefaultString) 
from  Viewpoint.dbo.budCustomerDefaults a
full outer join  dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='JCDept' and a.TableName='bPRTH';

select @defaultCraft=isnull(b.DefaultString,a.DefaultString) 
from  Viewpoint.dbo.budCustomerDefaults a
full outer join  dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Craft' and a.TableName='bPRTH';

select @defaultClass=isnull(b.DefaultString,a.DefaultString) 
from  Viewpoint.dbo.budCustomerDefaults a
full outer join  dbo.budCustomerDefaults b 
	on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Class' and a.TableName='bPRTH';


alter table bPRPC disable trigger all;
alter table bPRPS disable trigger all;
alter table bPRTH disable trigger all;



 
-- add new trans
BEGIN TRAN
BEGIN TRY

--insert pay period record for those that don't exist
insert bPRPC (PRCo,PRGroup,PREndDate,BeginDate,MultiMth,BeginMth,
	LimitMth,Hrs,Days,Wks,Status,JCInterface,EMInterface,GLInterface,
	APInterface,LeaveProcess,Conv,MaxRegHrsInWeek1, MaxRegHrsInWeek2,udSource,udConv)
select 
	 PRCo = @toco
	,PRGroup=d.PRGroup
	,PREndDate=d.PREndDate
	,BeginDate=dateadd(dd,-6,d.PREndDate)
	,MultiMth = 'N'
	,BeginMth = convert(varchar(2),datepart(mm,d.PREndDate)) + '/01/' + 
			convert(varchar(4),datepart(yy,d.PREndDate))
	,LimitMth = convert(varchar(2),datepart(mm,d.PREndDate)) + '/01/' + 
			convert(varchar(4),datepart(yy,d.PREndDate))
	,Hrs=0
	,Days=0
	,Wks=0
	,Status=1
	,JCInterface='Y'
	,EMInterface='Y'
	,GLInterface='Y'
	,APInterface='Y'
	,LeaveProcess='Y'
	,Conv='N'
	,MaxRegHrsInWeek1 = 40
	,MaxRegHrsInWeek2 = 40
	,udSource ='PRTH_ZeroTC'
	,udConv='Y'
--select *	
from bPRDT d
	left join bPRTH h on h.PRCo=d.PRCo and h.PRGroup=d.PRGroup and h.PREndDate=d.PREndDate 
			and h.PaySeq=d.PaySeq 
			and h.Employee=d.Employee
	left join bPRPC p on d.PRCo=p.PRCo and d.PRGroup=p.PRGroup and d.PREndDate=p.PREndDate
where h.PRCo is null
	and p.PRCo is null
	and d.PRCo=@toco
group by d.PRCo, d.PRGroup, d.PREndDate;

--insert pay seq for $0 timecards
insert into bPRPS (PRCo, PRGroup, PREndDate, PaySeq, Description, Bonus, OverrideDirDep,udSource,udConv,
	udCGCTable,udCGCTableID)
select 
	 PRCo=d.PRCo
	,PRGroup=d.PRGroup
	,PREndDate=d.PREndDate
	,PaySeq=d.PaySeq
	,Description='Conversion'
	,Bonus='N'
	,OverrideDirDep='N'
	,udSource ='PRTH_ZeroTC'	
	,udConv='Y'
	,udCGCTable=null
	,udCGCTableID=null
from bPRDT d
	left join bPRTH h on h.PRCo=d.PRCo and h.PRGroup=d.PRGroup and h.PREndDate=d.PREndDate 
			and h.PaySeq=d.PaySeq 
			and h.Employee=d.Employee
	left join bPRPS s on d.PRCo=s.PRCo and d.PRGroup=s.PRGroup and d.PREndDate=s.PREndDate
		and d.PaySeq=s.PaySeq
where h.PRCo is null
	and d.PRCo=@toco
	and s.PRCo is null
group by d.PRCo, d.PRGroup, d.PREndDate, d.PaySeq;


--insert $0 timecards for pay periods that exist in PRTH but not in PRTL
insert bPRTH (PRCo, PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate
	,JCCo, Job, PhaseGroup, Phase, JCDept,GLCo,TaxState,UnempState,InsState,PRDept
	,Cert,Craft,Class,Shift,EarnCode,Hours,Rate,Amt, BatchId, InsCode,
	udPaidDate, udCMCo, udCMAcct, udCMRef, udTCSource,udSource,udConv,udCGCTable,udCGCTableID)
select @toco
	, e.PRGroup
	, d.WkEndDate
	, d.EMPLOYEENUMBER
	, d.PaySeq
	, PostSeq=isnull((select max(PostSeq) 
			from PRTH b 
			where b.PRCo=@toco
					and b.PREndDate=d.WkEndDate
					and b.Employee=d.EMPLOYEENUMBER),0) 
				+ row_number() over(partition by d.COMPANYNUMBER, d.WkEndDate,d.EMPLOYEENUMBER 
									order by d.COMPANYNUMBER, d.WkEndDate,d.EMPLOYEENUMBER)
	, Type='J'
	, PostDate=d.WkEndDate
	, JCCo=@toco
	, xj.VPJob --d.Job
	, PhaseGroup=@PhaseGroup
	, Phase=null
	, JCDept=@defaultJCDept
	, GLCo=@toco
	, max(e.TaxState)
	, max(e.UnempState)
	, max(e.InsState)
	, max(e.PRDept)
	, Cert='Y'
	, Craft=case when x.Class is not null and x.Craft is null then @defaultCraft else
				x.Craft end 
	, Class=case when x.Class is null and x.Craft is not null then @defaultClass else
				x.Class end 
	, Shift=1
	, EarnCode=max(e.EarnCode)
	, Hours=0
	, Rate=0
	, Amt=0
	, BatchId=0
	, max(e.InsCode)
	,udPaidDate=max(substring(convert(nvarchar(max),d.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),d.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),d.CHECKDATE),1,4))
	,udCMCo=g.CMCo
	,udCMAcct=g.CMAcct
	,udCMRef = d.CHECKNUMBER
	,udTCSource='ZERO'
	,udSource ='PRTH_ZeroTC'
	,udConv='Y'
	,udCGCTable='PRTMUN'
	,udCGCTableID=max(PRTMUNID)
from CV_CMS_SOURCE.dbo.PRTMUN d
left join Viewpoint.dbo.udxrefUnion x 
	on x.Company=@fromco 
		and d.UNIONNO=x.CMSUnion and d.EMPLOYEECLASS=x.CMSClass 
		and d.EMPLTYPE=x.CMSType
join bPREH e 
	on e.PRCo=@toco and e.Employee=d.EMPLOYEENUMBER
left join Viewpoint.dbo.budxrefJCJobs xj
	on xj.COMPANYNUMBER = d.COMPANYNUMBER and xj.DIVISIONNUMBER = d.DIVISIONNUMBER and xj.JOBNUMBER = d.JOBNUMBER
		and xj.SUBJOBNUMBER = d.SUBJOBNUMBER
left join bPRGR g
	on e.PRCo=g.PRCo and e.PRGroup=g.PRGroup
left join bPRTH h 
	on h.PRCo=@toco and h.PRGroup=e.PRGroup and h.PREndDate=d.WkEndDate
		and h.PaySeq=d.PaySeq 
		and h.Employee=d.EMPLOYEENUMBER
where h.PRCo is null
	and d.COMPANYNUMBER=@fromco
group by d.COMPANYNUMBER, e.PRGroup, d.WkEndDate, d.EMPLOYEENUMBER, d.PaySeq, xj.VPJob, --d.Job,
	g.CMCo, g.CMAcct, d.CHECKNUMBER, x.Craft, x.Class
	


/***************************End $0 timecards *****************/


select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bPRPC enable trigger all;
alter table bPRPS enable trigger all;
alter table bPRTH enable trigger all;


return @@error


GO
