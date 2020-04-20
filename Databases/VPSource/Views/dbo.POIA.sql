SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POIA] as select a.* From bPOIA a

GO
GRANT SELECT ON  [dbo].[POIA] TO [public]
GRANT INSERT ON  [dbo].[POIA] TO [public]
GRANT DELETE ON  [dbo].[POIA] TO [public]
GRANT UPDATE ON  [dbo].[POIA] TO [public]
GO
