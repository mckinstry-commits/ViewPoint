
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_PRTH_Adj] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

/**
=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS
=========================================================================
	Title:			Timecard Adjustments (PRTH)
	Created:		06.01.09
	Created by:		CR
	Function:		Xref for Earnings/Deductions/Liabilities in CMS
	Revisions:		1. 6.19.09 - ADB - Ignoring following ADJTYPECODEs: UD, UB, BA
					2. 8.10.09 - CR - changed InsState and InsCode, 
						added nolocks,changed PostedDate to use WEEKENDDATE instead of JOURNALDATE.
					3. 8.19.10 - JH - Added TC source as ud field to PRTH 
					4. 10/04/13 BTC - Added JCJobs cross reference
**/

set @errmsg=''
set @rowcount=0


--Declare Variables for functions
Declare @JobFormat varchar(30)
Set @JobFormat=(Select InputMask from vDDDTc where Datatype='bJob')

--Get Customer Defaults
declare @defaultJCDept varchar(5), @defaultCraft varchar(10), @defaultClass varchar(10)

select @defaultJCDept=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='JCDept' and a.TableName='bPRTH';

select @defaultCraft=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Craft' and a.TableName='bPRTH';

select @defaultClass=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Class' and a.TableName='bPRTH';

--Get HQCO defaults
declare @PhaseGroup tinyint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco

-- Job formatting
declare @JobLen smallint, @SubJobLen smallint
select @JobLen = left(InputMask,1) from vDDDTc where Datatype = 'bJob';
select @SubJobLen = substring(InputMask,4,1) from vDDDTc where Datatype = 'bJob';

ALTER Table bPRTH disable trigger ALL;


-- delete existing trans
--no delete necessary, done in earlier SP

-- add new trans
BEGIN TRAN
BEGIN TRY

--OD ADJUSTMENTS 
insert bPRTH (PRCo, PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate
,JCCo, Job, PhaseGroup, Phase, JCDept,GLCo,TaxState,UnempState,InsState,PRDept
,Cert,Craft,Class,Shift,EarnCode,Hours,Rate,Amt, BatchId, InsCode,
	udPaidDate, udCMCo, udCMAcct, udCMRef, udTCSource, udSchool, udSource,udConv,udCGCTable,udCGCTableID)

select PRCo=@toco
	, PRGroup=e.PRGroup
	, PREndDate=PRTTCH.WkEndDate
	, Employee=EMPLOYEENUMBER
	, PaySeq=PRTTCH.PaySeq
	, PostSeq=isnull((select max(PostSeq) 
						from bPRTH b 
						where b.PREndDate=PRTTCH.WkEndDate and b.Employee=PRTTCH.EMPLOYEENUMBER),0) 
							+row_number() over(partition by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER 
									order by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER)
	, Type='J'
	, PostDate=substring(convert(nvarchar(max),WEEKENDDATE),5,2) + '/' + substring(convert(nvarchar(max),WEEKENDDATE),7,2) 
				+ '/' + substring(convert(nvarchar(max),WEEKENDDATE),1,4)
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
	, PRDept=e.PRDept
	, Cert=e.CertYN  
	, Craft=case when x.Class is not null and x.Craft is null then @defaultCraft else
				x.Craft end 
	, Class=case when x.Class is null and x.Craft is not null then @defaultClass else
				x.Class end 
	, Shift=e.Shift
	, EarnCode=prearn.EarnCode
	, Hours=0
	, Rate=0
	, Amt=ADJAMOUNT
	, BatchId=0
	, InsCode=right('0000'+convert(varchar,WCCODE),4)
	, udPaidDate=substring(convert(nvarchar(max),PRTTCH.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),PRTTCH.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),PRTTCH.CHECKDATE),1,4)
	, udCMCo=g.CMCo
	, udCMAcct=g.CMAcct
	, udCMRef = PRTTCH.CHECKNUMBER
	, udTCSource='ADJ1'
	, udSchoolDistrict = case when PRTTCH.CHLCD2=0 then NULL else PRTTCH.CHLCD2 end
	, udSource ='PRTH_Adj'
	, udConv='Y'
	,udCGCTable='PRTTCH',udCGCTableID=PRTTCHID
from CV_CMS_SOURCE.dbo.PRTTCH PRTTCH
	join Viewpoint.dbo.budxrefPREarn prearn  with (nolock) on prearn.Company=@fromco and convert(varchar(max),DEDNUMBER)=prearn.CMSDedCode
	join bPREH e with (nolock) on e.PRCo=@toco and EMPLOYEENUMBER=e.Employee
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
where PRTTCH.COMPANYNUMBER=@fromco
	and ADJAMOUNT<>0 
	and ADJTYPECODE='OD' 
	and prearn.CMSCode='M'
order by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate, PRTTCH.CHECKDATE;


select @rowcount=@@rowcount;

--HR ADJUSTMENTS 
insert bPRTH (PRCo, PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate
,JCCo, Job, PhaseGroup, Phase, JCDept,GLCo,TaxState,UnempState,InsState,PRDept
,Cert,Craft,Class,Shift,EarnCode,Hours,Rate,Amt, BatchId, InsCode,
	udPaidDate, udCMCo, udCMAcct, udCMRef, udTCSource, udSource,udConv,udCGCTable,udCGCTableID )

select PRCo=@toco
	, PRGroup=e.PRGroup
	, PREndDate=PRTTCH.WkEndDate
	, Employee=EMPLOYEENUMBER
	, PaySeq=PRTTCH.PaySeq
	, PostSeq=isnull((select max(PostSeq) 
								from PRTH b 
								where b.PREndDate=PRTTCH.WkEndDate and b.Employee=PRTTCH.EMPLOYEENUMBER),0) +
									row_number() over(partition by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER 
									order by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER)
	, Type='J'
	, PostDate=substring(convert(nvarchar(max),WEEKENDDATE),5,2) + '/' + substring(convert(nvarchar(max),WEEKENDDATE),7,2) + '/' + substring(convert(nvarchar(max),WEEKENDDATE),1,4)
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
	, TaxState= isnull(s.TaxState,e.TaxState)
	, UnempState=isnull(s.TaxState,e.UnempState)
	, InsState = isnull(s.TaxState,e.InsState)
	, PRDept=e.PRDept
	, Cert=e.CertYN 
	, Craft=case when x.Class is not null and x.Craft is null then @defaultCraft else
				x.Craft end 
	, Class=case when x.Class is null and x.Craft is not null then @defaultClass else
				x.Class end  
	, Shift=e.Shift
	, EarnCode=prearn.EarnCode
	, Hours=0
	, Rate=0
	, Amt=ADJAMOUNT
	, BatchId=0
	, InsCode=right('0000'+convert(varchar,WCCODE),4)
	, udPaidDate=substring(convert(nvarchar(max),PRTTCH.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),PRTTCH.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),PRTTCH.CHECKDATE),1,4)
	, udCMCo=g.CMCo
	, udCMAcct=g.CMAcct
	, udCMRef=PRTTCH.CHECKNUMBER
	, udTCSource='ADJ2'
	, udSource ='PRTH_Adj'
	, udConv='Y'
	,udCGCTable='PRTTCH',udCGCTableID=PRTTCHID
from CV_CMS_SOURCE.dbo.PRTTCH PRTTCH 
	join Viewpoint.dbo.budxrefPREarn prearn on prearn.Company=@fromco and convert(varchar(max),DEDNUMBER)=prearn.CMSDedCode
	join bPREH e with(nolock) on e.PRCo=@toco and EMPLOYEENUMBER=e.Employee
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
where PRTTCH.COMPANYNUMBER=@fromco
		and ADJAMOUNT<>0 
		and ADJTYPECODE='HR' 
		and prearn.CMSCode='H'
order by PRTTCH.COMPANYNUMBER, EMPLOYEENUMBER, PRTTCH.WkEndDate;


select @rowcount=@rowcount+@@rowcount;


--SP ADJUSTMENTS 
insert bPRTH (PRCo, PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate
,JCCo, Job, PhaseGroup, Phase, JCDept,GLCo,TaxState,UnempState,InsState,PRDept
,Cert,Craft,Class,Shift,EarnCode,Hours,Rate,Amt, BatchId, InsCode,
	udPaidDate, udCMCo, udCMAcct, udCMRef, udTCSource, udSource,udConv ,udCGCTable,udCGCTableID)

select PRCo=@toco
	, PRGroup=e.PRGroup
	, PREndDate=PRTTCH.WkEndDate
	, Employee=EMPLOYEENUMBER
	, PaySeq=PRTTCH.PaySeq
	, PostSeq=isnull((select max(PostSeq) 
									from PRTH b 
									where b.PREndDate=PRTTCH.WkEndDate and b.Employee=PRTTCH.EMPLOYEENUMBER),0) +
									row_number() over(partition by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER 
									order by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER)
	, Type='J'
	, PostDate=substring(convert(nvarchar(max),WEEKENDDATE),5,2) + '/' + substring(convert(nvarchar(max),WEEKENDDATE),7,2) + '/' 
						+ substring(convert(nvarchar(max),WEEKENDDATE),1,4)
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
	, PRDept=e.PRDept
	, Cert=e.CertYN 
	, Craft=case when x.Class is not null and x.Craft is null then @defaultCraft else
				x.Craft end 
	, Class=case when x.Class is null and x.Craft is not null then @defaultClass else
				x.Class end 
	, Shift=e.Shift
	, EarnCode=prearn.EarnCode
	, Hours=0
	, Rate=0
	, Amt=ADJAMOUNT
	, BatchId=0
	, InsCode=right('0000'+convert(varchar,WCCODE),4)
	, udPaidDate=substring(convert(nvarchar(max),PRTTCH.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),PRTTCH.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),PRTTCH.CHECKDATE),1,4)
	, udCMCo=g.CMCo
	, udCMAcct=g.CMAcct
	, udCMRef = PRTTCH.CHECKNUMBER
	, udTCSource='ADJ3'
	, udSource ='PRTH_Adj'
	, udConv='Y'
	,udCGCTable='PRTTCH',udCGCTableID=PRTTCHID
from CV_CMS_SOURCE.dbo.PRTTCH PRTTCH
	join Viewpoint.dbo.budxrefPREarn prearn  with (nolock) on prearn.Company=@fromco 
			and convert(varchar(max),DEDNUMBER)=prearn.CMSDedCode
	join PREH e with(nolock) on e.PRCo=@toco and EMPLOYEENUMBER=e.Employee
	left join bPRGR g on e.PRCo=g.PRCo and e.PRGroup=g.PRGroup
	left join Viewpoint.dbo.budxrefUnion x on x.Company=@fromco 
				and PRTTCH.UNIONNO=x.CMSUnion and PRTTCH.EMPLOYEECLASS=x.CMSClass 
				and PRTTCH.EMPLTYPE=x.CMSType
	left join Viewpoint.dbo.budxrefJCJobs xj
		on xj.COMPANYNUMBER = PRTTCH.COMPANYNUMBER and xj.DIVISIONNUMBER = PRTTCH.ADJAMOUNT and xj.JOBNUMBER = PRTTCH.JOBNUMBER
			and xj.SUBJOBNUMBER = PRTTCH.SUBJOBNUMBER
	left join Viewpoint.dbo.budxrefPhase p on p.Company=@fromco and PRTTCH.JCDISTRIBTUION=p.oldPhase
	left join (select StateCode, TaxState=max(Abbr) 
				from CV_CMS_SOURCE.dbo.TaxLimits
				group by StateCode)
				as s 
				on s.StateCode=convert(varchar(max),PRTTCH.STIDCODE)
where PRTTCH.COMPANYNUMBER=@fromco
	and ADJAMOUNT<>0 
	and ADJTYPECODE='SP' 
	and prearn.CMSCode='D'
order by PRTTCH.COMPANYNUMBER, EMPLOYEENUMBER, PRTTCH.WkEndDate;


select @rowcount=@rowcount+@@rowcount;

--SP ADJUSTMENTS 
insert bPRTH (PRCo, PRGroup,PREndDate,Employee,PaySeq,PostSeq,Type,PostDate
,JCCo, Job, PhaseGroup, Phase, JCDept,GLCo,TaxState,UnempState,InsState,PRDept
,Cert,Craft,Class,Shift,EarnCode,Hours,Rate,Amt, BatchId, InsCode,
	udPaidDate, udCMCo, udCMAcct, udCMRef, udTCSource, udSource,udConv,udCGCTable,udCGCTableID)

select PRCo=@toco
	, PRGroup=e.PRGroup
	, PREndDate=PRTTCH.WkEndDate
	, Employee=EMPLOYEENUMBER
	, PaySeq=PRTTCH.PaySeq
	, PostSeq=isnull((select max(PostSeq) 
									from PRTH b 
									where b.PREndDate=PRTTCH.WkEndDate and b.Employee=PRTTCH.EMPLOYEENUMBER),0) +
									row_number() over(partition by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER 
									order by PRTTCH.COMPANYNUMBER, PRTTCH.WkEndDate,EMPLOYEENUMBER)
	, Type='J'
	, PostDate=substring(convert(nvarchar(max),WEEKENDDATE),5,2) + '/' + substring(convert(nvarchar(max),WEEKENDDATE),7,2) + '/' 
						+ substring(convert(nvarchar(max),WEEKENDDATE),1,4)
	, JCCo=DISTCOMPANY+@toco-PRTTCH.COMPANYNUMBER
	, Job=case when PRTTCH.JOBNUMBER='' 
			then null 
			else 
				xj.VPJob
			--			dbo.bfMuliPartFormat(right(space(@JobLen) + ltrim(rtrim(PRTTCH.JOBNUMBER)),@JobLen) + 
			--				left(PRTTCH.SUBJOBNUMBER,@SubJobLen),@JobFormat)
			end
	, PhaseGroup=@PhaseGroup
	, Phase=p.newPhase
	, JCDept=@defaultJCDept
	, GLCo=@toco
	, TaxState = isnull(s.TaxState,e.TaxState)
	, UnempState=isnull(s.TaxState,e.UnempState)
	, InsState = isnull(s.TaxState,e.InsState)
	, PRDept=e.PRDept
	, Cert=e.CertYN 
	, Craft=case when x.Class is not null and x.Craft is null then @defaultCraft else
				x.Craft end 
	, Class=case when x.Class is null and x.Craft is not null then @defaultClass else
				x.Class end 
	, Shift=e.Shift
	/****** check the CheckTypes, they signify different Earn codes ADJTYPECODE's of 'TX'  example:
	case when CHECKTYPE='S' then 6 when CHECKTYPE='Q' then 28 when CHECKTYPE='B' then 29 else 
		prearn.EarnCode end
	*****/
	, EarnCode=prearn.EarnCode
	, Hours=0
	, Rate=0
	, Amt=ADJAMOUNT
	, BatchId=0
	, InsCode=right('0000'+convert(varchar,WCCODE),4)
	, udPaidDate=substring(convert(nvarchar(max),PRTTCH.CHECKDATE),5,2) 
			+ '/' + substring(convert(nvarchar(max),PRTTCH.CHECKDATE),7,2) + '/' 
			+ substring(convert(nvarchar(max),PRTTCH.CHECKDATE),1,4)
	, udCMCo=g.CMCo
	, udCMAcct=g.CMAcct
	, udCMRef = PRTTCH.CHECKNUMBER
	, udTCSource='ADJ4'
	, udSource ='PRTH_Adj'
	, udConv='Y'
	,udCGCTable='PRTTCH',udCGCTableID=PRTTCHID
from CV_CMS_SOURCE.dbo.PRTTCH PRTTCH
	join Viewpoint.dbo.budxrefPREarn prearn  with (nolock) on prearn.Company=@fromco 
			and convert(varchar(max),DEDNUMBER)=prearn.CMSDedCode
	join PREH e with(nolock) on e.PRCo=@toco and EMPLOYEENUMBER=e.Employee
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
where PRTTCH.COMPANYNUMBER=@fromco
	and ADJAMOUNT<>0 
	and ADJTYPECODE='TX' 
order by PRTTCH.COMPANYNUMBER, EMPLOYEENUMBER, PRTTCH.WkEndDate;

select @rowcount=@rowcount+@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPRTH enable trigger ALL;

return @@error




GO
