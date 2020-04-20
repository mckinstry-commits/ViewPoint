SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/******************************/
CREATE view [dbo].[PMPOTotal] as
/*****************************
* Created By:	??
* Modified By:	GG 04/10/08 - added top 100 percent and order by
*				GF 03/15/2010 - issue #120252 - PO distribution
*				GF 04/29/2010 - issue #138434 added PCO to PM totals
*				GF 11/10/2010 - ISSUE #142080 TOP 1 from PMFM
*				GF 02/01/2011 - issue #143199 add outer apply for performance
*				GF 04/09/2012 TK-13886 #145504 get PMMF original amount and tax for inclusion on totals
*
*
* Displays total original and current PO amounts in PMPOHeader
*
********************************/


SELECT TOP 100 PERCENT
        a.POCo,
        a.PO,
        [POTotal]       = ISNULL(POTotal, 0),
        [POTotalOrig]   = ISNULL(POTotalOrig, 0),
        [PMPOAmt]       = ISNULL(SUM(PMPOAmt), 0)
        ----TK-13886
        ,[PMPOAmtOrig]		= ISNULL(SUM(PMPOAmtOrig), 0)
        ,[POTotalTax]		= ISNULL(POTotalTax,0)
        ,[POTotalOrigTax]	= ISNULL(POTotalOrigTax,0)
        ,[PMPOAmtTax]		= ISNULL(SUM(PMPOAmtTax),0)
        ,[PMPOAmtOrigTax]	= ISNULL(SUM(PMPOAmtOrigTax),0)
        ,[PMPOExists]    = CASE WHEN EXISTS (  SELECT    1
                                                                    FROM      dbo.bPMMF x WITH ( NOLOCK )
                                                                    WHERE     x.POCo = a.POCo
                                                                                    AND x.PO = a.PO
                                                                                    AND x.POItem IS NOT NULL
                                                                                    AND x.InterfaceDate IS NULL
                                                                                    AND x.MaterialOption = 'P' )
                            THEN 'Y'
                            ELSE 'N'
                                    END,
      [SortOrder]       = CASE WHEN a.[Status] = 3 THEN 'A'
                                             WHEN a.[Status] = 0 THEN 'B'
                                             WHEN a.[Status] = 1 THEN 'C'
                                             ELSE 'D'
                                      END,
		----TK-13886
        [TotalOrigPO]   = ISNULL(POTotalOrig, 0) + ISNULL(POTotalOrigTax,0) + ISNULL(SUM(PMPOAmtOrig), 0) + ISNULL(SUM(PMPOAmtOrigTax),0)
        ,[TotalCurrPO]   = ISNULL(POTotal, 0) + ISNULL(POTotalTax,0) + ISNULL(SUM(PMPOAmt), 0) + ISNULL(SUM(PMPOAmtTax),0)
        ----120252
        ,[VendorFirm]    = ISNULL(CONVERT(varchar(10), MIN(f.FirmNumber)), '')
            ----120252
FROM    dbo.bPOHD a WITH ( NOLOCK ) ----120252

        OUTER APPLY ( SELECT TOP (1)
                                f.FirmNumber
                      FROM      dbo.bPMFM f WITH ( NOLOCK )
                      WHERE     f.VendorGroup = a.VendorGroup
                                AND f.Vendor = a.Vendor
                    ) f
        OUTER APPLY ( SELECT    PMPOAmt = ISNULL(SUM(c.Amount), 0)
								----TK-13886
								,PMPOAmtTax = CASE WHEN c.TaxCode IS NULL THEN 0
												   WHEN c.TaxType IN (2,3) THEN 0
											  ELSE ISNULL(ROUND(ISNULL(SUM(c.Amount), 0) * ISNULL(dbo.vfHQTaxRate(c.TaxGroup, c.TaxCode, GetDate()),0),2),0)
											  END
								,PMPOAmtOrig = ISNULL(SUM(CASE WHEN c.POCONum IS NULL THEN c.Amount ELSE 0 END), 0)
								,PMPOAmtOrigTax = CASE WHEN c.POCONum IS NULL THEN
																	CASE WHEN c.TaxCode IS NULL THEN 0
																		 WHEN c.TaxType IN (2,3) THEN 0
																	ELSE ISNULL(ROUND(ISNULL(SUM(c.Amount), 0) * ISNULL(dbo.vfHQTaxRate(c.TaxGroup, c.TaxCode, GetDate()),0),2),0)
																	END
												  ELSE 0 END
								
                      FROM      dbo.bPMMF c WITH ( NOLOCK )
                      WHERE     c.SendFlag = 'Y'
                                AND c.InterfaceDate IS NULL
                                AND c.MaterialOption = 'P'
                                AND c.POItem IS NOT NULL
                                AND ( ( c.RecordType = 'O'
                                        AND c.ACO IS NULL
                                      )
                                      OR ( c.RecordType = 'C'
                                           AND ( c.ACO IS NOT NULL
                                                 OR c.PCO IS NOT NULL
                                               )
                                         )
                                    )
                                AND c.POCo = a.POCo
                                AND c.PO = a.PO
                      GROUP BY  c.POCo,
                                c.PO,
                                c.SendFlag,
                                c.InterfaceDate,
                                c.RecordType,
                                c.MaterialOption,
                                c.ACO
                                ----TK-13886
                                ,c.POCONum
                                ,c.TaxCode
                                ,c.TaxType
                                ,c.TaxGroup
                    ) pm

        OUTER APPLY ( SELECT    POTotal = ISNULL(SUM(b.CurCost), 0),
                                POTotalOrig = ISNULL(SUM(b.OrigCost), 0)
                                ----TK-13886
                                ,POTotalTax = ISNULL(SUM(b.CurTax),0)
                                ,POTotalOrigTax = ISNULL(SUM(b.OrigTax),0)
                      FROM      dbo.bPOIT b WITH ( NOLOCK )
                      WHERE     b.POCo = a.POCo
                                AND b.PO = a.PO
                      GROUP BY  b.POCo,
                                b.PO
                    ) po

GROUP BY    a.POCo,
                  a.PO,
                  ISNULL(POTotal, 0),
                  ISNULL(POTotalOrig, 0)
                  ----TK-13886
                  ,ISNULL(POTotalTax,0)
                  ,ISNULL(POTotalOrigTax,0)
                  ,a.[Status]
ORDER BY    a.POCo,
                  a.PO









GO
GRANT SELECT ON  [dbo].[PMPOTotal] TO [public]
GRANT INSERT ON  [dbo].[PMPOTotal] TO [public]
GRANT DELETE ON  [dbo].[PMPOTotal] TO [public]
GRANT UPDATE ON  [dbo].[PMPOTotal] TO [public]
GO
