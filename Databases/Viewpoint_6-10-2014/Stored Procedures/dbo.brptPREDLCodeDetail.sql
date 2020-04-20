SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc dbo.brptPREDLCodeDetail (@PRCo tinyint, @PRGroup tinyint, @PREndDate smalldatetime)

as

create table #EDLCodes

(PRCo tinyint null,
 PRGroup tinyint null,
 PREndDate smalldatetime null,
 Employee int null,
 PaySeq tinyint null,
 EarnCode smallint null,
 DedCode smallint null,
 LiabCode smallint null,
 RecCount int null)

create table #EDLDetail
(PRCo tinyint null,
 PRGroup tinyint null,
 PREndDate smalldatetime null,
 Employee int null,
 PaySeq tinyint null,
 EarnCode smallint null,
 DedCode smallint null,
 LiabCode smallint null,
 RecCount int null)

insert into #EDLCodes
(PRCo, PRGroup, PREndDate, Employee, PaySeq, EarnCode, DedCode, LiabCode, RecCount)
select PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLCode, null, null,
  RecCount=(select count(*) From PRDT d Where d.PRCo=PRDT.PRCo and d.PRGroup=PRDT.PRGroup
                             and d.PREndDate=PRDT.PREndDate and d.Employee=PRDT.Employee and d.PaySeq=PRDT.PaySeq and d.EDLType='E'
                             and d.EDLCode <= PRDT.EDLCode)
  
 From PRDT 
  Where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate and EDLType='E' 

union all


select PRCo, PRGroup, PREndDate, Employee, PaySeq, null, DedCode=EDLCode, null,
  RecCount=(select count(*) From PRDT d Where d.PRCo=PRDT.PRCo and d.PRGroup=PRDT.PRGroup
                             and d.PREndDate=PRDT.PREndDate and d.Employee=PRDT.Employee and d.PaySeq=PRDT.PaySeq and d.EDLType='D'
                             and d.EDLCode <= PRDT.EDLCode)
 From PRDT 
  Where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate and EDLType='D' 

union all

select PRCo, PRGroup, PREndDate, Employee, PaySeq, null, null, LiabCode=EDLCode,
  RecCount=(select count(*) From PRDT d Where d.PRCo=PRDT.PRCo and d.PRGroup=PRDT.PRGroup
                             and d.PREndDate=PRDT.PREndDate and d.Employee=PRDT.Employee and d.PaySeq=PRDT.PaySeq and d.EDLType='L'
                             and d.EDLCode <= PRDT.EDLCode)
 From PRDT 
  Where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate and EDLType='L' 

insert into #EDLDetail
(PRCo, PRGroup, PREndDate, Employee, PaySeq, RecCount, EarnCode, DedCode, LiabCode)
select PRCo, PRGroup, PREndDate, Employee, PaySeq, RecCount, EarnCode=max(EarnCode), DedCode=max(DedCode), LiabCode=max(LiabCode)
From #EDLCodes 
Group By PRCo, PRGroup, PREndDate, Employee, PaySeq, RecCount


select a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.PaySeq, a.RecCount, a.EarnCode, 
a.DedCode, a.LiabCode, 
EarnAmount=Earn.Amount,
DedAmount=Ded.Amount, 
LiabAmount = Liab.Amount
From #EDLDetail a
Left Join PRDT Earn on Earn.PRCo=a.PRCo and Earn.PRGroup=a.PRGroup and Earn.PREndDate=a.PREndDate and Earn.Employee=a.Employee 
     and Earn.PaySeq=a.PaySeq and Earn.EDLType='E' and Earn.EDLCode=a.EarnCode
Left Join PRDT Ded on Ded.PRCo=a.PRCo and Ded.PRGroup=a.PRGroup and Ded.PREndDate=a.PREndDate and Ded.Employee=a.Employee 
     and Ded.PaySeq=a.PaySeq and Ded.EDLType='D' and Ded.EDLCode=a.DedCode
Left Join PRDT Liab on Liab.PRCo=a.PRCo and Liab.PRGroup=a.PRGroup and Liab.PREndDate=a.PREndDate and Liab.Employee=a.Employee 
     and Liab.PaySeq=a.PaySeq and Liab.EDLType='L' and Liab.EDLCode=a.LiabCode
GO
GRANT EXECUTE ON  [dbo].[brptPREDLCodeDetail] TO [public]
GO
