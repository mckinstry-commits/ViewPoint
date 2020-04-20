SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQQR] as select a.* From bRQQR a
GO
GRANT SELECT ON  [dbo].[RQQR] TO [public]
GRANT INSERT ON  [dbo].[RQQR] TO [public]
GRANT DELETE ON  [dbo].[RQQR] TO [public]
GRANT UPDATE ON  [dbo].[RQQR] TO [public]
GRANT SELECT ON  [dbo].[RQQR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RQQR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RQQR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RQQR] TO [Viewpoint]
GO
