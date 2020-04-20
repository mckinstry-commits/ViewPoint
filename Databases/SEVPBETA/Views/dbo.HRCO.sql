SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRCO] as select a.* From bHRCO a

GO
GRANT SELECT ON  [dbo].[HRCO] TO [public]
GRANT INSERT ON  [dbo].[HRCO] TO [public]
GRANT DELETE ON  [dbo].[HRCO] TO [public]
GRANT UPDATE ON  [dbo].[HRCO] TO [public]
GO
