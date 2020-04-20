SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvGLFSPart3] as select GLCo,PartNo,"Part3I"=Instance,"Part3IDesc"=Description
    from GLPI
    where PartNo=3

GO
GRANT SELECT ON  [dbo].[brvGLFSPart3] TO [public]
GRANT INSERT ON  [dbo].[brvGLFSPart3] TO [public]
GRANT DELETE ON  [dbo].[brvGLFSPart3] TO [public]
GRANT UPDATE ON  [dbo].[brvGLFSPart3] TO [public]
GO
