SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [dbo].[SLClaimHeaderTotal] as
/*****************************
* Created By:	GF 09/14/2012 TK-17944
* Modified By:
*
*
* Displays SL Claim Totals from SLIT, SLClaimItems
* for display in SL Claims form.
*
* THESE TOTALS ARE ALSO OUTPUT PARAMETERS IN vspSLClaimNoTotalsGet using this view.
*
********************************/

SELECT TOP 100 PERCENT
		c.KeyID AS SLClaimKeyID
		,c.SLCo
		,c.SL
		,c.ClaimNo
        
        ---- subcontract totals
		,CAST(SLITTOTAL.OrigContractAmt AS NUMERIC(16,2)) AS [OrigContractAmt]
		,CAST(SLITTOTAL.CurrContractAmt AS NUMERIC(16,2)) AS [CurrContractAmt]
		,CAST(SLITTOTAL.Variations		AS NUMERIC(16,2)) AS [Variations]

		---- subcntract this claim totals
		,CAST(ISNULL(THISCLAIM.ThisAmtClaimed, 0)	AS NUMERIC(16,2)) AS [ClaimAmount]
		,CAST(ISNULL(THISCLAIM.ThisAmtApproved, 0)	AS NUMERIC(16,2)) AS [ApproveAmount]
		,CAST(ISNULL(THISCLAIM.ThisRetApproved, 0)	AS NUMERIC(16,2)) AS [ApproveRetention]
		,CAST(ISNULL(THISCLAIM.ThisTaxAmount, 0)	AS NUMERIC(16,2)) AS [ApproveTaxAmount]
		,CAST(ISNULL(THISCLAIM.ThisPayment, 0)		AS NUMERIC(16,2)) AS [ThisPayment]
		,CAST(ISNULL(THISCLAIM.ThisAmtPayable, 0)	AS NUMERIC(16,2)) AS [AmountPayable]
		---- this claim retainage percentage
		,CAST(ISNULL(THISCLAIM.ThisRetPct, 0)		AS NUMERIC(9,4)) AS [RetentionPct]

		---- subcontract previous claim totals
		,CAST(ISNULL(CLAIMPRIOR.PriorAmtClaimed, 0)  AS NUMERIC(16,2)) AS [PreviousClaimed]
		,CAST(ISNULL(CLAIMPRIOR.PriorAmtApproved, 0) AS NUMERIC(16,2)) AS [PreviousApproved]
		,CAST(ISNULL(CLAIMPRIOR.PriorRetApproved, 0) AS NUMERIC(16,2)) AS [PreviousApprovedRet]
		,CAST(ISNULL(CLAIMPRIOR.PriorTaxAmount, 0)   AS NUMERIC(16,2)) AS [PreviousTaxAmount]

		---- subcontract to date claim totals
		,CAST(ISNULL(CLAIMTOTAL.SLTotalClaimed, 0)		AS NUMERIC(16,2)) AS [TotalClaimed]
		,CAST(ISNULL(CLAIMTOTAL.SLTotalApproved, 0)		AS NUMERIC(16,2)) AS [TotalApproved]
		,CAST(ISNULL(CLAIMTOTAL.SLTotalApprovedRet, 0)	AS NUMERIC(16,2)) AS [TotalApprovedRet]
		,CAST(ISNULL(CLAIMTOTAL.SLTotalTaxAmount, 0)	AS NUMERIC(16,2)) AS [TotalTaxAmount]
		
FROM dbo.SLClaimHeader c

	---- subcontract item totals
    OUTER APPLY (SELECT OrigContractAmt	= ISNULL(SUM(i.OrigCost), 0)
                       ,CurrContractAmt = ISNULL(SUM(i.CurCost), 0)
                       ,Variations		= ISNULL(SUM(i.CurCost), 0) - ISNULL(SUM(i.OrigCost), 0)
                  FROM dbo.bSLIT i
                  WHERE i.SLCo = c.SLCo
                         AND i.SL = c.SL
                ) SLITTOTAL
     

	---- subcontract to date claim totals
    OUTER APPLY (SELECT SLTotalClaimed	  = ISNULL(SUM(e.ClaimAmount), 0)
                       ,SLTotalApproved	  = ISNULL(SUM(e.ApproveAmount), 0)
                       ,SLTotalApprovedRet= ISNULL(SUM(e.ApproveRetention), 0)
                       ,SLTotalTaxAmount  = ISNULL(SUM(e.TaxAmount), 0)
                  FROM dbo.vSLClaimItem e
                  WHERE e.SLCo = c.SLCo
                         AND e.SL = c.SL
                         AND c.ClaimStatus <> 20 ----denied
                  GROUP BY  e.SLCo,
                            e.SL
                ) CLAIMTOTAL

	---- SL CLAIM PREVIOUS AMOUNTS
    OUTER APPLY ( SELECT PriorAmtClaimed  = ISNULL(SUM(p.ClaimAmount), 0)
						,PriorAmtApproved = ISNULL(SUM(p.ApproveAmount), 0)
						,PriorRetApproved = ISNULL(SUM(p.ApproveRetention), 0)
						,PriorTaxAmount   = ISNULL(SUM(p.TaxAmount), 0)
                  FROM dbo.vSLClaimItem p
                  INNER JOIN dbo.vSLClaimHeader h ON h.SLCo=p.SLCo AND h.SL=p.SL AND h.ClaimNo=p.ClaimNo
                  WHERE p.SLCo = c.SLCo
					 AND p.SL = c.SL
					 ---- prior claims with earlier claim date are prior
					 AND (p.ClaimNo < c.ClaimNo AND h.ClaimDate <= c.ClaimDate)
					 AND c.ClaimStatus <> 20 ----denied
                  GROUP BY p.SLCo,
                           p.SL
                ) CLAIMPRIOR

	---- SL CLAIM THIS CLAIM
    OUTER APPLY ( SELECT ThisAmtClaimed  = ISNULL(SUM(m.ClaimAmount), 0)
						,ThisAmtApproved = ISNULL(SUM(m.ApproveAmount), 0)
						,ThisRetApproved = ISNULL(SUM(m.ApproveRetention), 0)
						,ThisTaxAmount   = ISNULL(SUM(m.TaxAmount), 0)
						,ThisPayment	 = ISNULL(SUM(m.ApproveAmount), 0) - ISNULL(SUM(m.ApproveRetention), 0)
						,ThisAmtPayable  = ISNULL(SUM(m.ApproveAmount), 0) - ISNULL(SUM(m.ApproveRetention), 0) + ISNULL(SUM(m.TaxAmount), 0)
						---- this claim retainage percentage
						,ThisRetPct		 = CASE WHEN ISNULL(SUM(m.ApproveAmount), 0) = 0 THEN 0
											ELSE (ISNULL(SUM(m.ApproveRetention), 0) / ISNULL(SUM(m.ApproveAmount), 0))
											END 
                  FROM dbo.vSLClaimItem m
                  WHERE m.SLCo = c.SLCo
					 AND m.SL = c.SL
					 AND m.ClaimNo = c.ClaimNo
                  GROUP BY m.SLCo,
                           m.SL,
                           m.ClaimNo
                ) THISCLAIM

GROUP BY c.SLCo
		,c.SL
		,c.ClaimNo
		,c.KeyID
		,OrigContractAmt
		,CurrContractAmt
		,Variations
		,ThisAmtClaimed
		,ThisAmtApproved
		,ThisRetApproved
		,ThisTaxAmount
		,ThisPayment
		,ThisAmtPayable
		,ThisRetPct
		,PriorAmtClaimed
		,PriorAmtApproved
		,PriorRetApproved
		,PriorTaxAmount
		,SLTotalClaimed
		,SLTotalApproved
		,SLTotalApprovedRet
		,SLTotalTaxAmount
   
ORDER BY  c.SLCo, c.SL, c.ClaimNo










GO
GRANT SELECT ON  [dbo].[SLClaimHeaderTotal] TO [public]
GRANT INSERT ON  [dbo].[SLClaimHeaderTotal] TO [public]
GRANT DELETE ON  [dbo].[SLClaimHeaderTotal] TO [public]
GRANT UPDATE ON  [dbo].[SLClaimHeaderTotal] TO [public]
GO
