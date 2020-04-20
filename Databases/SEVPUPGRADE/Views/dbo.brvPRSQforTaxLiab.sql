SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvPRSQforTaxLiab] as select PRCo, PRGroup, PREndDate, Employee, PaySeq, CMCo, CMAcct, PayMethod,
      CMRef, CMRefSeq, EFTSeq, ChkType, 
      PaidDate=case when PayMethod='X' and PaidDate is null then PREndDate else PaidDate end,
      PaidMth, Hours, Earnings, Dedns,
      SUIEarnings,    PostToAll, Processed , CMInterface
    from PRSQ

GO
GRANT SELECT ON  [dbo].[brvPRSQforTaxLiab] TO [public]
GRANT INSERT ON  [dbo].[brvPRSQforTaxLiab] TO [public]
GRANT DELETE ON  [dbo].[brvPRSQforTaxLiab] TO [public]
GRANT UPDATE ON  [dbo].[brvPRSQforTaxLiab] TO [public]
GO
