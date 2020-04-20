SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefPRStates] as select a.* From budxrefPRStates a
GO
GRANT SELECT ON  [dbo].[udxrefPRStates] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRStates] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRStates] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRStates] TO [public]
GO
