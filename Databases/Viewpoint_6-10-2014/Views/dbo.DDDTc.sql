SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[DDDTc] AS SELECT a.* FROM vDDDTc a 


GO
GRANT SELECT ON  [dbo].[DDDTc] TO [public]
GRANT INSERT ON  [dbo].[DDDTc] TO [public]
GRANT DELETE ON  [dbo].[DDDTc] TO [public]
GRANT UPDATE ON  [dbo].[DDDTc] TO [public]
GRANT SELECT ON  [dbo].[DDDTc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDDTc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDDTc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDDTc] TO [Viewpoint]
GO
