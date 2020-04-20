SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[vf_rptARAgingByCompany]

                 ( 
                   @MonthEndDate smalldatetime
                   )
                   
/******
 Created:  8/11/11  DH
 Modified:
 
 Usage:  Function returns the AR Aging Amounts by Company through a specified Month End Date.
 		 Funtion used in the vrvARAgingTotalsByCompany view, which selects data for SSRS reports.

  ******/		                    
                   

RETURNS TABLE
AS
RETURN (

SELECT	h.ARCo,
	
		--isnull(h.DueDate,h.TransDate)
		SUM(CASE WHEN DATEDIFF(d,isnull(ARTHApply.DueDate,ARTHApply.TransDate),@MonthEndDate) <= 30
				  THEN l.Amount - l.Retainage
		END) as AmountCurrent,
		
		SUM(CASE WHEN DATEDIFF(d,isnull(ARTHApply.DueDate,ARTHApply.TransDate),@MonthEndDate) > 30
				  AND DATEDIFF(d,isnull(ARTHApply.DueDate,ARTHApply.TransDate),@MonthEndDate) <= 60
			 THEN l.Amount - l.Retainage
		END) as AmountOver30,
		
		SUM(CASE WHEN DATEDIFF(d,isnull(ARTHApply.DueDate,ARTHApply.TransDate),@MonthEndDate) > 60
				  AND DATEDIFF(d,isnull(ARTHApply.DueDate,ARTHApply.TransDate),@MonthEndDate) <= 90
			 THEN l.Amount - l.Retainage
		END) as AmountOver60,
		
		SUM(CASE WHEN DATEDIFF(d,isnull(ARTHApply.DueDate,ARTHApply.TransDate),@MonthEndDate) > 90
			 THEN l.Amount - l.Retainage
		END) as AmountOver90,
		
		sum(l.Amount - l.Retainage) as TotalAged,
		sum(l.Retainage) as Retainage

		
FROM ARTH  h WITH (NOLOCK)
INNER JOIN ARTL l WITH (NOLOCK) ON
	l.ARCo = h.ARCo AND
	l.Mth = h.Mth AND
	l.ARTrans = h.ARTrans
INNER JOIN ARTH ARTHApply ON
	ARTHApply.ARCo = l.ARCo AND
	ARTHApply.Mth = l.ApplyMth AND
	ARTHApply.ARTrans = l.ApplyTrans
	
	
WHERE h.ARTransType<>'M' AND --exclude Misc Payments 
	  h.TransDate<=@MonthEndDate 

GROUP BY h.ARCo)


		 
	  


	
			

GO
GRANT SELECT ON  [dbo].[vf_rptARAgingByCompany] TO [public]
GO
