SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APWD] as select a.* From bAPWD a
GO
GRANT SELECT ON  [dbo].[APWD] TO [public]
GRANT INSERT ON  [dbo].[APWD] TO [public]
GRANT DELETE ON  [dbo].[APWD] TO [public]
GRANT UPDATE ON  [dbo].[APWD] TO [public]
GO
