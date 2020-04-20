SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  CREATE VIEW dbo.HRTCGrid
  AS
  SELECT     dbo.bHRTC.*
  FROM         dbo.bHRTC
  
 



GO
GRANT SELECT ON  [dbo].[HRTCGrid] TO [public]
GRANT INSERT ON  [dbo].[HRTCGrid] TO [public]
GRANT DELETE ON  [dbo].[HRTCGrid] TO [public]
GRANT UPDATE ON  [dbo].[HRTCGrid] TO [public]
GO
