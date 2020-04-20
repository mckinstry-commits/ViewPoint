SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/********************************/
CREATE view [dbo].[PMSLTotal] as
/********************************
* Created By:	GF 05/12/2011 - TK-00000
* Modified By:
*
* Displays Totals from SL and PM (not interfaced)
* These totals will have have tax as separate columns
* and included in the summary totals.
* This view is currently used in PM SL Header form for total display
*
* * calculated maximum retainage amount based upon:
*
*	SLHD Percent of Contract setup value.
*	SLHD exclude Variations from Max Retainage by % value.
*	SLIT Non-Zero Retainage Percent items
*
* NOTE: TAX TYPE 2 - USE TAX IS NOT INCLUDED IN THE TOTALS. 
* 
****************************/

SELECT TOP 100 PERCENT
        a.SLCo,
        a.SL,
        
        ---- SUBCONTRACT TOTALS FROM SL
        CAST(ISNULL(SUM(SLTOTAL.SLTotal), 0)			AS NUMERIC(18,2)) AS SLTotal,
        CAST(ISNULL(SUM(SLTOTAL.SLTotalCurrTax), 0)		AS NUMERIC(18,2)) AS SLTotalCurrTax,
        CAST(ISNULL(SUM(SLTOTAL.SLTotalOrig), 0)		AS NUMERIC(18,2)) AS SLTotalOrig,
		CAST(ISNULL(SUM(SLTOTAL.SLTotalOrigTax), 0)		AS NUMERIC(18,2)) AS SLTotalOrigTax,
		
		---- SUBCONTRACT TOTALS FROM PM FOR DETAIL NOT INTERFACED
		CAST(ISNULL(SUM(PMTOTAL.PMSLAmt), 0)			AS NUMERIC(18,2)) AS PMSLAmt,
		CAST(ISNULL(SUM(PMTOTAL.PMSLTaxAmt), 0)			AS NUMERIC(18,2)) AS PMSLTaxAmt,
		CAST(ISNULL(SUM(PMTOTAL.PMSLAmtOrig), 0)		AS NUMERIC(18,2)) AS PMSLAmtOrig,
		CAST(ISNULL(SUM(PMTOTAL.PMSLTaxOrig), 0)		AS NUMERIC(18,2)) AS PMSLTaxOrig,
		
		---- SUBCONTRACT MAXIMUM RETG AMOUNT BY PERCENT
		CAST(ISNULL(PMTOTAL.MaxRetgByPct, 0)			AS NUMERIC(18,2)) as MaxRetgByPct,
		
		---- SUMMARY TOTALS OF SL AND PM
		CAST(ISNULL(SLTOTAL.SLTotalOrig, 0)		+ ISNULL(SUM(PMTOTAL.PMSLAmt), 0)		AS NUMERIC(18,2)) AS TotalOrigSL,
		CAST(ISNULL(SLTOTAL.SLTotal, 0)			+ ISNULL(SUM(PMTOTAL.PMSLAmt), 0)		AS NUMERIC(18,2)) AS TotalCurrSL,
		CAST(ISNULL(SLTOTAL.SLTotalOrigTax, 0)	+ ISNULL(SUM(PMTOTAL.PMSLTaxOrig), 0)	AS NUMERIC(18,2)) AS TotalOrigTax,
		CAST(ISNULL(SLTOTAL.SLTotalCurrTax, 0)	+ ISNULL(SUM(PMTOTAL.PMSLTaxAmt), 0)	AS NUMERIC(18,2)) AS TotalCurrTax,
		
        [PMSLExists]		= CASE WHEN EXISTS (SELECT 1
												FROM dbo.bPMSL x
                                                WHERE	x.SLCo = a.SLCo
														AND x.SL = a.SL
														AND x.SLItem IS NOT NULL
														AND x.InterfaceDate IS NULL)
												THEN 'Y' ELSE 'N' END,
												
		[SortOrder]			= CASE WHEN a.[Status] = 3 THEN 'A'
                                             WHEN a.[Status] = 0 THEN 'B'
                                             WHEN a.[Status] = 1 THEN 'C'
                                             ELSE 'D' END
                                             


FROM dbo.bSLHD a WITH (NOLOCK)

        OUTER APPLY ( SELECT    SLTotal			= ISNULL(SUM(b.CurCost), 0),
                                SLTotalOrig		= ISNULL(SUM(CASE WHEN b.ItemType IN (1,4) THEN b.OrigCost ELSE 0 END), 0),
								SLTotalOrigTax	= ISNULL(SUM(b.OrigTax),0),
								SLTotalCurrTax	= ISNULL(SUM(b.CurTax),0)
                      FROM      dbo.bSLIT b WITH ( NOLOCK )
                      WHERE     b.SLCo = a.SLCo
                                AND b.SL = a.SL
                                AND b.ItemType IN (1,2,4)
                      GROUP BY  b.SLCo,
                                b.SL
                    ) SLTOTAL


	----- TABLE FUNCTION APPLIED FOR PM SUBCONTRACT AMOUNTS
	CROSS APPLY dbo.vfPMSLHeaderAmounts(a.SLCo, a.SL) PMTOTAL


GROUP BY	a.SLCo,
			a.SL,
			SLTotal,
			SLTotalOrig,
			SLTotalOrigTax,
			SLTotalCurrTax,
			a.[Status],
			PMTOTAL.MaxRetgByPct
			
ORDER BY    a.SLCo,
			a.SL









GO
GRANT SELECT ON  [dbo].[PMSLTotal] TO [public]
GRANT INSERT ON  [dbo].[PMSLTotal] TO [public]
GRANT DELETE ON  [dbo].[PMSLTotal] TO [public]
GRANT UPDATE ON  [dbo].[PMSLTotal] TO [public]
GRANT SELECT ON  [dbo].[PMSLTotal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMSLTotal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMSLTotal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMSLTotal] TO [Viewpoint]
GO
