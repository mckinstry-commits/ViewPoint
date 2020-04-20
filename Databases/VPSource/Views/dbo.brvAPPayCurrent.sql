SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvAPPayCurrent]
    
    /**************
     Created 6/17/01  DH
     Usage:  Used by the AP Payment Audit report to get
             the current amount and discount from APDB.  View returns one line
             per Co, Mth, BatchId, BatchSeq, ExpMth, APTrans
    
    **************/
    
    as
    
    Select Co, Mth, BatchId, BatchSeq, ExpMth, APTrans, CurrentAmt=sum(Amount), DiscTaken=sum(DiscTaken) From APDB
                  Group By Co, Mth, BatchId, BatchSeq, ExpMth, APTrans

GO
GRANT SELECT ON  [dbo].[brvAPPayCurrent] TO [public]
GRANT INSERT ON  [dbo].[brvAPPayCurrent] TO [public]
GRANT DELETE ON  [dbo].[brvAPPayCurrent] TO [public]
GRANT UPDATE ON  [dbo].[brvAPPayCurrent] TO [public]
GO
