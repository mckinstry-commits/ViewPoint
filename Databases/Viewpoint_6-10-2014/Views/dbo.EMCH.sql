SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMCH] as select a.* From bEMCH a
GO
GRANT SELECT ON  [dbo].[EMCH] TO [public]
GRANT INSERT ON  [dbo].[EMCH] TO [public]
GRANT DELETE ON  [dbo].[EMCH] TO [public]
GRANT UPDATE ON  [dbo].[EMCH] TO [public]
GRANT SELECT ON  [dbo].[EMCH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMCH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMCH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMCH] TO [Viewpoint]
GO
