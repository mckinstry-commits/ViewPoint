SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvJCProductionCalc]
AS

-- JC Production Calc
-- If using a user memo to indicate which jobs to send to Powertrack
-- and that is the only use of the JC Production Calc View, then add a 
-- restriciton by the user memo to the View.  If JC Production Calc is 
-- used in other places as well, add the retriction here.

SELECT * 

FROM JCProductionCalcs p with (nolock)
-- inner join JCJM WITH (NOLOCK)ON p.JCCo=JCJM.JCCo and p.Job=JCJM.Job
-- Where JCJM.udPT='Y'

GO
GRANT SELECT ON  [dbo].[ptvJCProductionCalc] TO [public]
GRANT INSERT ON  [dbo].[ptvJCProductionCalc] TO [public]
GRANT DELETE ON  [dbo].[ptvJCProductionCalc] TO [public]
GRANT UPDATE ON  [dbo].[ptvJCProductionCalc] TO [public]
GRANT SELECT ON  [dbo].[ptvJCProductionCalc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvJCProductionCalc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvJCProductionCalc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvJCProductionCalc] TO [Viewpoint]
GO
