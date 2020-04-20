SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   View [dbo].[brvJCDailyCost]
    
    as
    
    /***
     Usage: View selects both summarized and detail costs from JCCP and JCCD, respectively
            Useful for reports that need cost information through a particular month and for 
            a given date range.    
            View used by JC Daily Cost by Cost Type Template
    ****/
    
    /***********
      Cost Period.  PostedDate and ActualDate set to 12/31/2050 so that reports select all cost summary records after 
       a beginning date report parameter.
    ************/
    
    select JCCP.JCCo, JCCP.Job, JCCP.Phase, JCCP.CostType, RecordType='CP', /*Cost Period*/ JCCH.UM, PhaseUnitFlag, CPMonth=JCCP.Mth, CDMonth='1/1/1950', CostTrans=0, ActualDate='12/31/2050', PostedDate='12/31/2050',    
           JCCP.ActualHours, JCCP.ActualUnits, JCCP.ActualCost, JCCP.OrigEstHours, JCCP.OrigEstUnits, JCCP.OrigEstCost,
           JCCP.CurrEstHours, JCCP.CurrEstUnits, JCCP.CurrEstCost, JCCP.ProjHours, JCCP.ProjUnits, JCCP.ProjCost,
           JCCP.ForecastHours, JCCP.ForecastUnits, JCCP.ForecastCost, JCCP.TotalCmtdUnits, JCCP.TotalCmtdCost,
           JCCP.RemainCmtdUnits, JCCP.RemainCmtdCost, JCCP.RecvdNotInvcdUnits, JCCP.RecvdNotInvcdCost
    From JCCP
    Join JCCH on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCCP.Job and JCCH.PhaseGroup=JCCP.PhaseGroup and JCCH.Phase=JCCP.Phase and JCCH.CostType=JCCP.CostType
    
    UNION ALL
    
    /***********
     Cost Detail.  Recommended that reports restrict information between a beginning date and ending month
    ************/
    
    select JCCD.JCCo, JCCD.Job, JCCD.Phase, JCCD.CostType, RecordType='CD', /*Cost Detail*/ JCCD.UM, PhaseUnitFlag, CPMonth='1/1/1950', JCCD.Mth, JCCD.CostTrans, JCCD.ActualDate, JCCD.PostedDate,
           JCCD.ActualHours, JCCD.ActualUnits, JCCD.ActualCost, 0, 0, 0,
           JCCD.EstHours, JCCD.EstUnits, JCCD.EstCost, JCCD.ProjHours, JCCD.ProjUnits, JCCD.ProjCost, 
           JCCD.ForecastHours, JCCD.ForecastUnits, JCCD.ForecastCost, JCCD.TotalCmtdUnits, JCCD.TotalCmtdCost,
           JCCD.RemainCmtdUnits, JCCD.RemainCmtdCost, 0, 0
    From JCCD
    Join JCCH on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.Phase=JCCD.Phase and JCCH.CostType=JCCD.CostType

GO
GRANT SELECT ON  [dbo].[brvJCDailyCost] TO [public]
GRANT INSERT ON  [dbo].[brvJCDailyCost] TO [public]
GRANT DELETE ON  [dbo].[brvJCDailyCost] TO [public]
GRANT UPDATE ON  [dbo].[brvJCDailyCost] TO [public]
GO
