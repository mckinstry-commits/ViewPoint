SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMAdvancedLaborRate] as select a.* From vSMAdvancedLaborRate a
GO
GRANT SELECT ON  [dbo].[SMAdvancedLaborRate] TO [public]
GRANT INSERT ON  [dbo].[SMAdvancedLaborRate] TO [public]
GRANT DELETE ON  [dbo].[SMAdvancedLaborRate] TO [public]
GRANT UPDATE ON  [dbo].[SMAdvancedLaborRate] TO [public]
GRANT SELECT ON  [dbo].[SMAdvancedLaborRate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAdvancedLaborRate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAdvancedLaborRate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAdvancedLaborRate] TO [Viewpoint]
GO
