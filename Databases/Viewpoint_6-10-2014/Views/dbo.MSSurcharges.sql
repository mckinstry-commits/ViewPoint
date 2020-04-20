SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















CREATE view [dbo].[MSSurcharges] as select a.* From bMSSurcharges a
















GO
GRANT SELECT ON  [dbo].[MSSurcharges] TO [public]
GRANT INSERT ON  [dbo].[MSSurcharges] TO [public]
GRANT DELETE ON  [dbo].[MSSurcharges] TO [public]
GRANT UPDATE ON  [dbo].[MSSurcharges] TO [public]
GRANT SELECT ON  [dbo].[MSSurcharges] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSSurcharges] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSSurcharges] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSSurcharges] TO [Viewpoint]
GO
