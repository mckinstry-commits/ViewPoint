SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefGLAcctTypes as select a.* From Viewpoint.dbo.budxrefGLAcctTypes a;
GO
GRANT REFERENCES ON  [dbo].[udxrefGLAcctTypes] TO [public]
GRANT SELECT ON  [dbo].[udxrefGLAcctTypes] TO [public]
GRANT INSERT ON  [dbo].[udxrefGLAcctTypes] TO [public]
GRANT DELETE ON  [dbo].[udxrefGLAcctTypes] TO [public]
GRANT UPDATE ON  [dbo].[udxrefGLAcctTypes] TO [public]
GRANT SELECT ON  [dbo].[udxrefGLAcctTypes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefGLAcctTypes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefGLAcctTypes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefGLAcctTypes] TO [Viewpoint]
GO
