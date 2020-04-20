SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvGLFSP2] as select GLCo,PartNo,"P2Desc"=Description
    from GLPD
    where PartNo=2

GO
GRANT SELECT ON  [dbo].[brvGLFSP2] TO [public]
GRANT INSERT ON  [dbo].[brvGLFSP2] TO [public]
GRANT DELETE ON  [dbo].[brvGLFSP2] TO [public]
GRANT UPDATE ON  [dbo].[brvGLFSP2] TO [public]
GRANT SELECT ON  [dbo].[brvGLFSP2] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvGLFSP2] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvGLFSP2] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvGLFSP2] TO [Viewpoint]
GO
