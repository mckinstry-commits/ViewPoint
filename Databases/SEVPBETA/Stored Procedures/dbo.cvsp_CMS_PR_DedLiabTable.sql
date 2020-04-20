SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PR_DedLiabTable] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Loads Deductions/Liabilities by employee for each check
	Created:	10.12.09
	Created by:	JJH   
	Notes:		This table will be used later to populate PRDT after subj/elig are determined
	Revisions:	1. None

**/



set @errmsg=''
set @rowcount=0


--get Customer Defaults
declare @exclCraft varchar(10), @defaultstatecode int
select @exclCraft=isnull(b.DefaultString,a.DefaultString) 
from CustomerDefaults a
	full outer join CustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='EXCL_UNION' and a.TableName='bPRDT';

select @defaultstatecode=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from CustomerDefaults a
full outer join CustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='StateCode' and a.TableName='bPRDT';

--insert deduction/liability balances into one table from multiple sources
if not exists (select name from CV_CMS_SOURCE.dbo.sysobjects where name ='DedLiabByEmp')
begin
	create table CV_CMS_SOURCE.dbo.DedLiabByEmp 
		(Company	smallint		not null, 
		Employee	decimal(6,0)	not null,
		PREndDate	smalldatetime	not null,
		PaySeq		tinyint			not null,
		PaidDate	smalldatetime	null,
		CMRef		varchar(15)		null,
		EDLType		char(1)			not null,
		EDLCode		int				not null,
		Amount		decimal(15,2)	null,
		SubjectAmt	decimal(15,2)	null,
		EligibleAmt	decimal(15,2)	null,
		CurrentRT	decimal(15,2)	null,
		PriorRT		decimal(15,2)	null,
		LimitYN		char(1)			null,
		StateYN		char(1)			null,
		udSource	varchar(30)		null,
		udConv		varchar(1)		null
		,udCGCTable varchar(10)		null,
		udCGCTableID decimal(12,0) null);

create unique clustered index iDedLiabEmp on CV_CMS_SOURCE.dbo.DedLiabByEmp
	(Company, Employee, PREndDate, PaySeq, EDLType, EDLCode, PaidDate, CMRef);
create nonclustered index ciRunTotal on CV_CMS_SOURCE.dbo.DedLiabByEmp (Company, Employee, PREndDate,
		PaySeq, EDLCode, EDLType);
create nonclustered index ciPaidDate on CV_CMS_SOURCE.dbo.DedLiabByEmp
(Company, Employee, PREndDate, PaySeq, EDLType, EDLCode, PaidDate);


end
--Remove records
truncate table CV_CMS_SOURCE.dbo.DedLiabByEmp ;

-- add new trans
BEGIN TRAN
BEGIN TRY


--Federal Taxes
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, s.EMPLOYEENUMBER
	, s.WkEndDate 
	, PaySeq=s.PaySeq
	, PaidDate=substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
	, CMRef=s.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=PRFI.TaxDedn
	, Amount=sum(s.FEDINCTAX)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource = 'PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTHST',udCGCTableID=max(PRTHSTID)
from CV_CMS_SOURCE.dbo.PRTHST s
	join bPRFI PRFI on PRFI.PRCo=@toco 
	join bPRDL PRDL on PRFI.PRCo=PRDL.PRCo and PRFI.TaxDedn=PRDL.DLCode
where s.COMPANYNUMBER=@fromco
group by s.COMPANYNUMBER, s.EMPLOYEENUMBER, s.WkEndDate, s.CHECKDATE, s.CHECKNUMBER,
	PRDL.DLType, PRFI.TaxDedn, s.PaySeq

select @rowcount=@@rowcount;

--FUTA
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN,udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, h.EMPLOYEENUMBER
	, h.WkEndDate 
	, PaySeq=h.PaySeq
	, PaidDate=substring(convert(nvarchar(max),h.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),h.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),h.CHECKDATE),1,4)
	, CMRef=h.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=PRFI.FUTALiab
	, Amount=sum(h.FUTABURDEN)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource='PR_DedLiabTable'
	, udConv='Y',udCGCTable='PRTTCH',udCGCTableID=max(PRTTCHID)
from CV_CMS_SOURCE.dbo.PRTTCH h
	join bPRFI PRFI on PRFI.PRCo=@toco 
	join bPRDL PRDL on PRFI.PRCo=PRDL.PRCo and PRFI.FUTALiab=PRDL.DLCode
where h.COMPANYNUMBER=@fromco
group by h.COMPANYNUMBER, h.EMPLOYEENUMBER, h.WkEndDate, h.CHECKDATE, h.CHECKNUMBER, PRDL.DLType,
	PRFI.FUTALiab, h.PaySeq;

select @rowcount=@rowcount+@@rowcount;

--Other Deductions
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, d.EMPLOYEENUMBER
	, d.WkEndDate
	, PaySeq=d.PaySeq
	, PaidDate=substring(convert(nvarchar(max),d.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),d.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),d.CHECKDATE),1,4)
	, CMRef=d.CHECKNUMBER
	, x.VPType
	, x.DLCode
	, sum(d.DEDUCTIONAMT)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTMED',udCGCTableID=max(PRTMEDID)
from CV_CMS_SOURCE.dbo.PRTMED d with (nolock)
	join Viewpoint.dbo.budxrefPRDedLiab x on x.Company=@fromco and 
		convert(varchar(10),d.DEDNUMBER)=x.CMSDedCode and x.CMSDedType='M'
	join bPRDL PRDL on PRDL.PRCo=@toco and PRDL.DLType=x.VPType and PRDL.DLCode=x.DLCode
where d.COMPANYNUMBER=@fromco
group by d.COMPANYNUMBER, d.EMPLOYEENUMBER, d.WkEndDate, d.CHECKDATE, d.CHECKNUMBER, 
	x.VPType, x.DLCode, d.PaySeq;

select @rowcount=@rowcount+@@rowcount;

--Fica - SS, Employee
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, s.EMPLOYEENUMBER
	, s.WkEndDate 
	, PaySeq=s.PaySeq
	, PaidDate=substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
	, CMRef=s.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=PRFI.MiscFedDL1
	, Amount=sum(s.FICATAXSS)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTHST',udCGCTableID=max(PRTHSTID)
from CV_CMS_SOURCE.dbo.PRTHST s
	join bPRFI PRFI on PRFI.PRCo=@toco 
	join bPRDL PRDL on PRFI.PRCo=PRDL.PRCo and PRFI.MiscFedDL1=PRDL.DLCode
where s.COMPANYNUMBER=@fromco
group by s.COMPANYNUMBER, s.EMPLOYEENUMBER, s.WkEndDate, s.CHECKDATE, s.CHECKNUMBER,
	PRDL.DLType, PRFI.MiscFedDL1, s.PaySeq;

select @rowcount=@rowcount+@@rowcount;


--Fica - SS, Employer
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, s.EMPLOYEENUMBER
	, s.WkEndDate 
	, PaySeq=s.PaySeq
	, PaidDate=substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
	, CMRef=s.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=PRFI.MiscFedDL3
	, Amount=sum(h.FICABURDENSS)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTHST',udCGCTableID=max(PRTHSTID)
from CV_CMS_SOURCE.dbo.PRTHST s
	join bPRFI PRFI on PRFI.PRCo=@toco 
	join bPRDL PRDL on PRFI.PRCo=PRDL.PRCo and PRFI.MiscFedDL3=PRDL.DLCode
		join CV_CMS_SOURCE.dbo.PRTTCH h on s.COMPANYNUMBER=h.COMPANYNUMBER and s.EMPLOYEENUMBER=h.EMPLOYEENUMBER and
	s.WEEKENDDATE=h.WEEKENDDATE and s.CHECKDATE=h.CHECKDATE and s.CHECKNUMBER=h.CHECKNUMBER and s.PaySeq=h.PaySeq
where s.COMPANYNUMBER=@fromco
group by s.COMPANYNUMBER, s.EMPLOYEENUMBER, s.WkEndDate, s.CHECKDATE, s.CHECKNUMBER,
	PRDL.DLType, PRFI.MiscFedDL3, s.PaySeq;

select @rowcount=@rowcount+@@rowcount;


--Fica - Med, Employee
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, s.EMPLOYEENUMBER
	, s.WkEndDate 
	, PaySeq=s.PaySeq
	, PaidDate=substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
	, CMRef=s.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=PRFI.MiscFedDL2
	, Amount=sum(s.FICATAXMC)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTHST',udCGCTableID=max(PRTHSTID)
from CV_CMS_SOURCE.dbo.PRTHST s
	join bPRFI PRFI on PRFI.PRCo=@toco 
	join bPRDL PRDL on PRFI.PRCo=PRDL.PRCo and PRFI.MiscFedDL2=PRDL.DLCode
where s.COMPANYNUMBER=@fromco
group by s.COMPANYNUMBER, s.EMPLOYEENUMBER, s.WkEndDate, s.CHECKDATE, s.CHECKNUMBER,
	PRDL.DLType, PRFI.MiscFedDL2, s.PaySeq;

select @rowcount=@rowcount+@@rowcount;



--Fica - Med, Employer
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, s.EMPLOYEENUMBER
	, s.WkEndDate 
	, PaySeq=s.PaySeq
	, PaidDate=substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
	, CMRef=s.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=PRFI.MiscFedDL4
	, Amount=sum(s.FICATAXMC)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTHST',udCGCTableID=max(PRTHSTID)
from CV_CMS_SOURCE.dbo.PRTHST s
	join bPRFI PRFI on PRFI.PRCo=@toco 
	join bPRDL PRDL on PRFI.PRCo=PRDL.PRCo and PRFI.MiscFedDL4=PRDL.DLCode
where s.COMPANYNUMBER=@fromco
group by s.COMPANYNUMBER, s.EMPLOYEENUMBER, s.WkEndDate, s.CHECKDATE, s.CHECKNUMBER,
	PRDL.DLType, PRFI.MiscFedDL4, s.PaySeq;

select @rowcount=@rowcount+@@rowcount;


--State Taxes
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, StateYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
, e.EMPLOYEENUMBER
, e.WkEndDate
, e.PaySeq
, PaidDate = substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
, e.CHECKNUMBER
, i.VPType
, EDLCode = convert(smallint,i.DLCode)
, sum(e.AMOUNT01)
, LimitYN=max(case when l.LimitBasis='N' then 'N' else 'Y' end)
, StateYN='Y'
, udSource ='PR_DedLiabTable'
, udConv='Y'
,udCGCTable='PRTTCE',udCGCTableID=max(PRTTCEID)
from CV_CMS_SOURCE.dbo.PRTTCE e
	join CV_CMS_SOURCE.dbo.PRTHST s on e.COMPANYNUMBER=s.COMPANYNUMBER and e.EMPLOYEENUMBER=s.EMPLOYEENUMBER
		and e.WkEndDate=s.WkEndDate and e.CHECKNUMBER=s.CHECKNUMBER and e.PaySeq=s.PaySeq
		join  Viewpoint.dbo.budxrefPRDedLiab i on e.COMPANYNUMBER=i.Company and convert(varchar(3),e.DISTNUMBER)=i.CMSDedCode
	join bPRDL l on l.PRCo=i.Company and l.DLCode=i.DLCode
where e.COMPANYNUMBER=@fromco and i.VPType='D' and i.CMSDedType='S'
group by e.COMPANYNUMBER, e.EMPLOYEENUMBER, e.WkEndDate, s.CHECKDATE, e.CHECKNUMBER,
	i.VPType, e.PaySeq, e.DISTNUMBER, i.DLCode;
--  OLD CODE...delete if not needed..
/*select Company=@toco
	, s.EMPLOYEENUMBER
	, s.WkEndDate 
	, PaySeq=s.PaySeq
	, PaidDate=substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
	, CMRef=s.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=isnull(PRSI.TaxDedn, @defaultstatecode)
	, Amount=sum(s.USTTX)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, StateYN='Y'
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
from CV_CMS_SOURCE.dbo.PRTHST s
	join bPREH PREH on PREH.PRCo=@toco and s.EMPLOYEENUMBER=PREH.Employee
	left join bPRSI PRSI on PREH.PRCo=PRSI.PRCo and PREH.TaxState=PRSI.State
	join bPRDL PRDL on PREH.PRCo=PRDL.PRCo and isnull(PRSI.TaxDedn,@defaultstatecode)=PRDL.DLCode
where s.COMPANYNUMBER=@fromco
	and s.USTTX<>0
group by s.COMPANYNUMBER, s.EMPLOYEENUMBER, s.WkEndDate, s.CHECKDATE, s.CHECKNUMBER,
	PRDL.DLType, PRSI.TaxDedn, s.PaySeq;*/

select @rowcount=@rowcount+@@rowcount;


--SUTA
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, StateYN, udSource,udConv
		,udCGCTable,udCGCTableID)
select Company=@toco
	, s.EMPLOYEENUMBER
	, s.WkEndDate 
	, PaySeq=s.PaySeq
	, PaidDate=substring(convert(nvarchar(max),s.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),s.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),s.CHECKDATE),1,4)
	, CMRef=s.CHECKNUMBER
	, EDLType=PRDL.DLType
	, EDLCode=PRSI.SUTALiab
	, Amount=sum(CHSUBU)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, StateYN='Y'
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTTCH',udCGCTableID=max(PRTTCHID)
from CV_CMS_SOURCE.dbo.PRTTCH s
	--Join to get the right unemployment state based on CMS State id
	--
	left join (select StateCode, TaxState=max(Abbr) 
				from CV_CMS_SOURCE.dbo.TaxLimits
				group by StateCode)
				as u 
				on u.StateCode=convert(varchar(max),s.HOMESTATECODE) /*Unsure if this is changes per Customer  ?  s.STIDCODE*/
	join bPREH PREH on PREH.PRCo=@toco and s.EMPLOYEENUMBER=PREH.Employee
	join bPRSI PRSI on PRSI.PRCo=@toco and isnull(u.TaxState,PREH.TaxState)=PRSI.State
	join bPRDL PRDL on PRSI.PRCo=PRDL.PRCo and PRSI.SUTALiab=PRDL.DLCode
--	join (select COMPANYNUMBER, EMPLOYEENUMBER, WkEndDate, CHECKNUMBER,
--				CHECKDATE=max(CHECKDATE)
--			from CV_CMS_SOURCE.dbo.PRTHST
--			where COMPANYNUMBER=@fromco
--			group by COMPANYNUMBER, EMPLOYEENUMBER, WkEndDate, CHECKNUMBER)
--			as d
--			on d.COMPANYNUMBER=s.COMPANYNUMBER and d.EMPLOYEENUMBER=s.EMPLOYEENUMBER
--				and d.WkEndDate=s.WkEndDate and d.CHECKNUMBER=s.CHECKNUMBER
where s.COMPANYNUMBER=@fromco
	--don't restrict to records are not zero since that causes problems with the subj amounts later
group by s.COMPANYNUMBER, s.EMPLOYEENUMBER, s.WkEndDate, s.CHECKDATE, s.CHECKNUMBER,
	PRDL.DLType, PRSI.SUTALiab, s.PaySeq;


select @rowcount=@rowcount+@@rowcount;


--Local Taxes 
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv
		,udCGCTable,udCGCTableID)
select Company=@toco
	, t.EMPLOYEENUMBER
	, t.WkEndDate
	, PaySeq=t.PaySeq
	, PaidDate=substring(convert(nvarchar(max),d.CheckDate),5,2) 
			+ '/' + substring(convert(nvarchar(max),d.CheckDate),7,2) + '/' 
			+ substring(convert(nvarchar(max),d.CheckDate),1,4)
	, CMRef=t.CHECKNUMBER
	, x.VPType
	, x.DLCode
	, Amount=sum(t.AMOUNT01)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTTCE',udCGCTableID=max(PRTTCEID)
from CV_CMS_SOURCE.dbo.PRTTCE t with(nolock)
	join Viewpoint.dbo.budxrefPRDedLiab x on x.Company=@fromco and t.RECORDCODE=x.CMSDedType 
		and convert(varchar(10),t.DISTNUMBER)=x.CMSDedCode and x.CMSDedType='L'
	left join (select COMPANYNUMBER, EMPLOYEENUMBER, CHECKNUMBER, WkEndDate, CheckDate=max(CHECKDATE)
			from CV_CMS_SOURCE.dbo.PRTHST
			where COMPANYNUMBER=@fromco
			group by COMPANYNUMBER, EMPLOYEENUMBER, CHECKNUMBER, WkEndDate)
			as d
			on d.COMPANYNUMBER=t.COMPANYNUMBER and d.EMPLOYEENUMBER=t.EMPLOYEENUMBER
				and d.CHECKNUMBER=t.CHECKNUMBER and d.WkEndDate=t.WkEndDate
	left join bPRDL PRDL on PRDL.PRCo=@toco and x.VPType=PRDL.DLType and x.DLCode=PRDL.DLCode
where t.COMPANYNUMBER=@fromco
	and t.Mth is not null 
Group by t.COMPANYNUMBER, t.EMPLOYEENUMBER, t.WkEndDate, d.CheckDate, t.CHECKNUMBER,
	x.VPType, x.DLCode, t.PaySeq;

select @rowcount=@rowcount+@@rowcount;


--Union Deductions and Liabilities
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, m.EMPLOYEENUMBER
	, m.WkEndDate
	, PaySeq=m.PaySeq
	, PaidDate=isnull(substring(convert(nvarchar(max),m.CHECKDATE),5,2) 
						+ '/' + substring(convert(nvarchar(max),m.CHECKDATE),7,2) + '/' 
						+ substring(convert(nvarchar(max), m.CHECKDATE),1,4),d.CheckDate)
	, CMRef=m.CHECKNUMBER
	, x.VPType
	, x.DLCode
	, Amount=sum(m.NUDEA)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTMUN',udCGCTableID=max(PRTMUNID)
from CV_CMS_SOURCE.dbo.PRTMUN m with (nolock)
	join Viewpoint.dbo.budxrefPRDedLiab x on x.Company=@fromco
		and convert(varchar(10),m.NUDTY)=x.CMSDedCode and x.CMSDedType='U' 
		and m.UNIONNO=isnull(x.CMSUnion,m.UNIONNO)
	left join (select COMPANYNUMBER, EMPLOYEENUMBER, CHECKNUMBER, WkEndDate, 
				CheckDate=max(substring(convert(nvarchar(max),CHECKDATE),5,2) 
						+ '/' + substring(convert(nvarchar(max),CHECKDATE),7,2) + '/' 
						+ substring(convert(nvarchar(max),CHECKDATE),1,4))
			from CV_CMS_SOURCE.dbo.PRTHST
			where COMPANYNUMBER=@fromco
			group by COMPANYNUMBER, EMPLOYEENUMBER, CHECKNUMBER, WkEndDate)
			as d
			on d.COMPANYNUMBER=m.COMPANYNUMBER and d.EMPLOYEENUMBER=m.EMPLOYEENUMBER
				and d.CHECKNUMBER=m.CHECKNUMBER and d.WkEndDate=m.WkEndDate
	join bPRDL PRDL on PRDL.PRCo=@toco and x.VPType=PRDL.DLType and x.DLCode=PRDL.DLCode
	join bPREH PREH on PREH.PRCo=@toco and m.EMPLOYEENUMBER=PREH.Employee
where m.COMPANYNUMBER=@fromco
	and UNIONNO<> @exclCraft
Group by m.COMPANYNUMBER, m.EMPLOYEENUMBER, m.WkEndDate, m.CHECKDATE, d.CheckDate
	, m.CHECKNUMBER, x.VPType, x.DLCode, m.PaySeq;

select @rowcount=@rowcount+@@rowcount;

--Worker's Comp
insert into CV_CMS_SOURCE.dbo.DedLiabByEmp  (Company, Employee, PREndDate, PaySeq,
		PaidDate, CMRef, EDLType, EDLCode, Amount, LimitYN, udSource,udConv,udCGCTable,udCGCTableID)
select Company=@toco
	, h.EMPLOYEENUMBER
	, h.WkEndDate
	, PaySeq=h.PaySeq
	, PaidDate=substring(convert(nvarchar(max),h.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),h.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),h.CHECKDATE),1,4)
	, CMRef=h.CHECKNUMBER
	, PRDL.DLType
	, PRDL.DLCode
	, Amount=sum(h.CHWCBU)
	, LimitYN=max(case when PRDL.LimitBasis='N' then 'N' else 'Y' end)
	, udSource ='PR_DedLiabTable'
	, udConv='Y'
	,udCGCTable='PRTTCH',udCGCTableID=max(PRTTCHID)
from CV_CMS_SOURCE.dbo.PRTTCH h with(nolock)
	--Join to get the right unemployment state based on CMS State id
	left join (select StateCode, TaxState=max(Abbr) 
				from CV_CMS_SOURCE.dbo.TaxLimits
				group by StateCode)
				as u 
				on u.StateCode=convert(varchar(max),h.STIDCODE)
	join bPREH e on e.PRCo=@toco and h.EMPLOYEENUMBER=e.Employee
	join (select PRCo, State, DLCode=max(DLCode)
			from bPRID 
			group by PRCo, State)
			as PRID
			on PRID.PRCo=e.PRCo and isnull(u.TaxState,e.TaxState)=PRID.State
	join bPRDL PRDL on e.PRCo=PRDL.PRCo and PRID.DLCode=PRDL.DLCode
where h.COMPANYNUMBER=@fromco
	and h.CHWCBU <> 0
Group by h.COMPANYNUMBER, h.EMPLOYEENUMBER, h.WkEndDate, 
	h.CHECKNUMBER, h.CHECKDATE, PRDL.DLType, PRDL.DLCode, h.PaySeq;


select @rowcount=@rowcount+@@rowcount;




COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;



return @@error

GO
