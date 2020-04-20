SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[SLIT] as select a.* From bSLIT a


GO
GRANT SELECT ON  [dbo].[SLIT] TO [public]
GRANT INSERT ON  [dbo].[SLIT] TO [public]
GRANT DELETE ON  [dbo].[SLIT] TO [public]
GRANT UPDATE ON  [dbo].[SLIT] TO [public]
GO
