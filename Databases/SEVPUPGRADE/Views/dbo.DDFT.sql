SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   view [dbo].[DDFT] as select * from vDDFT


GO
GRANT SELECT ON  [dbo].[DDFT] TO [public]
GRANT INSERT ON  [dbo].[DDFT] TO [public]
GRANT DELETE ON  [dbo].[DDFT] TO [public]
GRANT UPDATE ON  [dbo].[DDFT] TO [public]
GO
