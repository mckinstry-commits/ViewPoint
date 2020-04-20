SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvARBH_CMDist] as
    
    select	OldNew = 1, 
    	Co, 
    	Mth, 
    	BatchId, 
    	BatchSeq, 
    	TransType,
            ARTransType, 
    	ARTrans,
            CustGroup,
    	Customer, 
    	CheckNo, 
    	"Description", 
    	TransDate, 
    	CheckDate, 
    	CMCo, 
    	CMAcct, 
    	CMDeposit, 
    	CreditAmt 
    from ARBH
    where TransType <> 'D' 
    
    union all
    
    select	OldNew = 0, 
    	Co, 
    	Mth, 
    	BatchId, 
    	BatchSeq, 
    	TransType, 
            ARTransType,
    	ARTrans, 
            CustGroup,
    	Customer, 
    	oldCheckNo, 
    	oldDescription, 
    	oldTransDate, 
    	oldCheckDate, 
    	oldCMCo, 
    	oldCMAcct, 
    	oldCMDeposit,
    	-1* oldCreditAmt
    from ARBH
    where TransType <> 'A'

GO
GRANT SELECT ON  [dbo].[brvARBH_CMDist] TO [public]
GRANT INSERT ON  [dbo].[brvARBH_CMDist] TO [public]
GRANT DELETE ON  [dbo].[brvARBH_CMDist] TO [public]
GRANT UPDATE ON  [dbo].[brvARBH_CMDist] TO [public]
GO
