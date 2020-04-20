SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APCT] as select a.* From bAPCT a
GO
GRANT SELECT ON  [dbo].[APCT] TO [public]
GRANT INSERT ON  [dbo].[APCT] TO [public]
GRANT DELETE ON  [dbo].[APCT] TO [public]
GRANT UPDATE ON  [dbo].[APCT] TO [public]
GRANT SELECT ON  [dbo].[APCT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APCT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APCT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APCT] TO [Viewpoint]
GO
