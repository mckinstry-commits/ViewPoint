SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRCT] as select a.* From bHRCT a

GO
GRANT SELECT ON  [dbo].[HRCT] TO [public]
GRANT INSERT ON  [dbo].[HRCT] TO [public]
GRANT DELETE ON  [dbo].[HRCT] TO [public]
GRANT UPDATE ON  [dbo].[HRCT] TO [public]
GRANT SELECT ON  [dbo].[HRCT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRCT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRCT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRCT] TO [Viewpoint]
GO
