SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  view [dbo].[DDFLc] as select a.* From vDDFLc a
                                                                                               




GO
GRANT SELECT ON  [dbo].[DDFLc] TO [public]
GRANT INSERT ON  [dbo].[DDFLc] TO [public]
GRANT DELETE ON  [dbo].[DDFLc] TO [public]
GRANT UPDATE ON  [dbo].[DDFLc] TO [public]
GO
