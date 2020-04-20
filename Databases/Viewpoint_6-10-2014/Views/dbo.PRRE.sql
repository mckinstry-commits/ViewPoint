SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRE] as select a.* From bPRRE a
GO
GRANT SELECT ON  [dbo].[PRRE] TO [public]
GRANT INSERT ON  [dbo].[PRRE] TO [public]
GRANT DELETE ON  [dbo].[PRRE] TO [public]
GRANT UPDATE ON  [dbo].[PRRE] TO [public]
GRANT SELECT ON  [dbo].[PRRE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRRE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRRE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRRE] TO [Viewpoint]
GO
