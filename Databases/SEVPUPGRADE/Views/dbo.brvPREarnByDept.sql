SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[brvPREarnByDept]
  
     
/*==================================================================================      

Author:   
JH 

Create date:   
05/05/2005   

Usage:
View used by PRDeptRecon.rpt. Calculates earnings posting to JC, EM and Intercompany 
before the ledger update is run. Includes add-on earnings from PRTA. 

Things to keep in mind regarding this report and proc: 
Uses the vf_rptPRUpdateGetFixedRate function to get JC rate information

Related reports:   
PR Department Reconciliation (ID: 942)     

Revision History      
Date		Author			Issue						Description
07/23/08	CWirtz			CL-126777	/	V1-NA		JCFixedYN and JCFixedAmt.  
	The common table expression JCTemplateRateTable calculates	the JC fix template rate 
	for each timecard.  The template rate is set to zero when a template is not being 
	used or no matching rate detail is found.
08/09/2012	Scott Alvey		CL-?????	/	V1-B-10483	Add SM PR record
==================================================================================*/  
     
as

with 

JCTemplateRateTable 

AS
(
	SELECT    
		h.PRCo 
		, h.PRGroup
		, h.PREndDate
		, h.Employee 
		, h.PaySeq
		, h.PostSeq
		, h.PostDate
		, h.JCCo 
		, j.RateTemplate 
		, h.Craft
		, h.Class
		, h.Shift
		, p.Factor
		,JCTemplateRate = dbo.vf_rptPRUpdateGetFixedRate
			(
				h.PostDate
				, h.JCCo 
				, j.RateTemplate 
				, h.PRCo 
				, h.Craft
				, h.Class
				, h.Shift
				, p.Factor
				, h.Employee 
			)
	FROM 
		PRTH h (Nolock)
	join 
		PREH e (Nolock) ON 
			h.PRCo=e.PRCo 
			and h.Employee=e.Employee
	left outer join 
		JCJM j (Nolock) ON 
			h.JCCo = j.JCCo 
			and h.Job = j.Job 
	left outer join 
		PREC p (Nolock) ON 
		h.EarnCode = p.EarnCode 
		and h.PRCo = p.PRCo
), 

PRSMDepartment

as

(
	select
		smwo.SMCo
		, smwo.WorkOrder
		, smd.Department
	from
		SMWorkOrder smwo
	join
		SMServiceCenter smsc on
			smwo.SMCo = smsc.SMCo
			and smwo.ServiceCenter = smsc.ServiceCenter
	join
		SMDepartment smd on
			smsc.SMCo = smd.SMCo
			and smsc.Department = smd.Department
)

--All timecard earnings to use for PR department 
select Dept=('1'+'PR' + h.PRDept), h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, SMDept=null, h.PRDept, h.EarnCode, h.Hours, h.Rate,
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=
(case when h.Type='J' and h.Phase is not null then 
Case when (r.JCTemplateRate = 0)Then (e.JCFixedRate * h.Hours)
Else(r.JCTemplateRate *h.Hours)
End
else 0 end),
EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), 
EMFixedAmt=(case when h.Type='M' then (e.EMFixedRate * h.Hours) else 0 end), h.Amt 
from PRTH h (Nolock)
join PREH e (Nolock) ON h.PRCo=e.PRCo and h.Employee=e.Employee
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq


UNION ALL

--All add-on earnings to use for PR department 
select Dept=('1'+'PR' + h.PRDept), a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.PaySeq, a.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, SMDept=null, h.PRDept, a.EarnCode, h.Hours, a.Rate, 
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=NULL, EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), EMFixedAmt=NULL, a.Amt 
from PRTA a (Nolock)
join PRTH h (Nolock) on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
join PREH e (Nolock) on h.PRCo=e.PRCo and h.Employee=e.Employee
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq

UNION ALL

--All JC earnings.  Amount will be fixed rate * hours unless fixed rate is zero then it's actual amount from PRTH.
select Dept=('2'+'JC'+ convert(varchar(3), h.JCCo) + h.JCDept), h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, h.PostSeq, h.Type, 
h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, SMDept=null, h.PRDept, h.EarnCode, h.Hours, h.Rate, 
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=NULL, EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), EMFixedAmt=NULL, 
Amt=(case when e.JCFixedRate<>0 then e.JCFixedRate * h.Hours else h.Amt end)
from PRTH h (Nolock)
join PREH e (Nolock) on h.PRCo=e.PRCo and h.Employee=e.Employee
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
where h.Phase is not null and h.Type='J' 


UNION ALL

--All JC add-on earnings.  If fixed rates are being used, add-on earnings are set to zero.
select Dept=('2'+'JC'+ convert(varchar(3), h.JCCo) + h.JCDept), a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.PaySeq, a.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, SMDept=null, h.PRDept, a.EarnCode, h.Hours, a.Rate, 
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=NULL, EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), EMFixedAmt=NULL,
Amt=(case when e.JCFixedRate<>0 then 0 else a.Amt end) 
from PRTA a (Nolock)
join PRTH h (Nolock) on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
join PREH e (Nolock) on h.PRCo=e.PRCo and h.Employee=e.Employee
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
where h.Phase is not null and h.Type='J' 


UNION ALL

--All EM earnings.  Amount will be fixed rate * hours unless fixed rate is zero then it's actual amount from PRTH.
select Dept=('3'+'EM'+ convert(varchar(3), h.EMCo) + m.Department), h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=m.Department, h.SMCo, SMDept=null, h.PRDept, h.EarnCode, h.Hours, h.Rate, 
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=NULL, EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), EMFixedAmt=NULL,
Amt=(case when e.EMFixedRate<>0 then e.EMFixedRate * h.Hours else h.Amt end)
from PRTH h (Nolock)
join PREH e (Nolock) on h.PRCo=e.PRCo and h.Employee=e.Employee
join EMEM m (Nolock) on h.EMCo=m.EMCo and h.Equipment=m.Equipment
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
where h.Type='M' 

UNION ALL

--All EM add-on earnings.  If fixed rates are being used, add-on earnings are set to zero.
select Dept=('3'+'EM'+ convert(varchar(3), h.EMCo) + m.Department), a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.PaySeq, a.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=m.Department, h.SMCo, SMDept=null, h.PRDept, a.EarnCode, h.Hours, a.Rate, 
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=NULL, EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), EMFixedAmt=NULL,
Amt=(case when e.EMFixedRate<>0 then 0 else a.Amt end) 
from PRTA a (Nolock)
join PRTH h (Nolock) on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
join PREH e (Nolock) on h.PRCo=e.PRCo and h.Employee=e.Employee
join EMEM m (Nolock) on h.EMCo=m.EMCo and h.Equipment=m.Equipment
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
where h.Type='M' 


UNION ALL

--All Intercompany regular earnings.  
select Dept=('4'+'IC'+ convert(varchar(3), h.GLCo)), h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, SMDept=null, h.PRDept, h.EarnCode, h.Hours, h.Rate, JCFixedYN=null,
JCFixedAmt=NULL, EMFixedYN=NULL, EMFixedAmt=NULL, h.Amt
from PRTH h
where h.Type='J' and h.GLCo<>h.PRCo and h.Phase is null 

UNION ALL

--All Intercompany add-on earnings.  
select Dept=('4'+'IC'+ convert(varchar(3), h.GLCo)), a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.PaySeq, a.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, SMDept=null, h.PRDept, a.EarnCode, h.Hours, a.Rate, JCFixedYN=NULL,
JCFixedAmt=NULL, EMFixedYN=NULL, EMFixedAmt=NULL, a.Amt
from PRTA a
join PRTH h on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
where h.Type='J' and h.GLCo<>h.PRCo and h.Phase is null

-- start V1-B-10483

UNION ALL

--All SM earnings. 
select Dept=('5'+'SM'+ convert(varchar(3), h.SMCo) + prsmd.Department), h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, h.PostSeq, h.Type, 
h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, prsmd.Department as SMDept, h.PRDept, h.EarnCode, h.Hours, h.Rate, 
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=NULL, EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), EMFixedAmt=NULL, 
Amt=(case when e.JCFixedRate<>0 then e.JCFixedRate * h.Hours else h.Amt end)
from PRTH h (Nolock)
join PREH e (Nolock) on h.PRCo=e.PRCo and h.Employee=e.Employee
join PRSMDepartment prsmd on h.SMCo = prsmd.SMCo and h.SMWorkOrder = prsmd.WorkOrder
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
where h.Phase is not null and h.Type='S' 


UNION ALL

--All SM add-on earnings.
select Dept=('5'+'SM'+ convert(varchar(3), h.SMCo) + prsmd.Department), a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.PaySeq, a.PostSeq, h.Type, h.JCCo, h.Job, h.PhaseGroup, h.Phase, 
h.JCDept, h.GLCo, h.EMCo, h.Equipment, EMDept=NULL, h.SMCo, prsmd.Department as SMDept, h.PRDept, a.EarnCode, h.Hours, a.Rate, 
JCFixedYN=(case when r.JCTemplateRate <> 0 then 'Y'
when e.JCFixedRate<>0 then 'Y' else 'N' end),
JCFixedAmt=NULL, EMFixedYN=(case when e.EMFixedRate<>0 then 'Y' else 'N' end), EMFixedAmt=NULL,
Amt=(case when e.JCFixedRate<>0 then 0 else a.Amt end) 
from PRTA a (Nolock)
join PRTH h (Nolock) on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
join PREH e (Nolock) on h.PRCo=e.PRCo and h.Employee=e.Employee
join PRSMDepartment prsmd on h.SMCo = prsmd.SMCo and h.SMWorkOrder = prsmd.WorkOrder
join JCTemplateRateTable r (Nolock)
ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
where h.Phase is not null and h.Type='S' 

-- end V1-B-10483
GO
GRANT SELECT ON  [dbo].[brvPREarnByDept] TO [public]
GRANT INSERT ON  [dbo].[brvPREarnByDept] TO [public]
GRANT DELETE ON  [dbo].[brvPREarnByDept] TO [public]
GRANT UPDATE ON  [dbo].[brvPREarnByDept] TO [public]
GO
