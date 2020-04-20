SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INJC] as select a.* From bINJC a
GO
GRANT SELECT ON  [dbo].[INJC] TO [public]
GRANT INSERT ON  [dbo].[INJC] TO [public]
GRANT DELETE ON  [dbo].[INJC] TO [public]
GRANT UPDATE ON  [dbo].[INJC] TO [public]
GRANT SELECT ON  [dbo].[INJC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INJC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INJC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INJC] TO [Viewpoint]
GO
