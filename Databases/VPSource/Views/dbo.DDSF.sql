SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[DDSF] as select a.* From vDDSF a
                                                                                             



GO
GRANT SELECT ON  [dbo].[DDSF] TO [public]
GRANT INSERT ON  [dbo].[DDSF] TO [public]
GRANT DELETE ON  [dbo].[DDSF] TO [public]
GRANT UPDATE ON  [dbo].[DDSF] TO [public]
GO
