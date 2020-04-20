SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APAA] as select a.* From bAPAA a
GO
GRANT SELECT ON  [dbo].[APAA] TO [public]
GRANT INSERT ON  [dbo].[APAA] TO [public]
GRANT DELETE ON  [dbo].[APAA] TO [public]
GRANT UPDATE ON  [dbo].[APAA] TO [public]
GO
