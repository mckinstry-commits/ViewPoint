SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRER] as select a.* From bHRER a

GO
GRANT SELECT ON  [dbo].[HRER] TO [public]
GRANT INSERT ON  [dbo].[HRER] TO [public]
GRANT DELETE ON  [dbo].[HRER] TO [public]
GRANT UPDATE ON  [dbo].[HRER] TO [public]
GO
