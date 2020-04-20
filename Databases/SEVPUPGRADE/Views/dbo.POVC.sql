SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POVC] as select a.* From bPOVC a

GO
GRANT SELECT ON  [dbo].[POVC] TO [public]
GRANT INSERT ON  [dbo].[POVC] TO [public]
GRANT DELETE ON  [dbo].[POVC] TO [public]
GRANT UPDATE ON  [dbo].[POVC] TO [public]
GO
