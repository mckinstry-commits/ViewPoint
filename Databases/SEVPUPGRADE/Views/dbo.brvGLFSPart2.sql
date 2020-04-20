SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvGLFSPart2] as select GLCo,PartNo,"Part2I"=Instance,"Part2IDesc"=Description
    from GLPI
    where PartNo=2

GO
GRANT SELECT ON  [dbo].[brvGLFSPart2] TO [public]
GRANT INSERT ON  [dbo].[brvGLFSPart2] TO [public]
GRANT DELETE ON  [dbo].[brvGLFSPart2] TO [public]
GRANT UPDATE ON  [dbo].[brvGLFSPart2] TO [public]
GO
