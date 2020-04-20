SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INMA] as select a.* From bINMA a
GO
GRANT SELECT ON  [dbo].[INMA] TO [public]
GRANT INSERT ON  [dbo].[INMA] TO [public]
GRANT DELETE ON  [dbo].[INMA] TO [public]
GRANT UPDATE ON  [dbo].[INMA] TO [public]
GRANT SELECT ON  [dbo].[INMA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INMA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INMA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INMA] TO [Viewpoint]
GO
