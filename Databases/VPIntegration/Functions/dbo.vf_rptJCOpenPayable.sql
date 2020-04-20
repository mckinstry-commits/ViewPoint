SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vf_rptJCOpenPayable]
                 ( @JCCo tinyint,
                   @Contract varchar(10),
                   @PreviousMth smalldatetime,
                   @ThroughMth smalldatetime )
                   
/******
 Created:  8/10/11  DH
 Modified:
 
 Usage:  Function returns the unpaid amount from AP for obtaining the open payable amount figured into
		 contract net cash flow calculations for reports.  Funtion used in the vrvJCNetCashFlow view, which 
		 selects data for SSRS reports.

  ******/		                    
                   

RETURNS TABLE
AS
RETURN (
SELECT	 JCJM.JCCo,
		 JCJM.Contract,
		 --Include AP transactions where the paid month is null or is past the through/previous month 
		 sum( case when (APTD.Mth <=@PreviousMth and  APTD.PaidMth>@PreviousMth) or 
                         (APTD.Mth <= @PreviousMth and APTD.PaidMth is null )
                   then APTD.Amount
              end) as UnpaidPrevious,      
                                 
		 sum(case when APTD.PaidMth>@ThroughMth or APTD.PaidMth is null then APTD.Amount end) as Unpaid
  FROM APTD WITH (NOLOCK)
        
  INNER JOIN APTL WITH (NOLOCK) ON
			 APTD.APCo=APTL.APCo AND
			 APTD.Mth=APTL.Mth AND
			 APTD.APTrans=APTL.APTrans AND 
			 APTL.APLine=APTD.APLine
  INNER JOIN JCJM WITH (NOLOCK) ON 
			 APTL.JCCo=JCJM.JCCo AND
			 APTL.Job=JCJM.Job
  INNER JOIN JCCM WITH (NOLOCK) ON
			 JCCM.JCCo = JCJM.JCCo AND
			 JCCM.Contract = JCJM.Contract
  
  WHERE  JCCM.JCCo = @JCCo and JCCM.Contract = @Contract and APTD.Mth <=@ThroughMth
               /*and ( (APTD.Mth <=@ThroughMth and  APTD.PaidMth>@ThroughMth) or 
               (APTD.Mth <= @ThroughMth and APTD.PaidMth is null ))*/
  GROUP BY
       	JCJM.JCCo,
       	JCJM.Contract
       ) 
       
       	
GO
GRANT SELECT ON  [dbo].[vf_rptJCOpenPayable] TO [public]
GO
