SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefGLAcctNew] as select a.* From budxrefGLAcctNew a
GO
GRANT SELECT ON  [dbo].[udxrefGLAcctNew] TO [public]
GRANT INSERT ON  [dbo].[udxrefGLAcctNew] TO [public]
GRANT DELETE ON  [dbo].[udxrefGLAcctNew] TO [public]
GRANT UPDATE ON  [dbo].[udxrefGLAcctNew] TO [public]
GO
