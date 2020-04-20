SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefPRIns] as select a.* From budxrefPRIns a
GO
GRANT SELECT ON  [dbo].[udxrefPRIns] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRIns] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRIns] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRIns] TO [public]
GO
