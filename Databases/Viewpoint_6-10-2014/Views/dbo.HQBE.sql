SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQBE] as select a.* From bHQBE a
GO
GRANT SELECT ON  [dbo].[HQBE] TO [public]
GRANT INSERT ON  [dbo].[HQBE] TO [public]
GRANT DELETE ON  [dbo].[HQBE] TO [public]
GRANT UPDATE ON  [dbo].[HQBE] TO [public]
GRANT SELECT ON  [dbo].[HQBE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQBE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQBE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQBE] TO [Viewpoint]
GO
