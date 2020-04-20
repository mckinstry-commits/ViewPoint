SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[JCProductionCalcs]
AS
    /*********************************************
  *	Created by	ROBH  01/15/05
  *  Modified	JRE 08/10/05 - performance, combine group by's
  *				GG 10/04/05 - #29539 - correct unit based calculations
				AR 06/20/2011 - TK-06186 - refactoring for better performance
  *
  *  This view is used to retrieve Job, Phase productivity data - primarily for export to 3rd party packages. 
  *	Unit based production calculations based on Phase Units (JCCH.PhaseUnitFlag = 'Y')
  *	Hours hardcoded for Labor Cost type = 1.  If this is not the case modify the appropriate queries.
  *
  *  Comment or uncomment section to return the desired set of data
  *
  *	Tables:
  *		P	JCCP
  *		N	JCJP
  *		M	JCJM
  *		U	JCCP
  *		
  **********************************************/
    SELECT  JCJP.JCCo ,
            JCJP.Job ,
            JCJP.Phase ,
            JCJP.Description ,
  
  -- Original Estimated Amounts
            ISNULL([Orig Est Hours], 0) AS 'Orig Est Hours' ,
  	--isnull[Orig Est Units],0) as 'Orig Est Units',
            ISNULL([Orig Est Phase Units], 0) AS 'Orig Est Phase Units' ,
            ISNULL([Orig Est Cost], 0) AS 'Orig Est Cost' ,
  	
  --Current Estimated Amounts
            ISNULL([Curr Est Hours], 0) AS 'Curr Est Hours' ,
  	--isnull[Curr Est Units],0) as 'Curr Est Units',
            ISNULL([Curr Est Phase Units], 0) AS 'Curr Est Phase Units' ,
            ISNULL([Curr Est Cost], 0) AS 'Curr Est Cost' ,
  
  -- Actual Amounts
            ISNULL([Actual Hours], 0) AS 'Actual Hours' ,
  	--isnull[Actual Units],0) as 'Actual Units',	-- all units w/o regard to JCCH.PhaseUnitFlag
            ISNULL([Actual Phase Units], 0) AS 'Actual Phase Units' ,	-- units where JCCH.PhaseUnitFlag = 'Y'
            ISNULL([Actual Cost], 0) AS 'Actual Cost' ,
  
  -- Total Committed Amounts
  	--isnull([Total Cmtd Units],0) as 'Total Cmtd Units',
  	--isnull([Total Cmtd Phase Units],0) as 'Total Cmtd Phase Units',
  	--isnull([Total Cmtd Cost],0) as 'Total Cmtd Cost',
  
  
  -- Remaining Committed Amounts
  	--isnull([Remain Cmtd Units],0) as 'Remain Cmtd Units',
  	--isnull([Remain Cmtd Phase Units],0) as 'Remain Cmtd Phase Units',
  	--isnull([Remain Cmtd Cost],0) as 'Remain Cmtd Cost',
  
  -- Forecast Amounts
  	-- isnull([Forecast Hours],0) as 'Forecast Hours',
  	-- isnull([Forecast Units],0) as 'Forecast Units',
  	-- isnull([Forecast PhaseUnits],0) as 'Forecast PhaseUnits',
  	-- isnull([Forecast Cost],0) as 'Forecast Cost',
  
  -- Projected Amounts
  	-- isnull([Proj Hours],0) as 'Proj Hours',
  	-- isnull([Proj Units],0) as 'Proj Units',
  	-- isnull([Proj PhaseUnits],0) as 'Proj PhaseUnits',
  	-- isnull([Proj Cost],0) as 'Proj Cost',
  
   
  -- Estimated Units/Hour                      		
            CASE ISNULL([Curr Est Hours], 0)
              WHEN 0 THEN 0
              ELSE ISNULL([Curr Est Phase Units], 0) / ISNULL([Curr Est Hours],
                                                              0) 	-- #29539 use estimated phase units
            END AS 'Est Units/Hr' , 
  
  -- Actual Units/Hour
            CASE ISNULL([Actual Hours], 0)
              WHEN 0 THEN 0
              ELSE ISNULL([Actual Phase Units], 0) / ISNULL([Actual Hours], 0) -- #29539 use actual phase units
            END AS 'Actual Units/Hr' , 
  
  
  -- Estimated Cost/Hour
            CASE ISNULL([Curr Est Hours], 0)
              WHEN 0 THEN 0
              ELSE ISNULL([Curr Est Cost], 0) / ISNULL([Curr Est Hours], 0)
            END AS 'Est Cost/Hr' ,
  
  -- Actual Cost/Hour
            CASE ISNULL([Actual Hours], 0)
              WHEN 0 THEN 0
              ELSE ISNULL([Actual Cost], 0) / ISNULL([Actual Hours], 0)
            END AS 'Actual Cost/Hr' ,
  
  -- Estimated Cost/Unit
            CASE ISNULL([Curr Est Phase Units], 0)
              WHEN 0 THEN 0
              ELSE ISNULL([Curr Est Cost], 0) / ISNULL([Curr Est Phase Units],
                                                       0) 	-- #29539 use estimated cost
            END AS 'Est Cost/Unit' ,
  
  -- Actual Cost/Unit
            CASE ISNULL([Actual Phase Units], 0)	-- #29539 use estimated phase units
              WHEN 0 THEN 0
              ELSE ISNULL([Actual Cost], 0) / ISNULL([Actual Phase Units], 0)	-- #29539 use estimated phase units
            END AS 'Actual Cost/Unit' ,
  
  -- % Complete Units
            CASE ISNULL([Curr Est Phase Units], 0)
              WHEN 0 THEN 0
              ELSE ( ISNULL([Actual Phase Units], 0)
                     / ISNULL([Curr Est Phase Units], 0) ) * 100	-- #29539 use estimated phase units
            END AS '% Comp Units' ,
  
  -- % Complete Hours
            CASE ISNULL([Curr Est Hours], 0)
              WHEN 0 THEN 0
              ELSE ( ISNULL([Actual Hours], 0) / ISNULL([Curr Est Hours], 0) )
                   * 100
            END AS '% Comp Hrs' ,
  
  -- % Complete Cost
            CASE ISNULL([Curr Est Cost], 0)
              WHEN 0 THEN 0
              ELSE ( ISNULL([Actual Cost], 0) / ISNULL([Curr Est Cost], 0) )
                   * 100
            END AS '% Comp Cost'  
  
  
  --- tables 
    FROM    bJCJP JCJP WITH ( NOLOCK )
            JOIN ( SELECT   U.JCCo ,
                            U.Job ,
                            U.Phase
  
 
  -- Original Estimated Amounts
                            ,
                            SUM(CASE WHEN U.CostType = 1 THEN U.OrigEstHours
                                     ELSE 0
                                END) AS 'Orig Est Hours' ,
                            SUM(U.OrigEstUnits) AS 'Orig Est Units' ,
                            SUM(CASE WHEN H.PhaseUnitFlag = 'Y'
                                     THEN U.OrigEstUnits
                                     ELSE 0
                                END) AS 'Orig Est Phase Units' -- Orignal Estiamted Units
                            ,
                            SUM(U.OrigEstCost) AS 'Orig Est Cost'
  
  -- Current Estimated Amounts
                            ,
                            SUM(CASE WHEN U.CostType = 1 THEN U.CurrEstHours
                                     ELSE 0
                                END) AS 'Curr Est Hours' ,
                            SUM(U.CurrEstUnits) AS 'Curr Est Units' ,
                            SUM(CASE WHEN H.PhaseUnitFlag = 'Y'
                                     THEN U.CurrEstUnits
                                     ELSE 0
                                END) AS 'Curr Est Phase Units' ,
                            SUM(U.CurrEstCost) AS 'Curr Est Cost'
  
  -- actual amounts
                            ,
                            SUM(CASE WHEN U.CostType = 1 THEN U.ActualHours
                                     ELSE 0
                                END) AS 'Actual Hours' ,
                            SUM(U.ActualUnits) AS 'Actual Units' ,
                            SUM(CASE WHEN H.PhaseUnitFlag = 'Y'
                                     THEN U.ActualUnits
                                     ELSE 0
                                END) AS 'Actual Phase Units' ,
                            SUM(U.ActualCost) AS 'Actual Cost'
  
  -- Total Committed Amounts
  /*
 	,sum(U.TotalCmtdUnits) as 'Total Cmtd Units'
  	,sum(CASE WHEN H.PhaseUnitFlag='Y' THEN U.TotalCmtdUnits ELSE 0 END) as 'Total Cmtd Phase Units'
  	,sum(U.TotalCmtdCost) as 'Total Cmtd Cost'
 */
  
  -- remaining Committed Amounts
 /*
  	,sum(U.RemainCmtdUnits) as 'Remain Cmtd Units'
  	,sum(CASE WHEN H.PhaseUnitFlag='Y' THEN U.RemainCmtdUnits ELSE 0 END) as 'Remain Cmtd Phase Units'
  	,sum(U.RemainCmtdCost) as 'Remain Cmtd Cost'
 */
  
  -- Forecast Amounts
 /*
  	,sum(CASE WHEN U.CostType=1 THEN U.ForecastHours ELSE 0 END) AS 'Forecast Hours'
  	,sum(U.ForecastUnits) as 'Forecast Units'
  	,sum(CASE WHEN H.PhaseUnitFlag='Y' THEN U.ForecastUnits ELSE 0 END) AS 'Forecast PhaseUnits'
  	,sum(U.ForecastCost) as 'Forecast Cost'
 */ 
  	
  -- Projected Amounts
 /*
  	,sum(CASE WHEN U.CostType=1 THEN U.ProjHours ELSE 0 END) AS 'Proj Hours'
  	,sum(U.ProjUnits) as 'Proj Units'
  	,sum(CASE WHEN H.PhaseUnitFlag='Y' THEN U.ProjUnits ELSE 0 END) AS 'Proj PhaseUnits'
  	,sum(U.ProjCost) as 'Proj Cost'
 */
                   FROM     dbo.bJCCP U WITH ( NOLOCK )
                            JOIN dbo.bJCCH H WITH ( NOLOCK ) ON U.JCCo = H.JCCo
                                                              AND U.Job = H.Job
                                                              AND U.PhaseGroup = H.PhaseGroup
                                                              AND U.Phase = H.Phase
                                                              AND U.CostType = H.CostType
                   GROUP BY U.JCCo ,
                            U.Job ,
                            U.Phase
                 ) AS JCCPSum ON JCCPSum.JCCo = JCJP.JCCo
                                 AND JCCPSum.Job = JCJP.Job
                                 AND JCCPSum.Phase = JCJP.Phase
            JOIN dbo.bJCJM JCJM WITH ( NOLOCK ) ON JCJP.JCCo = JCJM.JCCo
                                                   AND JCJP.Job = JCJM.Job
            CROSS APPLY ( SELECT TOP 1
                                    1 AS ISPresent
                          FROM      dbo.bJCCP WITH ( NOLOCK )
                          WHERE     bJCCP.JCCo = JCJP.JCCo
                                    AND bJCCP.Job = JCJP.Job
                                    AND bJCCP.Phase = JCJP.Phase
                        ) AS JCCPVaild
    WHERE   JCCPVaild.ISPresent = 1
            AND JCJM.JobStatus = 1	-- open jobs only

GO
GRANT SELECT ON  [dbo].[JCProductionCalcs] TO [public]
GRANT INSERT ON  [dbo].[JCProductionCalcs] TO [public]
GRANT DELETE ON  [dbo].[JCProductionCalcs] TO [public]
GRANT UPDATE ON  [dbo].[JCProductionCalcs] TO [public]
GO
