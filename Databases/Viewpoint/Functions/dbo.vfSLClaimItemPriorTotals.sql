SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Gil Fox TK-19744 SL Claims
-- Create date: 09/18/2012
-- Description:	Retrieves prior values for a SL Claim item.
-- =============================================
CREATE FUNCTION [dbo].[vfSLClaimItemPriorTotals]
(	
	 @SLCo TINYINT
	,@SL VARCHAR(30)
	,@ClaimNo INT
	,@SLItem SMALLINT
	,@ClaimDate SMALLDATETIME
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
			 CAST(ISNULL(SUM(i.ClaimUnits), 0)		 AS NUMERIC(16,3)) AS [PrevClaimUnits]
			,CAST(ISNULL(SUM(i.ClaimAmount), 0)		 AS NUMERIC(16,2)) AS [PrevClaimAmt]
			,CAST(ISNULL(SUM(i.ApproveUnits), 0)	 AS NUMERIC(16,3)) AS [PrevApproveUnits]
			,CAST(ISNULL(SUM(i.ApproveAmount), 0)	 AS NUMERIC(16,2)) AS [PrevApproveAmt]
			,CAST(ISNULL(SUM(i.ApproveRetention), 0) AS NUMERIC(16,2)) AS [PrevApproveRet]

	FROM dbo.vSLClaimItem i
		INNER JOIN dbo.vSLClaimHeader h ON h.SLCo=i.SLCo AND h.SL=i.SL AND h.ClaimNo=i.ClaimNo
	WHERE i.SLCo = @SLCo
		AND i.SL = @SL
		AND i.SLItem = @SLItem
		---- prior claims with earlier claim date are prior
		AND (i.ClaimNo < @ClaimNo AND h.ClaimDate <= ISNULL(@ClaimDate, h.ClaimDate))
		AND h.ClaimStatus <> 20 ----denied

)




GO
GRANT SELECT ON  [dbo].[vfSLClaimItemPriorTotals] TO [public]
GO
