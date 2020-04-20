SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvGLFSP3] as select GLCo,PartNo,"P3Desc"=Description
    from GLPD
    where PartNo=3

GO
GRANT SELECT ON  [dbo].[brvGLFSP3] TO [public]
GRANT INSERT ON  [dbo].[brvGLFSP3] TO [public]
GRANT DELETE ON  [dbo].[brvGLFSP3] TO [public]
GRANT UPDATE ON  [dbo].[brvGLFSP3] TO [public]
GRANT SELECT ON  [dbo].[brvGLFSP3] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvGLFSP3] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvGLFSP3] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvGLFSP3] TO [Viewpoint]
GO
