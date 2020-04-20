SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMTrip] as select a.* From vSMTrip a
GO
GRANT SELECT ON  [dbo].[SMTrip] TO [public]
GRANT INSERT ON  [dbo].[SMTrip] TO [public]
GRANT DELETE ON  [dbo].[SMTrip] TO [public]
GRANT UPDATE ON  [dbo].[SMTrip] TO [public]
GRANT SELECT ON  [dbo].[SMTrip] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMTrip] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMTrip] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMTrip] TO [Viewpoint]
GO
