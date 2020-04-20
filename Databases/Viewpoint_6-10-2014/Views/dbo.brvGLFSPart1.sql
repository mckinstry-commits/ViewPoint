SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvGLFSPart1] as select * from GLPI where PartNo =1

GO
GRANT SELECT ON  [dbo].[brvGLFSPart1] TO [public]
GRANT INSERT ON  [dbo].[brvGLFSPart1] TO [public]
GRANT DELETE ON  [dbo].[brvGLFSPart1] TO [public]
GRANT UPDATE ON  [dbo].[brvGLFSPart1] TO [public]
GRANT SELECT ON  [dbo].[brvGLFSPart1] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvGLFSPart1] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvGLFSPart1] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvGLFSPart1] TO [Viewpoint]
GO
