SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefPRDeptPaySeq] as select a.* From budxrefPRDeptPaySeq a
GO
GRANT SELECT ON  [dbo].[udxrefPRDeptPaySeq] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRDeptPaySeq] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRDeptPaySeq] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRDeptPaySeq] TO [public]
GO
