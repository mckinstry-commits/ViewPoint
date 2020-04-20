SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PROT] as select a.* From bPROT a
GO
GRANT SELECT ON  [dbo].[PROT] TO [public]
GRANT INSERT ON  [dbo].[PROT] TO [public]
GRANT DELETE ON  [dbo].[PROT] TO [public]
GRANT UPDATE ON  [dbo].[PROT] TO [public]
GRANT SELECT ON  [dbo].[PROT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PROT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PROT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PROT] TO [Viewpoint]
GO
