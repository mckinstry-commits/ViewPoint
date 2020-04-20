SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE VIEW dbo.CMTBGrid
   AS
   SELECT     dbo.bCMTB.*
   FROM         dbo.bCMTB
   
  
 



GO
GRANT SELECT ON  [dbo].[CMTBGrid] TO [public]
GRANT INSERT ON  [dbo].[CMTBGrid] TO [public]
GRANT DELETE ON  [dbo].[CMTBGrid] TO [public]
GRANT UPDATE ON  [dbo].[CMTBGrid] TO [public]
GRANT SELECT ON  [dbo].[CMTBGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMTBGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMTBGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMTBGrid] TO [Viewpoint]
GO
