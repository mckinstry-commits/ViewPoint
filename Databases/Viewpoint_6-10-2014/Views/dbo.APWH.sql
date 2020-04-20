SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APWH] as select a.* From bAPWH a
GO
GRANT SELECT ON  [dbo].[APWH] TO [public]
GRANT INSERT ON  [dbo].[APWH] TO [public]
GRANT DELETE ON  [dbo].[APWH] TO [public]
GRANT UPDATE ON  [dbo].[APWH] TO [public]
GRANT SELECT ON  [dbo].[APWH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APWH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APWH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APWH] TO [Viewpoint]
GO
