SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE
   Proc [dbo].[brptPRSQforTaxLiab] 
   
   (@Company bCompany, @QtrEndMonth bDate, @FedDedn tinyint, @FICAMedDedn tinyint, @FICASSDedn tinyint,
   @FICAMedLiab tinyint, @FICASSLiab tinyint, @EICDednCode tinyint) 
   as 
   select Q.PRCo, Q.PRGroup,Q.PREndDate, Q.PaidDate,Q.PayMethod,
      CasePaidDate=case when Q.PayMethod='X' and Q.PaidDate is null then Q.PREndDate else Q.PaidDate end,
      CasePaidDay =case when Q.PayMethod='X' and Q.PaidDate is null then Day(Q.PREndDate) else Day(Q.PaidDate) end,
      FedAmt = case when @FedDedn=PRDT.EDLCode then PRDT.Amount end,
      FICAMedDed= Case when @FICAMedDedn=PRDT.EDLCode then PRDT.Amount end,
      FICASSDed = case when @FICASSDedn=PRDT.EDLCode then PRDT.Amount end,
      FICAMedLiab=case when @FICAMedLiab=PRDT.EDLCode then PRDT.Amount end,
      FICASSLiab = case when @FICASSLiab=PRDT.EDLCode then PRDT.Amount end,
      EICDedCode = case when @EICDednCode=PRDT.EDLCode then PRDT.Amount end,
      DateAdd(Month,-2,@QtrEndMonth),@QtrEndMonth, Datepart(q,@QtrEndMonth)
      
      
      
    
   
   
   
   
    from PRSQ Q
   Inner join PRDT on Q.PRCo=PRDT.PRCo and Q.PRGroup=PRDT.PRGroup and Q.PREndDate=PRDT.PREndDate and Q.Employee=PRDT.Employee and
   Q.PaySeq=PRDT.PaySeq 
   
   where @Company=Q.PRCo and PRDT.EDLType<>'E' and 
   Year(case when Q.PayMethod='X' and Q.PaidDate is null then Q.PREndDate else Q.PaidDate end)=Year(@QtrEndMonth) 
   and--(case when Q.PayMethod='X' and Q.PaidDate is null then Q.PREndDate else Q.PaidDate end)<='1/31/04'
   --(case when Q.PayMethod='X' and Q.PaidDate is null then Q.PREndDate else Q.PaidDate end)<= @QtrEndMonth and
   --(case when Q.PayMethod='X' and Q.PaidDate is null then Q.PREndDate else Q.PaidDate end)>=DateAdd(Month,-2,@QtrEndMonth)
   --(case when Q.PayMethod='X' and Q.PaidDate is null then Q.PREndDate else Q.PaidDate end) between DateAdd(Month,-2,@QtrEndMonth) and @QtrEndMonth
   DatePart(q,@QtrEndMonth)=Datepart(q,(case when Q.PayMethod='X' and Q.PaidDate is null then Q.PREndDate else Q.PaidDate end))

GO
GRANT EXECUTE ON  [dbo].[brptPRSQforTaxLiab] TO [public]
GO
