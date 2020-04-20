SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDG] as select a.* From bEMDG a
GO
GRANT SELECT ON  [dbo].[EMDG] TO [public]
GRANT INSERT ON  [dbo].[EMDG] TO [public]
GRANT DELETE ON  [dbo].[EMDG] TO [public]
GRANT UPDATE ON  [dbo].[EMDG] TO [public]
GRANT SELECT ON  [dbo].[EMDG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMDG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMDG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMDG] TO [Viewpoint]
GO
