SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udxrefPRPaySeq] as select a.* From budxrefPRPaySeq a
GO
GRANT SELECT ON  [dbo].[udxrefPRPaySeq] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRPaySeq] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRPaySeq] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRPaySeq] TO [public]
GO
