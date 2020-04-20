SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[DDUT] as select * from vDDUT

GO
GRANT SELECT ON  [dbo].[DDUT] TO [public]
GRANT INSERT ON  [dbo].[DDUT] TO [public]
GRANT DELETE ON  [dbo].[DDUT] TO [public]
GRANT UPDATE ON  [dbo].[DDUT] TO [public]
GO
