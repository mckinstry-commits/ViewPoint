SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APTB] as select a.* From bAPTB a
GO
GRANT SELECT ON  [dbo].[APTB] TO [public]
GRANT INSERT ON  [dbo].[APTB] TO [public]
GRANT DELETE ON  [dbo].[APTB] TO [public]
GRANT UPDATE ON  [dbo].[APTB] TO [public]
GRANT SELECT ON  [dbo].[APTB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APTB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APTB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APTB] TO [Viewpoint]
GO
