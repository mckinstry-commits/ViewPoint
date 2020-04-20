SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefGLAcct as select a.* From Viewpoint.dbo.budxrefGLAcct a;
GO
GRANT REFERENCES ON  [dbo].[udxrefGLAcct] TO [public]
GRANT SELECT ON  [dbo].[udxrefGLAcct] TO [public]
GRANT INSERT ON  [dbo].[udxrefGLAcct] TO [public]
GRANT DELETE ON  [dbo].[udxrefGLAcct] TO [public]
GRANT UPDATE ON  [dbo].[udxrefGLAcct] TO [public]
GO
