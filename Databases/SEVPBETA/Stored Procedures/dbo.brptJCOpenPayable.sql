SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    Proc [dbo].[brptJCOpenPayable] 
   (@JCCo bCompany, @Contract bContract, @ThroughMth bDate) as
   /**********************
   Stored Procecure to calculate Amount Paid to date on a Contract.
   Created 2/25/02 CR
   
   This Stored Procedure only calculates the amount paid per contract.
   
   Reports that use: JCContractStat.rpt
   **********************/
   /* Issue 25871 add with (nolock) DW 10/22/04*/
   /* D-04862 HH 4/18/2012 Removed GST amount from Unpaid:= sum(APTD.Amount)-sum(APTD.GSTtaxAmt)*/
   
        select JCJM.JCCo, JCJM.Contract, JCJM.Job, APTL.PhaseGroup, APTL.JCCType, JCCT.Abbreviation,
               Unpaid=sum(APTD.Amount)-sum(APTD.GSTtaxAmt)
        from JCJM with(nolock)
        join APTL with(nolock) on APTL.JCCo=JCJM.JCCo and APTL.Job=JCJM.Job
        join APTD with(nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and 
        APTL.APLine=APTD.APLine
        join JCCT with(nolock) on APTL.JCCType=JCCT.CostType and APTL.PhaseGroup=JCCT.PhaseGroup 
   
        where  JCJM.JCCo= @JCCo and JCJM.Contract= @Contract 
               and ( (APTD.Mth <=@ThroughMth and  APTD.PaidMth>@ThroughMth) or 
               (APTD.Mth <= @ThroughMth and APTD.PaidMth is null ))
        GROUP BY
        	JCJM.JCCo, JCJM.Contract, JCJM.Job, APTL.PhaseGroup, APTL.JCCType,
                JCCT.Abbreviation

GO
GRANT EXECUTE ON  [dbo].[brptJCOpenPayable] TO [public]
GO
