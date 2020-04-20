SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POCD] as select a.* From bPOCD a
GO
GRANT SELECT ON  [dbo].[POCD] TO [public]
GRANT INSERT ON  [dbo].[POCD] TO [public]
GRANT DELETE ON  [dbo].[POCD] TO [public]
GRANT UPDATE ON  [dbo].[POCD] TO [public]
GRANT SELECT ON  [dbo].[POCD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POCD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POCD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POCD] TO [Viewpoint]
GO
