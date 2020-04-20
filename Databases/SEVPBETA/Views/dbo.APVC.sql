SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APVC] as select a.* From bAPVC a
GO
GRANT SELECT ON  [dbo].[APVC] TO [public]
GRANT INSERT ON  [dbo].[APVC] TO [public]
GRANT DELETE ON  [dbo].[APVC] TO [public]
GRANT UPDATE ON  [dbo].[APVC] TO [public]
GO
