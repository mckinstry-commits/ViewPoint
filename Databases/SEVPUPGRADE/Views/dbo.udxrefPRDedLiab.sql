SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udxrefPRDedLiab] as select a.* From budxrefPRDedLiab a
GO
GRANT SELECT ON  [dbo].[udxrefPRDedLiab] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRDedLiab] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRDedLiab] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRDedLiab] TO [public]
GO
