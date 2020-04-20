SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           View [dbo].[brvCMST]
   
   /* Used to calculate the Current Acct Balance */
   
    as
Select CMCo,CMAcct,StmtDate=Max(StmtDate),StmtBal=min(StmtBal)
    From CMST
   Where Status=1
   Group by CMCo,CMAcct

GO
GRANT SELECT ON  [dbo].[brvCMST] TO [public]
GRANT INSERT ON  [dbo].[brvCMST] TO [public]
GRANT DELETE ON  [dbo].[brvCMST] TO [public]
GRANT UPDATE ON  [dbo].[brvCMST] TO [public]
GRANT SELECT ON  [dbo].[brvCMST] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvCMST] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvCMST] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvCMST] TO [Viewpoint]
GO
