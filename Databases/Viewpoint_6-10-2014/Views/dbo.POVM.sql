SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[POVM] as select a.* From bPOVM a

GO
GRANT SELECT ON  [dbo].[POVM] TO [public]
GRANT INSERT ON  [dbo].[POVM] TO [public]
GRANT DELETE ON  [dbo].[POVM] TO [public]
GRANT UPDATE ON  [dbo].[POVM] TO [public]
GRANT SELECT ON  [dbo].[POVM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POVM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POVM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POVM] TO [Viewpoint]
GO
