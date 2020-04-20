SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAU] as select a.* From bPRAU a
GO
GRANT SELECT ON  [dbo].[PRAU] TO [public]
GRANT INSERT ON  [dbo].[PRAU] TO [public]
GRANT DELETE ON  [dbo].[PRAU] TO [public]
GRANT UPDATE ON  [dbo].[PRAU] TO [public]
GRANT SELECT ON  [dbo].[PRAU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAU] TO [Viewpoint]
GO
