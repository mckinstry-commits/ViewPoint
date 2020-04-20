SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[vf_rptJCEstRevenue]
    (
      @JCCo INT,
      @Contract VARCHAR(30),
      @Item VARCHAR(30),
      @Mth SMALLDATETIME
    )

/**************
 Created By:  DH 7/6/11  D-02251
 Modified By: DH 7/8/11  D-02251.  Added Units for JC Projections - Revenue
				AR 1/10/2012 - TK-11655- Creating a Inline Table Function for better perf.
 
 Function returns Estimated Revenue calculated by month (EstRevenueMth) for 
 the Estimated Revenue At Completion shown on various JC Reports.  Function returns 
 a table that is applied in the brvJCCostRevenue, brvJCCostRevenueOverride, ,brvJCContStat, 
 brvJCCostRevFY views used by the various JC Work in Progress reports and the
 JC Contract Status Report.  Information selected from JCIP (JC Item Revenue by Month).
 
 EstRevenueMth = Estimated Revenue JTD - Estimated Revenue Previous
 
	Estimated Revenue JTD = if Projected Dollars to Date <> 0 or ProjPlug = Y 
							then Projected Dollars To Date
							else Contract Amount To Date
	
	Estimated Revenue Previous = if Projected Dollars through previous Month <>0 or
							     ProjPlug in Previous Month = Y then Projected Dollars through 
							     previous month
							     else Contract Amount through previous month.							
							
							   
 INPUT PARAMETERS 
	@JCCo  -JC Company
	@Contract
	@Item  --Contract Item
	@Mth							   	 		

***************/
RETURNS TABLE
 AS RETURN
    (
 
 WITH   cteLastMth ( LastProjMth, LastProjMthPrevious )
          AS ( SELECT   LastProjMth = MAX(JCID.Mth),
                        LastProjMthPrevious = MAX(CASE WHEN Mth < @Mth
                                                       THEN Mth
                                                  END)
               FROM     dbo.JCID
               WHERE    JCCo = @JCCo
                        AND Contract = @Contract
                        AND Item = @Item
                        AND Mth <= @Mth
                        AND TransSource = 'JC RevProj'
             ),
        cteJCIPSum ( ProjDollars_JTD, ProjUnits_JTD, ContractAmt_JTD, ContractUnits_JTD, ProjDollars_Previous, ProjUnits_Previous, ContractAmt_Previous, ContractUnits_Previous, ProjPlug, ProjPlug_Previous )
          AS ( SELECT   ProjDollars_JTD = SUM(ProjDollars),
                        ProjUnits_JTD = SUM(ProjUnits),
                        ContractAmt_JTD = SUM(ContractAmt),
                        ContractUnits_JTD = SUM(ContractUnits),
                        ProjDollars_Previous = SUM(CASE WHEN Mth < @Mth /*Mth<=dateadd(month,@DateAdd,@Mth)*/
                                                        THEN ProjDollars
                                                        ELSE 0
                                                   END),
                        ProjUnits_Previous = SUM(CASE WHEN Mth < @Mth /*Mth<=dateadd(month,@DateAdd,@Mth)*/
                                                      THEN ProjUnits
                                                      ELSE 0
                                                 END),
                        ContractAmt_Previous = SUM(CASE WHEN Mth < @Mth /*Mth<=dateadd(month,@DateAdd,@Mth)*/
                                                        THEN ContractAmt
                                                        ELSE 0
                                                   END),
                        ContractUnits_Previous = SUM(CASE WHEN Mth < @Mth /*Mth<=dateadd(month,@DateAdd,@Mth)*/
                                                          THEN ContractUnits
                                                          ELSE 0
                                                     END),
                        ProjPlug = MAX(CASE WHEN JCIP.Mth = LastMth.LastProjMth
                                            THEN JCIP.ProjPlug
                                            ELSE 'N'
                                       END),
                        ProjPlug_Previous = MAX(CASE WHEN JCIP.Mth = LastMth.LastProjMthPrevious/*=dateadd(month,@DateAdd,@Mth)*/
                                                     THEN JCIP.ProjPlug
                                                     ELSE 'N'
                                                END)
               FROM     dbo.JCIP
                        CROSS JOIN cteLastMth AS LastMth
               WHERE    JCIP.JCCo = @JCCo
                        AND JCIP.[Contract] = @Contract
                        AND JCIP.Item = @Item
                        AND JCIP.Mth <= @Mth
             )
    SELECT  ProjDollars_JTD AS ProjDollars_JobToDate,
            ProjUnits_JTD AS ProjUnits_JobToDate,
            ContractAmt_JTD AS ContractAmt_JobToDate,
            ContractUnits_JTD AS ContractUnits_JobToDate,
            EstRevenue_Previous = CASE WHEN ProjDollars_Previous <> 0
                                            OR ProjPlug_Previous = 'Y'
                                       THEN ProjDollars_Previous
                                       ELSE ContractAmt_Previous
                                  END,
            EstUnits_Previous = CASE WHEN ProjUnits_Previous <> 0
                                          OR ProjPlug_Previous = 'Y'
                                     THEN ProjUnits_Previous
                                     ELSE ContractUnits_Previous
                                END,
            EstUnits_Mth = CASE WHEN ProjUnits_JTD <> 0
                                     OR ProjPlug = 'Y' THEN ProjUnits_JTD
                                ELSE ContractUnits_JTD
                           END
						- CASE WHEN ProjUnits_Previous <> 0
									OR ProjPlug_Previous = 'Y' THEN ProjUnits_Previous
							   ELSE ContractUnits_Previous
						  END,
            EstRevenue_Mth = CASE WHEN ProjDollars_JTD <> 0
                                       OR ProjPlug = 'Y' THEN ProjDollars_JTD
                                  ELSE ContractAmt_JTD
                             END
							- CASE WHEN ProjDollars_Previous <> 0
										OR ProjPlug_Previous = 'Y' THEN ProjDollars_Previous
								   ELSE ContractAmt_Previous
							  END
    FROM    cteJCIPSum
)
GO
GRANT SELECT ON  [dbo].[vf_rptJCEstRevenue] TO [public]
GO
