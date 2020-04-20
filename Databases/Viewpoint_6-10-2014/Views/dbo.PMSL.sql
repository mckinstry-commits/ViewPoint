SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMSL] as select a.* From bPMSL a
GO
GRANT SELECT ON  [dbo].[PMSL] TO [public]
GRANT INSERT ON  [dbo].[PMSL] TO [public]
GRANT DELETE ON  [dbo].[PMSL] TO [public]
GRANT UPDATE ON  [dbo].[PMSL] TO [public]
GRANT SELECT ON  [dbo].[PMSL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMSL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMSL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMSL] TO [Viewpoint]
GO
