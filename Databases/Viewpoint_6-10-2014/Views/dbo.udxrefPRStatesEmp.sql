SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefPRStatesEmp] as select a.* From budxrefPRStatesEmp a
GO
GRANT SELECT ON  [dbo].[udxrefPRStatesEmp] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRStatesEmp] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRStatesEmp] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRStatesEmp] TO [public]
GO
