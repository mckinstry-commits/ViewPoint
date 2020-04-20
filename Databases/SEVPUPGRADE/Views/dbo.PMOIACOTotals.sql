SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[PMOIACOTotals]
AS
    /*****************************************
* Created:	GF 11/16/2005 6.x only
* Modfied:	GG 04/10/08 - added top 100 percent and order by
*			GF 12/20/2008 - issue #129669 - addon cost based on cost type
*			GF 05/15/2010 - issue #138206 - fix for old add-ons not showing as cost
*			GF 02/28/2011 - issue #143378 - do not calculate approved add-ons from PCO
*			GF 02/09/2012 - issue #145831 performance changes recommended by ADAM R
*
*
* Provides a view of PM ACO Item Totals for 6.x
* Returns PCO Revenue, PCO Phase Cost, PCO Addon Cost,
* ACO Revenue, ACO Phase Cost, ACO Addon Cost for a
* PMCo, Project, ACO, ACOItem.
* Used to display totals in PM Approved Change Orders Form.
*
*****************************************/

SELECT TOP 100 PERCENT
        a.PMCo,
        a.Project,
        a.ACO,
        a.ACOItem,
        'PCOItemRevTotal' = ISNULL(( CASE a.FixedAmountYN
                                       WHEN 'Y' THEN a.FixedAmount
                                       ELSE a.PendingAmount
                                     END ), 0),
        'PCOItemPhaseCost' = ISNULL(( PCOItemPhaseCost ), 0),
        'PCOItemAddonCost' = ISNULL(( PCOItemAddonCost ), 0),
        'PCOItemAddonTotal' = ISNULL(( PCOItemAddonTotal ), 0),
        'ACOItemRevTotal' = ISNULL(a.ApprovedAmt, 0),
        'ACOItemPhaseCost' = ISNULL(( ACOItemPhaseCost ), 0),
        'ACOItemAddonCost' = 0,
        'ACOItemAddonTotal' = ISNULL(( ACOItemAddonTotal ), 0),
        'PCOMarkUpTotal' = ISNULL(( PCOMarkUpTotal ), 0),
        'PCOItemNetAddonTotal' = ISNULL(( PCOItemNetAddonTotal ), 0),
        'PCOItemSubAddonTotal' = ISNULL(( PCOItemSubAddonTotal ), 0),
        'PCOItemGrandAddonTotal' = ISNULL(( PCOItemGrandAddonTotal ), 0)
FROM    dbo.bPMOI a WITH ( NOLOCK ) ---- pending phase cost
        LEFT JOIN ( SELECT  d.PMCo,
                            d.Project,
                            d.ACO,
                            d.ACOItem,
                            PCOItemPhaseCost = ISNULL(SUM(d.EstCost), 0)
                    FROM    dbo.bPMOL d WITH ( NOLOCK )
                    WHERE   d.PCO IS NOT NULL
                            AND d.PCOItem IS NOT NULL
                    GROUP BY d.PMCo,
                            d.Project,
                            d.ACO,
                            d.ACOItem
                  ) pcocost ON pcocost.PMCo = a.PMCo
                               AND pcocost.Project = a.Project
                               AND pcocost.ACO = a.ACO
                               AND pcocost.ACOItem = a.ACOItem
	---- pending markup total
        LEFT JOIN ( SELECT  m.PMCo,
                            m.Project,
                            m.PCOType,
                            m.PCO,
                            m.PCOItem,
                            PCOMarkUpTotal = ROUND(SUM(m.IntMarkUpAmt)
                                                   + SUM(m.ConMarkUpAmt), 2)
                    FROM    PMOMTotals m WITH ( NOLOCK )
                    WHERE   m.PCO IS NOT NULL
                            AND m.PCOItem IS NOT NULL
                    GROUP BY m.PMCo,
                            m.Project,
                            m.PCOType,
                            m.PCO,
                            m.PCOItem
                  ) pcomarkup ON pcomarkup.PMCo = a.PMCo
                                 AND pcomarkup.Project = a.Project
                                 AND pcomarkup.PCOType = a.PCOType
                                 AND pcomarkup.PCO = a.PCO
                                 AND pcomarkup.PCOItem = a.PCOItem
	---- pending addon cost - addon cost type must not be empty to be considered cost
        LEFT JOIN ( SELECT  e.PMCo,
                            e.Project,
                            e.ACO,
                            e.ACOItem,
                            PCOItemAddonCost = ISNULL(SUM(f.AddOnAmount), 0)
                    FROM    dbo.bPMOA f WITH ( NOLOCK )
                            JOIN dbo.bPMOI e WITH ( NOLOCK ) ON e.PMCo = f.PMCo
                                                            AND e.Project = f.Project
                                                            AND e.PCOType = f.PCOType
                                                            AND e.PCO = f.PCO
                                                            AND e.PCOItem = f.PCOItem
                            JOIN dbo.bPMPA g WITH ( NOLOCK ) ON g.PMCo = f.PMCo
                                                            AND g.Project = f.Project
                                                            AND g.AddOn = f.AddOn
                                                            AND g.CostType IS NOT NULL
			----#138206
                    WHERE   e.PCO IS NOT NULL
                            AND e.PCOItem IS NOT NULL ----and e.ACOItem is null
                            AND NOT EXISTS ( SELECT 1
                                             FROM   dbo.bPMOL l WITH ( NOLOCK )
                                             WHERE  l.PMCo = e.PMCo
                                                    AND l.Project = e.Project
                                                    AND l.PCOType = e.PCOType
                                                    AND l.PCO = e.PCO
                                                    AND l.PCOItem = e.PCOItem
                                                    AND l.CostType = g.CostType
                                                    AND l.CreatedFromAddOn = 'Y' )
			----#138206
                    GROUP BY e.PMCo,
                            e.Project,
                            e.ACO,
                            e.ACOItem
                  ) pcocostadd ON pcocostadd.PMCo = a.PMCo
                                  AND pcocostadd.Project = a.Project
                                  AND pcocostadd.ACO = a.ACO
                                  AND pcocostadd.ACOItem = a.ACOItem
	---- pending addon total - same as above except ignore addon cost type
	--- let's do all the pending totals in this view with some case statements so we don't hit
	-- PMOA 4 times.
	-- we are isnulling above, why isnull here?
	-- let's outer apply this then we don't need grouping
        OUTER APPLY ( 
					SELECT  
                            PCOItemAddonTotal = SUM(f.AddOnAmount),
                            PCOItemNetAddonTotal = SUM(
														CASE WHEN f.TotalType = 'N' 
																THEN f.AddOnAmount
															ELSE 0.00
														END),
							PCOItemSubAddonTotal = SUM(
														CASE WHEN f.TotalType = 'S' 
																THEN f.AddOnAmount
															ELSE 0.00
														END),
							PCOItemGrandAddonTotal = SUM(
														CASE WHEN f.TotalType = 'G' 
																THEN f.AddOnAmount
															ELSE 0.00 
														END	)		
						FROM    dbo.bPMOA f WITH ( NOLOCK )
                            JOIN dbo.bPMOI e WITH ( NOLOCK ) ON e.PMCo = f.PMCo
                                                            AND e.Project = f.Project
                                                            AND e.PCOType = f.PCOType
                                                            AND e.PCO = f.PCO
                                                            AND e.PCOItem = f.PCOItem
                            JOIN dbo.bPMPA g WITH ( NOLOCK ) ON g.PMCo = f.PMCo
                                                            AND g.Project = f.Project
                                                            AND g.AddOn = f.AddOn
                   -- we don't need NOT NULL the JOIN ensures they aren't coming along
                   -- if we are trying to limit PMOI the optimizer should be seeing this
                   -- but either way the outer apply just took it out :)
                   WHERE e.PMCo = a.PMCo
						 AND e.Project = a.Project
						 AND e.ACO = a.ACO
						 AND e.ACOItem = a.ACOItem
                  ) pcoaddontotal

	---- approved phase cost
        LEFT JOIN ( SELECT  h.PMCo,
                            h.Project,
                            h.ACO,
                            h.ACOItem,
                            ACOItemPhaseCost = ISNULL(SUM(h.EstCost), 0)
                    FROM    dbo.bPMOL h WITH ( NOLOCK )
                    WHERE   h.ACO IS NOT NULL
                            AND h.ACOItem IS NOT NULL
                    GROUP BY h.PMCo,
                            h.Project,
                            h.ACO,
                            h.ACOItem
                  ) acocost ON acocost.PMCo = a.PMCo
                               AND acocost.Project = a.Project
                               AND acocost.ACO = a.ACO
                               AND acocost.ACOItem = a.ACOItem
	---- approved addon cost - addon cost type must not be empty to be considered cost
	-- 1 = 2 that is just noise we are never going to return rows, kill this section put a 0 in above

	---- approved addon total - same as above except ignore addon cost type
        LEFT JOIN ( SELECT  j.PMCo,
                            j.Project,
                            j.ACO,
                            j.ACOItem,
                            ACOItemAddonTotal = ISNULL(SUM(i.AddOnAmount), 0)
                    FROM    dbo.bPMOA i WITH ( NOLOCK )
                            JOIN dbo.bPMOI j WITH ( NOLOCK ) ON j.PMCo = i.PMCo
                                                            AND j.Project = i.Project
                                                            AND j.PCOType = i.PCOType
                                                            AND j.PCO = i.PCO
                                                            AND j.PCOItem = i.PCOItem
                                                            AND ISNULL(j.ACO,
                                                              '') <> ''
                            JOIN dbo.bPMPA k WITH ( NOLOCK ) ON k.PMCo = i.PMCo
                                                            AND k.Project = i.Project
                                                            AND k.AddOn = i.AddOn
                    WHERE   j.ACO IS NOT NULL
                            AND j.ACOItem IS NOT NULL
                    GROUP BY j.PMCo,
                            j.Project,
                            j.ACO,
                            j.ACOItem
                  ) acoaddontotal ON acoaddontotal.PMCo = a.PMCo
                                     AND acoaddontotal.Project = a.Project
                                     AND acoaddontotal.ACO = a.ACO
                                     AND acoaddontotal.ACOItem = a.ACOItem
WHERE   a.ACO IS NOT NULL
        AND a.ACOItem IS NOT NULL
--why would we GROUP? 
        
-- please stop ordering in views, you are going to cause table scans when this stuff is join too
-- depending on if the optimizer can throw it out
--ORDER BY a.PMCo,
--        a.Project,
--        a.ACO,
--        a.ACOItem








GO
GRANT SELECT ON  [dbo].[PMOIACOTotals] TO [public]
GRANT INSERT ON  [dbo].[PMOIACOTotals] TO [public]
GRANT DELETE ON  [dbo].[PMOIACOTotals] TO [public]
GRANT UPDATE ON  [dbo].[PMOIACOTotals] TO [public]
GO
