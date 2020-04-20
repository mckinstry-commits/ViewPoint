SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POIB] as select a.* From bPOIB a
GO
GRANT SELECT ON  [dbo].[POIB] TO [public]
GRANT INSERT ON  [dbo].[POIB] TO [public]
GRANT DELETE ON  [dbo].[POIB] TO [public]
GRANT UPDATE ON  [dbo].[POIB] TO [public]
GRANT SELECT ON  [dbo].[POIB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POIB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POIB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POIB] TO [Viewpoint]
GO
