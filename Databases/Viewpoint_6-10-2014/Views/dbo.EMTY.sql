SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMTY] as select a.* From bEMTY a

GO
GRANT SELECT ON  [dbo].[EMTY] TO [public]
GRANT INSERT ON  [dbo].[EMTY] TO [public]
GRANT DELETE ON  [dbo].[EMTY] TO [public]
GRANT UPDATE ON  [dbo].[EMTY] TO [public]
GRANT SELECT ON  [dbo].[EMTY] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMTY] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMTY] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMTY] TO [Viewpoint]
GO
