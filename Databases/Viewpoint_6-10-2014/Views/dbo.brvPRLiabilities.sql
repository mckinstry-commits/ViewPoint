SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[brvPRLiabilities]
   

/*==================================================================================      

Author:   
JH 

Create date:   
05/03/2005   

Usage:
View used by PRDeptRecon.rpt. Calculates liabilities posting to JC, EM and Intercompany 
before the ledger update is run. 

Things to keep in mind regarding this report and proc: 
Uses the vf_rptPRUpdateGetFixedRate function to get JC rate information

Related reports:   
PR Department Reconciliation (ID: 942)     

Revision History      
Date		Author			Issue						Description
08/15/08	CWirtz			CL-126777	/	V1-NA		Added code to each JC where 
	clause so libiabilities are only included 
	when JCTemplateRateTable.JCTemplateRate = 0.  The common table expression JCTemplateRateTable 
	calculates the JC fix template rate for each timecard.  The template rate is set to zero when 
	a template is not being used or no matching rate detail is found.
07/17/2012	ScottAlvey		V1-D-05364					In modifying how PRTH.GLCo is populated from SM work order
	labor records it was discovered that the last select statement (Liabilities associated with 
	intercompany earnings) was comparing GLCo values incorrectly. It originaly was comparing
	'where h.GLCo<>h.GLCo and h.Job is null' and it should really be comparing the GLCo value of 
	the PR company setup. I modified the where statement to reflect this.
08/09/2012	Scott Alvey		CL-?????	/	V1-B-10483	Add SM PR record
==================================================================================*/  
     
     as
with JCTemplateRateTable AS
(SELECT    
	h.PRCo ,h.PRGroup, h.PREndDate, h.Employee , h.PaySeq, h.PostSeq, h.PostDate
	,h.JCCo , j.RateTemplate , h.Craft, h.Class, h.Shift, p.Factor
	,JCTemplateRate = dbo.vf_rptPRUpdateGetFixedRate
		(h.PostDate, h.JCCo , j.RateTemplate , h.PRCo ,h.Craft, h.Class, h.Shift, p.Factor,h.Employee )
FROM PRTH h (Nolock)
   join PREH e (Nolock) ON h.PRCo=e.PRCo and h.Employee=e.Employee
left outer join JCJM j (Nolock)
ON h.JCCo = j.JCCo and h.Job = j.Job 
left outer join PREC p (Nolock)
ON h.EarnCode = p.EarnCode and h.PRCo = p.PRCo
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

--PR Calculated Liabilities before looking at JC/EM/IC
   select Dept=('1'+'PR' + h.PRDept), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, 
   h.JCDept, d.LiabType, LiabTemplate=NULL, h.EMCo, h.Equipment, h.GLCo, h.Hours, EarnAmt=h.Amt, CalcMethod=NULL, LiabilityRate=NULL, 
   JCTEEarnCode=NULL, ActLiab=sum(l.Amt), LiabAmount=NULL, h.Phase, EMDept=NULL 
   from PRTL l 
   join PRTH h on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq --bring in job employee, earn code, earnings and job info
   join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode 
   join PREH p on p.PRCo=h.PRCo and p.Employee=h.Employee 
   group by h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, 
   d.LiabType, h.Hours, h.Amt, h.EMCo, h.Equipment, h.GLCo, h.Phase
   
   UNION ALL
   
   --Liabilities posting to JC at exact rate in JC Liability Template
   select Dept=('2'+'JC'+ convert(varchar(3), h.JCCo) + h.JCDept), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, 
   h.JCDept, d.LiabType, j.LiabTemplate, h.EMCo, h.Equipment, h.GLCo, h.Hours, EarnAmt=h.Amt, t.CalcMethod, t.LiabilityRate, 
   JCTEEarnCode=NULL, ActLiab=NULL, LiabAmount=sum(l.Amt), h.Phase, EMDept=NULL
   from PRTL l 
   join PRTH h on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq --bring in job employee, earn code, earnings and job info
   left outer join JCJM j on h.JCCo=j.JCCo and h.Job=j.Job 
   join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode 
   left outer join JCTL t on h.JCCo=t.JCCo and j.LiabTemplate=t.LiabTemplate and d.LiabType=t.LiabType 
   join PREH p on p.PRCo=h.PRCo and p.Employee=h.Employee 
   join JCTemplateRateTable r (Nolock)
		ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
			h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
   where p.JCFixedRate=0 and r.JCTemplateRate=0 and h.Type='J' and t.CalcMethod='E'
   group by h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, 
   d.LiabType, h.Hours, h.Amt, j.LiabTemplate, h.EMCo, h.Equipment, h.GLCo, 
   t.CalcMethod, t.LiabilityRate, h.Phase
   
   UNION ALL
   
   --Calculated liabilities on Regular earnings using rate in JC Liability Template
   select Dept=('2'+'JC'+ convert(varchar(3), h.JCCo) + h.JCDept), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, 
   h.JCDept, t.LiabType, j.LiabTemplate,h.EMCo, h.Equipment, h.GLCo, h.Hours, h.Amt, t.CalcMethod, t.LiabilityRate, 
   e.EarnCode, ActLiab=NULL, LiabAmount=(t.LiabilityRate * h.Amt), h.Phase, EMDept=NULL
   from PRTH h
   join JCJM j on h.JCCo=j.JCCo and h.Job=j.Job
   join JCTL t on h.JCCo=t.JCCo and j.LiabTemplate=t.LiabTemplate
   join JCTE e on e.JCCo=t.JCCo and e.LiabTemplate=t.LiabTemplate and e.LiabType=t.LiabType and h.EarnCode=e.EarnCode
   join PREH p on h.PRCo=p.PRCo and h.Employee=p.Employee
   join JCTemplateRateTable r (Nolock)
		ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
			h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
   where CalcMethod='R' and p.JCFixedRate=0 and r.JCTemplateRate=0 and h.Type='J'
   
   UNION ALL
   
   --Calculated liabilities on Add-on Earnings using rate in JC Liability Template 
   select Dept=('2'+'JC'+ convert(varchar(3), h.JCCo) + h.JCDept), EarnLiab='L', a.PRCo, a.PRGroup, a.PREndDate, h.PRDept, a.Employee, a.PaySeq, a.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, 
   h.JCDept, t.LiabType, j.LiabTemplate,h.EMCo, h.Equipment, h.GLCo, h.Hours, h.Amt, t.CalcMethod, t.LiabilityRate, 
   e.EarnCode, ActLiab=NULL, LiabAmount=(t.LiabilityRate * a.Amt), h.Phase, EMDept=NULL
   from PRTA a
   join PRTH h on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
   join JCJM j on h.JCCo=j.JCCo and h.Job=j.Job
   join JCTL t on h.JCCo=t.JCCo and j.LiabTemplate=t.LiabTemplate
   join JCTE e on e.JCCo=t.JCCo and e.LiabTemplate=t.LiabTemplate and e.LiabType=t.LiabType and a.EarnCode=e.EarnCode
   join PREH p on h.PRCo=p.PRCo and h.Employee=p.Employee
   join JCTemplateRateTable r (Nolock)
		ON h.PRCo = r.PRCo and h.PRGroup = r.PRGroup and h.PREndDate = r.PREndDate and 
			h.Employee = r.Employee and h.PaySeq = r.PaySeq and h.PostSeq = r.PostSeq
   where CalcMethod='R' and p.JCFixedRate=0 and r.JCTemplateRate=0 and h.Type='J'
   
   UNION ALL
   
   --Calculated Liabilities posting to EM using actual and addon rates
   select Dept=('3'+'EM'+ convert(varchar(3), h.EMCo) + m.Department), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, d.LiabType, NULL, 
   h.EMCo, h.Equipment, h.GLCo, h.Hours, h.Amt, t.BurdenType, t.BurdenRate, t.AddonRate, ActLiab=NULL, 
   LiabAmount=sum(l.Amt), h.Phase, EMDept=NULL
    from PRTL l 
   join PRTH h on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and h.Employee=l.Employee and h.PaySeq=l.PaySeq 
   and h.PostSeq=l.PostSeq 
   join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode --get liab type
   left outer join EMPB t on h.EMCo=t.EMCo and d.LiabType=t.LiabType --bring in rate/exact
   join PREH p on p.PRCo=h.PRCo and p.Employee=h.Employee --check for fixed rate
   join EMEM m on h.EMCo=m.EMCo and h.Equipment=m.Equipment
   where t.BurdenType='A' and p.EMFixedRate=0 and h.Type='M' 
   group by h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, 
    h.EMCo, h.Equipment, h.GLCo, d.LiabType, h.Hours, h.Amt, t.BurdenType, t.BurdenRate, t.AddonRate, h.Phase, m.Department
   
   UNION ALL
   
   --Calculated liabilities on Earnings using add-on rate in EM company parameters - LT is not in PRTL
   select Dept=('3'+'EM'+ convert(varchar(3), h.EMCo) + m.Department), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, 
   h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, b.LiabType, NULL,
   h.EMCo, h.Equipment, h.GLCo, NULL, h.Amt, b.BurdenType, b.AddonRate, NULL, ActLiab=NULL,
   LiabAmount=(b.AddonRate * h.Amt), h.Phase, EMDept=NULL
   from PRTH h
   join EMPB b on h.EMCo=b.EMCo 
   join EMEM m on h.EMCo=m.EMCo and h.Equipment=m.Equipment
   join PREH p on h.PRCo=p.PRCo and h.Employee=p.Employee
   where b.BurdenType='A' and p.EMFixedRate=0 and h.Type='M' and b.AddonRate<>0  
   
   UNION ALL
   
   --Calculated liabilities on Regular earnings using rate in EM company parameters
   select Dept=('3'+'EM'+ convert(varchar(3), h.EMCo) + m.Department), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, 
   h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, b.LiabType, NULL,
   h.EMCo, h.Equipment, h.GLCo, h.Hours, h.Amt, b.BurdenType, b.BurdenRate, NULL, ActLiab=NULL, 
   LiabAmount=(b.BurdenRate * h.Amt), h.Phase, EMDept=NULL
   from PRTH h
   join EMPB b on h.EMCo=b.EMCo --and d.LiabType=t.LiabType 
   join EMEM m on h.EMCo=m.EMCo and h.Equipment=m.Equipment
   join PREH p on h.PRCo=p.PRCo and h.Employee=p.Employee
   where b.BurdenType='R' and p.EMFixedRate=0 and h.Type='M' 
   
   UNION ALL
   
   --Calculated liabilities on Add-on Earnings using rate in EM company parameters
   select Dept=('3'+'EM'+ convert(varchar(3), h.EMCo) + m.Department), EarnLiab='L', a.PRCo, a.PRGroup, a.PREndDate, h.PRDept, a.Employee, a.PaySeq, a.PostSeq, h.Type, a.EarnCode, h.JCCo, h.Job, h.JCDept, b.LiabType, NULL,
   h.EMCo, h.Equipment, h.GLCo, NULL, a.Amt, b.BurdenType, b.BurdenRate, NULL, ActLiab=NULL, 
   LiabAmount=(b.BurdenRate * a.Amt), h.Phase, EMDept=NULL
   from PRTA a
   join PRTH h on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
   join EMPB b on h.EMCo=b.EMCo 
   join EMEM m on h.EMCo=m.EMCo and h.Equipment=m.Equipment
   join PREH p on h.PRCo=p.PRCo and h.Employee=p.Employee
   where b.BurdenType='R' and p.EMFixedRate=0 and h.Type='M' 
   
   UNION ALL
   
   --Calculated liabilities on Add-on Earnings using add-on rate in EM company parameters
   select Dept=('3'+'EM'+ convert(varchar(3), h.EMCo) + m.Department), EarnLiab='L', a.PRCo, a.PRGroup, a.PREndDate, h.PRDept, a.Employee, a.PaySeq, a.PostSeq, h.Type, a.EarnCode, h.JCCo, h.Job, h.JCDept, b.LiabType, NULL,
   h.EMCo, h.Equipment, h.GLCo, NULL, a.Amt, b.BurdenType, b.AddonRate, NULL, ActLiab=NULL,
   LiabAmount=(b.AddonRate * a.Amt), h.Phase, EMDept=NULL
   from PRTA a
   join PRTH h on h.PRCo=a.PRCo and h.PRGroup=a.PRGroup and h.PREndDate=a.PREndDate and h.Employee=a.Employee and h.PaySeq=a.PaySeq and h.PostSeq=a.PostSeq
   join EMPB b on h.EMCo=b.EMCo 
   join EMEM m on h.EMCo=m.EMCo and h.Equipment=m.Equipment
   join PREH p on h.PRCo=p.PRCo and h.Employee=p.Employee
   where b.BurdenType='A' and p.EMFixedRate=0 and h.Type='M' and AddonRate<>0 
   
   UNION ALL
   
   --Liabilities associated with intercompany earnings
   select Dept=('4'+'IC'+ convert(varchar(3), h.GLCo)), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, d.LiabType, NULL, 
   h.EMCo, h.Equipment, h.GLCo, NULL, h.Amt, NULL, NULL, NULL, ActLiab=NULL, LiabAmount=sum(l.Amt), h.Phase, EMDept=NULL
    from PRTL l
   join PRTH h on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq 
   join PRCO c on c.PRCo = h.PRCo
   join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode 
   where c.GLCo<>h.GLCo and h.Job is null
   group by h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, 
    d.LiabType, h.EMCo, h.Equipment, h.GLCo, h.Amt, h.Phase

-- start V1-B-10483

	UNION ALL
	
	--SM Calculated Liabilities
   select Dept=('5'+'SM'+ convert(varchar(3), h.SMCo) + prsmd.Department), EarnLiab='L', h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, 
   h.JCDept, d.LiabType, LiabTemplate=NULL, h.EMCo, h.Equipment, h.GLCo, h.Hours, EarnAmt=h.Amt, CalcMethod=NULL, LiabilityRate=NULL, 
   JCTEEarnCode=NULL, ActLiab=null, LiabAmount=sum(l.Amt), h.Phase, EMDept=NULL 
   from PRTL l 
   join PRTH h on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq --bring in job employee, earn code, earnings and job info
   join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode 
   join PREH p on p.PRCo=h.PRCo and p.Employee=h.Employee
   join PRSMDepartment prsmd on h.SMCo = prsmd.SMCo and h.SMWorkOrder = prsmd.WorkOrder
   where h.Type = 'S' 
   group by h.PRCo, h.PRGroup, h.PREndDate, h.PRDept, h.Employee, h.PaySeq, h.PostSeq, h.Type, h.EarnCode, h.JCCo, h.Job, h.JCDept, h.SMCo, prsmd.Department, 
   d.LiabType, h.Hours, h.Amt, h.EMCo, h.Equipment, h.GLCo, h.Phase
   
-- end V1-B-10483
GO
GRANT SELECT ON  [dbo].[brvPRLiabilities] TO [public]
GRANT INSERT ON  [dbo].[brvPRLiabilities] TO [public]
GRANT DELETE ON  [dbo].[brvPRLiabilities] TO [public]
GRANT UPDATE ON  [dbo].[brvPRLiabilities] TO [public]
GRANT SELECT ON  [dbo].[brvPRLiabilities] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRLiabilities] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRLiabilities] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRLiabilities] TO [Viewpoint]
GO
