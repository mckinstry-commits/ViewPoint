SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRSX] as select a.* From bPRSX a
GO
GRANT SELECT ON  [dbo].[PRSX] TO [public]
GRANT INSERT ON  [dbo].[PRSX] TO [public]
GRANT DELETE ON  [dbo].[PRSX] TO [public]
GRANT UPDATE ON  [dbo].[PRSX] TO [public]
GRANT SELECT ON  [dbo].[PRSX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRSX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRSX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRSX] TO [Viewpoint]
GO
