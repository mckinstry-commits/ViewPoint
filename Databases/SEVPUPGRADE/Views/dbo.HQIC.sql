SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQIC] as select a.* From bHQIC a
GO
GRANT SELECT ON  [dbo].[HQIC] TO [public]
GRANT INSERT ON  [dbo].[HQIC] TO [public]
GRANT DELETE ON  [dbo].[HQIC] TO [public]
GRANT UPDATE ON  [dbo].[HQIC] TO [public]
GO
