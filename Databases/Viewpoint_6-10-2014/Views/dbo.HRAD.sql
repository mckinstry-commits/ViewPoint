SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAD] as select a.* From bHRAD a
GO
GRANT SELECT ON  [dbo].[HRAD] TO [public]
GRANT INSERT ON  [dbo].[HRAD] TO [public]
GRANT DELETE ON  [dbo].[HRAD] TO [public]
GRANT UPDATE ON  [dbo].[HRAD] TO [public]
GRANT SELECT ON  [dbo].[HRAD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRAD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRAD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRAD] TO [Viewpoint]
GO
