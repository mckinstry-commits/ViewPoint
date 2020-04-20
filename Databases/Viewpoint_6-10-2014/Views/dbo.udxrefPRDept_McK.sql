SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefPRDept_McK] as select a.* From budxrefPRDept_McK a
GO
GRANT SELECT ON  [dbo].[udxrefPRDept_McK] TO [public]
GRANT INSERT ON  [dbo].[udxrefPRDept_McK] TO [public]
GRANT DELETE ON  [dbo].[udxrefPRDept_McK] TO [public]
GRANT UPDATE ON  [dbo].[udxrefPRDept_McK] TO [public]
GO
