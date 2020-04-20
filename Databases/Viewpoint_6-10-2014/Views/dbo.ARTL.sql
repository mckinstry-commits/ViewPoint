SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARTL] as select a.* From bARTL a
GO
GRANT SELECT ON  [dbo].[ARTL] TO [public]
GRANT INSERT ON  [dbo].[ARTL] TO [public]
GRANT DELETE ON  [dbo].[ARTL] TO [public]
GRANT UPDATE ON  [dbo].[ARTL] TO [public]
GRANT SELECT ON  [dbo].[ARTL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARTL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARTL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARTL] TO [Viewpoint]
GO
