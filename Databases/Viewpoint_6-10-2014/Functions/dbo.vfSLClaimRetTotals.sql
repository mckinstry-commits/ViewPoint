SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/***********************************************************
* CREATED BY:	GF 11/12/2012 TK-19744 TK-19328 SL Claims Enhancement
* MODIFIED By:	GF 10/03/2013 TFS-63634 change to not include paid retention when SLHD.MaxRetOpt = 'N'
*
*
*
* USAGE:
* This function will calculate the subcontract retention budget, taken, and remaining
* to display in the SL Claims form for subcontract info.
*
* Will use the subcontract header maximum retention option for retention calculations
* if applicable. If not using MaxRetgOpt option, then will calculate the budget using 
* the SLIT current cost and WCRetPct values.
*
* If tax amounts exists in APTD then will be deducted from the retention withheld.
*
* The retention taken will be broken down into 4 parts.
* 1. the sum from APTD for the subcontract that is not in a batch.
* 2. the sum from APLB for the subcontract.
* 3. the sum from APUL for the subcontract.
* 4. the sum of approved retention from SLClaimItem for claims not in AP
*
* The retention remaining will be budget - taken.
*
* INPUT PARAMETERS
* @slco				SL Company
* @sl				Subcontract
*
*
* OUTPUT PARAMETERS
* retention budget
* retention taken
* retention remaining
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

CREATE FUNCTION [dbo].[vfSLClaimRetTotals]
(
	 @SLCo INT = NULL
	,@SL VARCHAR(30) = NULL
    ,@ClaimNo INT = NULL  
)

RETURNS @RetentionTotals TABLE (
								 RetentionBudget NUMERIC(16,2)
								,RetentionTaken	 NUMERIC(16,2)
								,RetentionRemain NUMERIC(16,2)
								,ThisClaimRet	 NUMERIC(16,2)
							    )

AS
BEGIN

	DECLARE @RetentionBudget	NUMERIC(16,2)
			,@RetentionTaken	NUMERIC(16,2)
			,@RetentionRemeain	NUMERIC(16,2)
			,@RetAmountAPLB		NUMERIC(16,2)
			,@RetAmountAPUL		NUMERIC(16,2)
			,@SLTotalRetNotInAP NUMERIC(16,2)
			,@ThisClaimRet		NUMERIC(16,2)

	SET @RetentionBudget = 0
	SET @RetentionTaken = 0
	SET @RetentionRemeain = 0
	SET @SLTotalRetNotInAP = 0
	SET @ThisClaimRet = 0

	---- the retention budget will be based on the maximum retention option in SLHD
	---- we have 3 options. N-None, P-Percent, A-Amount. Tax is not included in the budget
	SELECT @RetentionBudget = 
			CASE h.MaxRetgOpt 
				 WHEN 'A' THEN ISNULL(h.MaxRetgAmt,0)

				 WHEN 'P' THEN
						CASE WHEN h.InclACOinMaxYN = 'Y'
							 THEN (ISNULL(h.MaxRetgPct,0) * SUM_CurCost) ----+ (ISNULL(h.MaxRetgPct,0) * Calc_CurTax)
						ELSE
							 (ISNULL(h.MaxRetgPct,0) * SUM_OrigCost) ----+ (ISNULL(h.MaxRetgPct,0) * Calc_OrigTax)
						END
						   
						     
						--	CASE WHEN c.DefaultCountry = 'US' 
						--		 THEN (ISNULL(h.MaxRetgPct,0) * SUM_CurCost) ----+ (ISNULL(h.MaxRetgPct,0) * Calc_CurTax)
						--	ELSE
						--		CASE WHEN a.TaxBasisNetRetgYN = 'Y'
						--				THEN (ISNULL(h.MaxRetgPct,0) * SUM_CurCost) ----+ (ISNULL(h.MaxRetgPct,0) * Calc_CurTax_Less_GST)
						--				ELSE (ISNULL(h.MaxRetgPct,0) * SUM_CurCost)
						--				END
						--	END
						--ELSE                          
						--	CASE WHEN c.DefaultCountry = 'US'
						--		 THEN (ISNULL(h.MaxRetgPct,0) * SUM_OrigCost) ----+ (ISNULL(h.MaxRetgPct,0) * Calc_OrigTax)
						--	ELSE
						--		CASE WHEN a.TaxBasisNetRetgYN = 'Y'
						--				THEN (ISNULL(h.MaxRetgPct,0) * SUM_OrigCost) ----+ (ISNULL(h.MaxRetgPct,0) * Calc_OrigTax_Less_GST)
						--				ELSE (ISNULL(h.MaxRetgPct,0) * SUM_OrigCost)
						--				END                         
						--	END
						--END	                          

				 WHEN 'N' THEN Calc_CurRet ----+ Calc_CurTax_Ret

				 ELSE 0

				 END
                 
					--	  CASE WHEN c.DefaultCountry = 'US'
					--		   THEN Calc_CurRet ----+ Calc_CurTax_Ret
					--		 ELSE
					--			CASE WHEN a.TaxBasisNetRetgYN = 'Y'
					--			THEN Calc_CurRet ----+ Calc_CurTax_Less_GST
					--			ELSE Calc_CurRet ----+ Calc_CurTax_Ret
					--			END
					--	  END	
				 --ELSE 0
				 --END
                 
	FROM dbo.bSLHD h WITH (NOLOCK)
	INNER JOIN dbo.bHQCO c ON c.HQCo = h.SLCo
	INNER JOIN dbo.bAPCO a ON a.APCo = h.SLCo
	CROSS APPLY  
	    (
	    SELECT  SUM(ISNULL(t.CurCost, 0)) SUM_CurCost
			   ,SUM(ISNULL(t.OrigCost,0)) SUM_OrigCost
			   ,SUM(ISNULL(t.WCRetPct,0)  * ISNULL(t.CurCost, 0)) Calc_CurRet
			   --,SUM(ISNULL(t.CurCost, 0)  * ISNULL(t.TaxRate, 0)) Calc_CurTax
			   --,SUM(ISNULL(t.OrigCost, 0) * ISNULL(t.TaxRate, 0)) Calc_OrigTax
			   --,SUM(ISNULL(t.CurCost, 0)  * (ISNULL(t.TaxRate, 0) - ISNULL(t.GSTRate, 0)) * ISNULL(t.WCRetPct,0)) Calc_CurTax_Less_GST
			   --,SUM(ISNULL(t.OrigCost, 0) * (ISNULL(t.TaxRate, 0) - ISNULL(t.GSTRate, 0)) * ISNULL(t.WCRetPct,0)) Calc_OrigTax_Less_GST
			   --,SUM(ISNULL(t.CurCost, 0)  * (ISNULL(t.WCRetPct,0) * ISNULL(t.TaxRate, 0))) Calc_CurTax_Ret
		 FROM dbo.bSLIT t  WITH (NOLOCK)
		 WHERE h.SLCo = t.SLCo 
		 AND h.SL = t.SL 
		 AND t.ItemType IN (1,2)
		 AND t.WCRetPct <> 0
		 ) t
	WHERE h.SLCo = @SLCo
		AND h.SL = @SL


	----Retainage total from posted AP Invoices	
	SELECT @RetentionTaken = 
			CASE WHEN d.PayCategory IS NULL
				 THEN (CASE WHEN d.PayType = a.RetPayType THEN ISNULL(SUM(d.Amount),0) - ISNULL(SUM(d.TotTaxAmount),0)
				 ELSE 0 END)                              
			ELSE (CASE WHEN d.PayType = c.RetPayType THEN ISNULL(SUM(d.Amount),0) - ISNULL(SUM(d.TotTaxAmount),0)
				 ELSE 0 END)
			END
            
	FROM dbo.bAPTD d WITH (NOLOCK)
	INNER JOIN dbo.bAPCO a WITH (NOLOCK) ON a.APCo = d.APCo
	INNER JOIN dbo.bHQCO h WITH (NOLOCK) ON h.HQCo = d.APCo
	INNER JOIN dbo.bAPTL l WITH (NOLOCK) ON l.APCo = d.APCo and l.Mth = d.Mth and l.APTrans = d.APTrans and d.APLine = l.APLine
	INNER JOIN dbo.bSLIT s WITH (NOLOCK) ON s.SLCo = d.APCo and l.SL = s.SL and l.SLItem = s.SLItem
	LEFT OUTER JOIN dbo.bAPPC c WITH (NOLOCK) ON c.APCo = d.APCo AND c.PayCategory = d.PayCategory
	----TFS-63634
	INNER JOIN dbo.bSLHD SLHD WITH (NOLOCK) ON SLHD.SLCo = d.APCo AND SLHD.SL = l.SL
	WHERE l.APCo = @SLCo
		AND l.SL = @SL
		AND d.APCo = @SLCo
		AND NOT EXISTS(select 1 from dbo.bAPLB b WITH (NOLOCK) WHERE b.Co=l.APCo AND b.Mth=l.Mth
								AND b.APLine=l.APLine AND b.SL=l.SL AND b.SLItem=l.SLItem)
		----TFS-63634
		AND d.Status < 3 ----unpaid retention
		---- retention not on hold is released, if using max retention then is still retention
		---- otherwise only consider taken if still on hold
		AND (SLHD.MaxRetgOpt  <> 'N'
			OR (SLHD.MaxRetgOpt = 'N'
				AND EXISTS(SELECT 1 FROM dbo.bAPHD APHD WHERE APHD.APCo=d.APCo AND APHD.Mth=d.Mth
						AND APHD.APTrans=d.APTrans AND APHD.APLine=d.APLine AND APHD.APSeq=d.APSeq
						AND APHD.HoldCode = a.RetHoldCode)))
	GROUP BY h.DefaultCountry, a.TaxBasisNetRetgYN, d.PayCategory, d.PayType, a.RetPayType, c.RetPayType


	----TFS-63634 paid retainage total from posted AP Invoices	
	SELECT @RetentionTaken = @RetentionTaken +
			CASE WHEN d.PayCategory IS NULL
					THEN (CASE WHEN d.PayType = a.RetPayType THEN ISNULL(SUM(d.Amount),0) - ISNULL(SUM(d.TotTaxAmount),0)
					ELSE 0 END)                              
			ELSE (CASE WHEN d.PayType = c.RetPayType THEN ISNULL(SUM(d.Amount),0) - ISNULL(SUM(d.TotTaxAmount),0) 
					ELSE 0 END)
			END        
	FROM dbo.bAPTD d WITH (NOLOCK)
	INNER JOIN dbo.bAPCO a WITH (NOLOCK) ON a.APCo = d.APCo
	INNER JOIN dbo.bHQCO h WITH (NOLOCK) ON h.HQCo = d.APCo
	INNER JOIN dbo.bAPTL l WITH (NOLOCK) ON l.APCo = d.APCo and l.Mth = d.Mth and l.APTrans = d.APTrans and d.APLine = l.APLine
	INNER JOIN dbo.bSLIT s WITH (NOLOCK) ON s.SLCo = d.APCo and l.SL = s.SL and l.SLItem = s.SLItem
	INNER JOIN dbo.bSLHD SLHD WITH (NOLOCK) ON SLHD.SLCo = d.APCo and SLHD.SL = l.SL
	LEFT OUTER JOIN dbo.bAPPC c WITH (NOLOCK) ON c.APCo = d.APCo AND c.PayCategory = d.PayCategory
	WHERE l.APCo = @SLCo
		AND l.SL = @SL
		AND d.APCo = @SLCo
		AND d.Status = 3 ----paid retention
		AND SLHD.MaxRetgOpt <> 'N'
		AND NOT EXISTS(select 1 from dbo.bAPLB b WITH (NOLOCK) WHERE b.Co=l.APCo AND b.Mth=l.Mth
					AND b.APLine=l.APLine AND b.SL=l.SL AND b.SLItem=l.SLItem)
	GROUP BY h.DefaultCountry, a.TaxBasisNetRetgYN, d.PayCategory, d.PayType, a.RetPayType, c.RetPayType
			 
			 
			                
	----Retainage amount from Open AP Transaction Batches
	SELECT @RetAmountAPLB = ISNULL(SUM(b.Retainage), 0)
	FROM dbo.bAPLB b WITH (NOLOCK)
	JOIN dbo.bSLIT s WITH (NOLOCK) ON s.SLCo=b.Co AND b.SL=s.SL AND b.SLItem=s.SLItem
	WHERE b.Co = @SLCo
		AND b.SL = @SL

	----Get retainage amounts from AP Unapproved Invoices
	SELECT @RetAmountAPUL = ISNULL(SUM(l.Retainage), 0)
	FROM dbo.bAPUL l WITH (NOLOCK)
	JOIN dbo.bSLIT s WITH (NOLOCK) ON s.SLCo=l.APCo AND l.SL=s.SL AND l.SLItem=s.SLItem
	WHERE l.APCo = @SLCo
		AND l.SL = @SL 


	---- subcontract to date retention total not in AP
	SELECT @SLTotalRetNotInAP = ISNULL(SUM(e.ApproveRetention), 0)
	FROM dbo.vSLClaimItem e
	INNER JOIN dbo.vSLClaimHeader h ON e.SLCo=h.SLCo AND e.SL=h.SL AND e.ClaimNo=h.ClaimNo
	WHERE e.SLCo = @SLCo
		AND e.SL = @SL
		AND h.ClaimStatus <> 20
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPUI APUI WHERE APUI.SLKeyID = h.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPHB APHB WHERE APHB.SLKeyID = h.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPTL APTL WHERE APTL.SLKeyID = h.KeyID)

	---- retention taken to date less current claim
	SELECT @ThisClaimRet = ISNULL(SUM(e.ApproveRetention), 0)
	FROM dbo.vSLClaimItem e
	INNER JOIN dbo.vSLClaimHeader h ON e.SLCo=h.SLCo AND e.SL=h.SL AND e.ClaimNo=h.ClaimNo
	WHERE e.SLCo = @SLCo
		AND e.SL = @SL
		AND e.ClaimNo = @ClaimNo
		AND h.ClaimStatus <> 20
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPUI APUI WHERE APUI.SLKeyID = h.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPHB APHB WHERE APHB.SLKeyID = h.KeyID)
		AND NOT EXISTS(SELECT 1 FROM dbo.bAPTL APTL WHERE APTL.SLKeyID = h.KeyID)

	----set retainage amount withheld
	SELECT @RetentionTaken = ISNULL(@RetentionTaken,0)
				+ ISNULL(@RetAmountAPLB, 0)
				+ ISNULL(@RetAmountAPUL, 0)
				+ ISNULL(@SLTotalRetNotInAP, 0)


	INSERT INTO @RetentionTotals (RetentionBudget, RetentionTaken, RetentionRemain, ThisClaimRet) 
	VALUES (
			ISNULL(@RetentionBudget, 0),
			ISNULL(@RetentionTaken, 0),
			ISNULL(@RetentionBudget, 0) - ISNULL(@RetentionTaken,0),
			ISNULL(@ThisClaimRet, 0)
			)
	
	RETURN
END








GO
GRANT SELECT ON  [dbo].[vfSLClaimRetTotals] TO [public]
GO
