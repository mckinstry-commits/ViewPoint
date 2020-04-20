SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APJC] as select a.* From bAPJC a

GO
GRANT SELECT ON  [dbo].[APJC] TO [public]
GRANT INSERT ON  [dbo].[APJC] TO [public]
GRANT DELETE ON  [dbo].[APJC] TO [public]
GRANT UPDATE ON  [dbo].[APJC] TO [public]
GO
