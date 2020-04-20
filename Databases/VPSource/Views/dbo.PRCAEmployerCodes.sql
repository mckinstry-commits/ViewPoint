SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCAEmployerCodes] as select * from bPRCAEmployerCodes


GO
GRANT SELECT ON  [dbo].[PRCAEmployerCodes] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployerCodes] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployerCodes] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployerCodes] TO [public]
GO
