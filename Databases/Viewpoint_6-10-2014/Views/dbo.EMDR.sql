SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDR] as select a.* From bEMDR a
GO
GRANT SELECT ON  [dbo].[EMDR] TO [public]
GRANT INSERT ON  [dbo].[EMDR] TO [public]
GRANT DELETE ON  [dbo].[EMDR] TO [public]
GRANT UPDATE ON  [dbo].[EMDR] TO [public]
GRANT SELECT ON  [dbo].[EMDR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMDR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMDR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMDR] TO [Viewpoint]
GO
