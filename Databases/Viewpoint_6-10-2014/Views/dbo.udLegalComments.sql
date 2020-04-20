SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udLegalComments] as select a.* From budLegalComments a
GO
GRANT SELECT ON  [dbo].[udLegalComments] TO [public]
GRANT INSERT ON  [dbo].[udLegalComments] TO [public]
GRANT DELETE ON  [dbo].[udLegalComments] TO [public]
GRANT UPDATE ON  [dbo].[udLegalComments] TO [public]
GO
