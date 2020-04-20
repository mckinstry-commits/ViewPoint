SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udxrefGLAcct] as select a.* From budxrefGLAcct a
GO
GRANT SELECT ON  [dbo].[udxrefGLAcct] TO [public]
GRANT INSERT ON  [dbo].[udxrefGLAcct] TO [public]
GRANT DELETE ON  [dbo].[udxrefGLAcct] TO [public]
GRANT UPDATE ON  [dbo].[udxrefGLAcct] TO [public]
GO
