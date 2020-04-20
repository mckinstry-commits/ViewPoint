SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDJP] 
as 
	select	a.*
	from bWDJP a
	







GO
GRANT SELECT ON  [dbo].[WDJP] TO [public]
GRANT INSERT ON  [dbo].[WDJP] TO [public]
GRANT DELETE ON  [dbo].[WDJP] TO [public]
GRANT UPDATE ON  [dbo].[WDJP] TO [public]
GO
