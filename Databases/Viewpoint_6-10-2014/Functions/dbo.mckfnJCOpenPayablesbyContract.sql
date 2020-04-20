SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/17/2014
-- Description:	Return Open Payables for reports
-- =============================================
CREATE FUNCTION [dbo].[mckfnJCOpenPayablesbyContract]
(	
	-- Add the parameters for the function here
	@JCCo bCompany, 
	@Contract bContract
	, @Mth bMonth
)
RETURNS TABLE 
AS
RETURN 
(
	--DECLARE @JCCo bCompany = 101, @Contract bContract = '080600-', @Mth bMonth = '2014-03-01 00:00:00'
	-- Add the SELECT statement with parameter references here
	select JCJM.JCCo, JCJM.Contract, Unpaid=sum(APTD.Amount)-sum(APTD.GSTtaxAmt)
        from JCJM with(nolock)
        join APTL with(nolock) on APTL.JCCo=JCJM.JCCo and APTL.Job=JCJM.Job
        join APTD with(nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and 
        APTL.APLine=APTD.APLine
        join JCCT with(nolock) on APTL.JCCType=JCCT.CostType and APTL.PhaseGroup=JCCT.PhaseGroup 
   
        where  JCJM.JCCo= @JCCo and JCJM.Contract= @Contract 
               and ( (APTD.Mth <=@Mth and  APTD.PaidMth>@Mth) or 
               (APTD.Mth <= @Mth and APTD.PaidMth is null ) OR @Mth IS NULL)
        GROUP BY
        	JCJM.JCCo, JCJM.Contract
)
GO
