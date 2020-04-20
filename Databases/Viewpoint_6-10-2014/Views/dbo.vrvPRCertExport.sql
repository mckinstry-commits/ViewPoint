SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvPRCertExport]

/**************
 Created:  11/26/08 DH
 Modified:
 
 Usage:
 View Returning earnings, deductions, and liabilities for the PR Certified Export report.
 CheckDataSort used for sorting PRSQ data separately in order to create CheckString field and report Gross Earnings.
 
*************/
 
as
/* Select a list of distinct Employees and jobs for the report.  
    Only employees that have true earnings (regular or addons) or non-true earnings flagged to print on report */

With EmployeeJobs
(PRCo, PRGroup, PREndDate, JCCo, Job, Certified, CertDate, Employee, CraftClass, GrossEarn)

as

(select PRTH.PRCo, 
	   PRTH.PRGroup,
	   PRTH.PREndDate,
	   PRTH.JCCo,
	   PRTH.Job,
	   max(j.Certified),
	   max(j.CertDate),	
	   PRTH.Employee,
	   PRTH.Craft+' '+PRTH.Class,
       sum(isnull(PRTH.Amt,0))+sum(isnull(a.AddonAmt,0)) as GrossEarn
       From
   PRTH with(nolock)  
   Join PREC e with(nolock) on e.PRCo=PRTH.PRCo and e.EarnCode=PRTH.EarnCode
   Join JCJM j with(nolock) on j.JCCo=PRTH.JCCo and j.Job=PRTH.Job
   Left Join (Select PRTA.PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, AddonCert='Y', sum(Amt) as AddonAmt From PRTA
               Join PREC with(nolock) on PREC.PRCo=PRTA.PRCo and PREC.EarnCode=PRTA.EarnCode
               Where ((PREC.TrueEarns='Y' and PRTA.Amt<>0) or (PREC.TrueEarns='N' and PREC.CertRpt='Y' and PRTA.Amt>0))
				Group by PRTA.PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq) as a
        on a.PRCo=PRTH.PRCo and a.PRGroup=PRTH.PRGroup and a.PREndDate=PRTH.PREndDate and a.Employee=PRTH.Employee and a.PaySeq=PRTH.PaySeq and a.PostSeq=PRTH.PostSeq
  
   Where PRTH.Cert='Y' and ((e.TrueEarns='Y' and PRTH.Amt<>0) or (e.TrueEarns='N' and e.CertRpt='Y' and  PRTH.Amt>0) or a.AddonCert='Y')

Group by PRTH.PRCo,
		 PRTH.PRGroup,
		 PRTH.PREndDate,
		 PRTH.JCCo,
	     PRTH.Job,
	     PRTH.Employee,
		 PRTH.Craft,
		 PRTH.Class

) /*End Employee Jobs*/


/*Deductions and negative non-true earnings*/

select d.PRCo,
	   d.PRGroup,
	   d.PREndDate,
	   d.Employee,
	   d.PaySeq,
	   sq.CMRef,
	   e.CraftClass,
       e.JCCo,
	   e.Job,
	   e.Certified,
	   e.CertDate,
	   d.EDLCode as DedCode,
       Null as EarnCode,
       Null as LiabCode,
	   Null as Factor,
	   Null as EarnRate,
	   case when d.EDLType='D' then dl.DetOnCert
            when d.EDLType='E' then ec.CertRpt
       end as DetailOnCertYN,
	   d.PREndDate as PostDate, /*Set date to last day of week for deductions*/
	   0 as Hours,
	   Amount=(case when d.EDLType='D' and d.UseOver='N' then d.Amount 
                    when d.EDLType='E' and ec.TrueEarns='N' and d.Amount<0 then abs(d.Amount)
                    when d.UseOver='Y' then d.OverAmt end),
	   FedTax=(case when d.EDLType='D' and d.EDLCode=fi.TaxDedn then d.Amount end),
	   FICA=(case when d.EDLType='D' and d.EDLCode=fi.MiscFedDL1 then d.Amount end),
	   Med=(case when d.EDLType='D' and d.EDLCode=fi.MiscFedDL2 then d.Amount end),
	   StateTax=(case when d.EDLType='D' and d.EDLCode=si.TaxDedn then d.Amount end),
       case when ec.TrueEarns='Y' and d.EDLType='E' then d.Amount
            when ec.TrueEarns='N' and d.EDLType='E' and d.Amount>0 then d.Amount end as GrossEarnings,
	   ParamBegPREndDate=d.PREndDate, /*ParamBegPREndDate:  Used in report record selection so that deductions are restricted only by PREndDate*/
	   ParamEndPREndDate=d.PREndDate, /*ParamEndPREndDate:  Used in report record selection so that deductions are restricted only by PREndDate*/
	   ParamBegPostDate='12/31/2050', /*ParamBegPostDate:  Set to max date value so that Beg/End PostDate record selection ignores for deductions*/
	   ParamEndPostDate='1/1/1950', /*ParamBegPostDate:  Set to min date value so that Beg/End PostDate record selection ignores for deductions*/	
	   CodeType=1 /*Deductions*/
      
   From PRDT d with(nolock)
   Join EmployeeJobs e on e.PRCo=d.PRCo and e.PRGroup=d.PRGroup and e.PREndDate=d.PREndDate and e.Employee=d.Employee
   Left Outer Join PRFI fi with (nolock) on fi.PRCo=d.PRCo and d.EDLType='D'
   Left Outer Join (Select distinct PRCo, TaxDedn From PRSI with (nolock)) as si on si.PRCo=d.PRCo and si.TaxDedn=d.EDLCode and d.EDLType='D'
   Left Outer Join PRDL dl with(nolock) on dl.PRCo=d.PRCo and dl.DLCode=d.EDLCode and d.EDLType='D'
   Left Outer Join PREC ec with(nolock) on ec.PRCo=d.PRCo and ec.EarnCode=d.EDLCode and d.EDLType='E'
   Left Outer Join PRSQ sq with (nolock) on sq.PRCo=d.PRCo and sq.PRGroup=d.PRGroup and sq.PREndDate=d.PREndDate
											and sq.Employee=d.Employee and sq.PaySeq=d.PaySeq
   Where d.EDLType<>'L'
   --Where ((TrueEarns='N' and EDLType='E' and d.Amount<0) or EDLType='D')
   


union all


/*Regular Earnings*/

select  h.PRCo,
		h.PRGroup,
		h.PREndDate, /*PREndDate used in record selection only when IncludeHoursOnlyinPayPd parameter=Y*/
		h.Employee,
		h.PaySeq,
		Null as CMRef,
		h.Craft+' '+h.Class,
		h.JCCo,
		h.Job,
	    j.Certified,
        j.CertDate,
		Null as DedCode,
        h.EarnCode,
		Null as LiabCode,
		e.Factor,
		h.Rate as EarnRate,
		e.CertRpt as DetailCert,
		h.PostDate,
		h.Hours,
		h.Amt,
	    Null as FedTax,
	    Null as FICA,
		Null as Med,
		Null as StateTax,
		0 as GrossEarnings,
        ParamBegPREndDate='12/31/2050', /*ParamBegPREndDate:  Set to max value so that PREndDate record selection ignores for Earns and Liab codes*/
	    ParamEndPREndDate='1/1/1950', /*ParamEndPREndDate:  Set to min value so that PREndDate record selection ignores for Earns and Liab codes*/
	    ParamBegPostDate=h.PostDate, /*ParamBegPostDate:  Used in Beg/End PostDate record selection */
	    ParamEndPostDate=h.PostDate, /*ParamBegPostDate:  Used in Beg/End PostDate record selection */

		CodeType=2 /*Earnings*/
   From PRTH h
   Join PREC e on e.PRCo=h.PRCo and e.EarnCode=h.EarnCode
   Join JCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
   	Where h.Cert='Y' and 
  	((e.TrueEarns='Y' and h.Amt<>0) or (e.TrueEarns='N' and e.CertRpt='Y' and  h.Amt>0)) /*Exclude Neg non-true earnings*/

union all

/*Addon Earnings*/

select  h.PRCo,
		h.PRGroup,
		h.PREndDate,
		h.Employee,
		h.PaySeq,
		Null as CMRef,
		h.Craft+' '+h.Class,
	    h.JCCo,
		h.Job,
	    j.Certified,
        j.CertDate,
		Null as DedCode,
		a.EarnCode as EarnCode,
	    Null as LiabCode,
		Null as Factor,
		Null as EarnRate,
		e.CertRpt as DetailCert,
		h.PREndDate as PostDate,
		0 as Hours,
		a.Amt,
        Null as FedTax,
	    Null as FICA,
		Null as Med,
		Null as StateTax,
		0 as GrossEarnings,
		ParamBegPREndDate='12/31/2050', /*ParamBegPREndDate:  Set to max value so that PREndDate record selection ignores for Earns and Liab codes*/
	    ParamEndPREndDate='1/1/1950', /*ParamEndPREndDate:  Set to min value so that PREndDate record selection ignores for Earns and Liab codes*/
	    ParamBegPostDate=h.PostDate, /*ParamBegPostDate:  Used in Beg/End PostDate record selection */
	    ParamEndPostDate=h.PostDate, /*ParamBegPostDate:  Used in Beg/End PostDate record selection */
	    CodeType=2 /*Earnings*/
   From PRTH h
   Join JCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
   Join PRTA a on a.PRCo=h.PRCo and a.PRGroup=h.PRGroup and a.PREndDate=h.PREndDate and a.Employee=h.Employee and a.PaySeq=h.PaySeq and a.PostSeq=h.PostSeq
   Join PREC e on e.PRCo=a.PRCo and e.EarnCode=a.EarnCode
   	Where h.Cert='Y' and 
  	((e.TrueEarns='Y' and h.Amt<>0) or (e.TrueEarns='N' and e.CertRpt='Y' and a.Amt>0)) /*Exclude Neg non-true earnings*/

/*Group By h.PRCo,
        h.PRGroup,
		h.PREndDate,
		h.Employee,
	    h.PaySeq,
		h.Craft,
		h.Class,
	    h.JCCo,
		h.Job,
		a.EarnCode,
		e.CertRpt*/
		

union all


/*Liabilities*/

select  h.PRCo,
		h.PRGroup,
		h.PREndDate,
		h.Employee,
		h.PaySeq,
		Null as CMRef,
		h.Craft+' '+h.Class,
		h.JCCo,
		h.Job,
	    j.Certified,
        j.CertDate,
		Null as DedCode,
		Null as EarnCode,
	    l.LiabCode as LiabCode,
		Null as Factor,
		Null as EarnRate,
		d.DetOnCert as DetailCert,
		h.PREndDate as PostDate,
		0 as Hours,
		l.Amt,
	    Null as FedTax,
	    Null as FICA,
		Null as Med,
		Null as StateTax,
		0 as GrossEarnings,
	    ParamBegPREndDate='12/31/2050', /*ParamBegPREndDate:  Set to max value so that PREndDate record selection ignores for Earns and Liab codes*/
	    ParamEndPREndDate='1/1/1950', /*ParamEndPREndDate:  Set to min value so that PREndDate record selection ignores for Earns and Liab codes*/
	    ParamBegPostDate=h.PostDate, /*ParamBegPostDate:  Used in Beg/End PostDate record selection */
	    ParamEndPostDate=h.PostDate, /*ParamBegPostDate:  Used in Beg/End PostDate record selection */
	    CodeType=3 /*Liabilities*/
    From PRTH h
    Join JCJM j with (nolock) on j.JCCo=h.JCCo and j.Job=h.Job
    Join PRTL l on h.PRCo=l.PRCo and h.PRGroup=l.PRGroup and h.PREndDate=l.PREndDate and
    h.Employee=l.Employee and h.PaySeq=l.PaySeq and h.PostSeq=l.PostSeq
    Join PRDL d on d.PRCo=l.PRCo and d.DLCode=l.LiabCode
      	Where h.Cert='Y' 
    /*Group By h.PRCo,
		h.PRGroup,
		h.PREndDate,
		h.Employee,
		h.PaySeq,
		h.Craft,
		h.Class,
		h.JCCo,
		h.Job,
		l.LiabCode,
		d.DetOnCert*/

union all

select  s.PRCo,
		s.PRGroup,
		s.PREndDate,
		s.Employee,
		s.PaySeq,
		s.CMRef,
		e.CraftClass,
		e.JCCo,
		e.Job,
		e.Certified,
        e.CertDate,
		Null as DedCode,
		Null as EarnCode,
	    Null as LiabCode,
		Null as Factor,
		Null as EarnRate,
		Null as DetailCert,
		s.PREndDate as PostDate,
		0 as Hours,
	    0 as Amount,
	    Null as FedTax,
	    Null as FICA,
		Null as Med,
		Null as StateTax,
		Null as GrossEarnings,
	    ParamBegPREndDate=s.PREndDate, /*ParamBegPREndDate:  Used in report record selection so that deductions are restricted only by PREndDate*/
	    ParamEndPREndDate=s.PREndDate, /*ParamEndPREndDate:  Used in report record selection so that deductions are restricted only by PREndDate*/
	    ParamBegPostDate='12/31/2050', /*ParamBegPostDate:  Set to max date value so that Beg/End PostDate record selection ignores for deductions*/
	    ParamEndPostDate='1/1/1950', /*ParamBegPostDate:  Set to min date value so that Beg/End PostDate record selection ignores for deductions*/	
	    CodeType=4 /*Checks*/
From PRSQ s
Join EmployeeJobs e on e.PRCo=s.PRCo and e.PRGroup=s.PRGroup and e.PREndDate=s.PREndDate and e.Employee=s.Employee

GO
GRANT SELECT ON  [dbo].[vrvPRCertExport] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCertExport] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCertExport] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCertExport] TO [public]
GRANT SELECT ON  [dbo].[vrvPRCertExport] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRCertExport] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRCertExport] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRCertExport] TO [Viewpoint]
GO
