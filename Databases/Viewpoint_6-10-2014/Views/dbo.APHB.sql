SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APHB] as select a.* From bAPHB a
GO
GRANT SELECT ON  [dbo].[APHB] TO [public]
GRANT INSERT ON  [dbo].[APHB] TO [public]
GRANT DELETE ON  [dbo].[APHB] TO [public]
GRANT UPDATE ON  [dbo].[APHB] TO [public]
GRANT SELECT ON  [dbo].[APHB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APHB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APHB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APHB] TO [Viewpoint]
GO
