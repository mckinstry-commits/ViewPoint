SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:
 * Modfied By:
 *
 * Provides a view of JC Job Phase cost header
 * with calculations. Used in PM Phase Cost Type
 * form.
 *
 *****************************************/
    
   -- -- -- ALTER     view dbo.JCCHPM as 
   -- -- -- select top 100 percent a.*,
   -- -- -- 	'HrsPerUnit' = case a.OrigUnits when 0 then OrigUnits else a.OrigHours/a.OrigUnits end,
   -- -- -- 	'CostPerHour' = case a.OrigHours when 0 then OrigHours else a.OrigCost/a.OrigHours end,
   -- -- -- 	'UnitCost' = case a.OrigUnits when 0 then OrigUnits else a.OrigCost/a.OrigUnits end,
   -- -- -- 	b.TrackHours
   -- -- -- from dbo.JCCH a
   -- -- -- left join dbo.JCCT b with (nolock) on b.PhaseGroup=a.PhaseGroup and b.CostType=a.CostType
   -- -- -- order by a.JCCo,a.Job,a.PhaseGroup,a.Phase,a.CostType
   
-- -- --    ALTER      view dbo.JCCHPM as select a.JCCo,a.Job,a.PhaseGroup,a.Phase,a.CostType,
-- -- --    	'HrsPerUnit' = case a.OrigUnits when 0 then OrigUnits else a.OrigHours/a.OrigUnits end,
-- -- --    	'CostPerHour' = case a.OrigHours when 0 then OrigHours else a.OrigCost/a.OrigHours end,
-- -- --    	'UnitCost' = case a.OrigUnits when 0 then OrigUnits else a.OrigCost/a.OrigUnits end,
-- -- --    	b.TrackHours
-- -- --    from JCCH a
-- -- --    left join JCCT b with (nolock) on b.PhaseGroup=a.PhaseGroup and b.CostType=a.CostType
   
   
/* 6.x only view below */
/*****************************************
 * Created By:	GF 07/25/2005 6.x only
 * Modfied By:
 *
 * Provides a view of JC Job Phase Cost Header for 6.x
 * Since PMProjectPhases form uses PMCo and Project, need to
 * alias JCCO as [PMCo] and Job as [Project] so that
 * JC Job Phase Cost Header can be on a related tab in 
 * PM Project Phases form.
 *
   ALTER view dbo.JCCHPM as 
   select a.JCCo as [PMCo], a.Job as [Project], a.*
   from dbo.JCCH a
   ********************************************/

   CREATE view [dbo].[JCCHPM] as 
   select a.JCCo as [PMCo], a.Job as [Project], a.*
   from dbo.JCCH a


GO
GRANT SELECT ON  [dbo].[JCCHPM] TO [public]
GRANT INSERT ON  [dbo].[JCCHPM] TO [public]
GRANT DELETE ON  [dbo].[JCCHPM] TO [public]
GRANT UPDATE ON  [dbo].[JCCHPM] TO [public]
GO
