SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvGLFSP1] as select * from GLPD where PartNo =1

GO
GRANT SELECT ON  [dbo].[brvGLFSP1] TO [public]
GRANT INSERT ON  [dbo].[brvGLFSP1] TO [public]
GRANT DELETE ON  [dbo].[brvGLFSP1] TO [public]
GRANT UPDATE ON  [dbo].[brvGLFSP1] TO [public]
GRANT SELECT ON  [dbo].[brvGLFSP1] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvGLFSP1] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvGLFSP1] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvGLFSP1] TO [Viewpoint]
GO
