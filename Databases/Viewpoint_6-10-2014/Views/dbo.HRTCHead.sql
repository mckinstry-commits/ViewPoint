SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /**************************
   *
   *	Created by MH
   *	Created 2004
   *
   *	Purpose:  Serves as the header table for HRTrainClassConsole.
   *
   *
   *
   *
   ***************************/
   
   CREATE   VIEW dbo.HRTCHead
   AS
   SELECT DISTINCT dbo.bHRTC.TrainCode, dbo.bHRCM.Description, dbo.bHRTC.HRCo
   FROM         dbo.bHRTC with (nolock) INNER JOIN
                         dbo.bHRCM with (nolock) ON dbo.bHRTC.HRCo = dbo.bHRCM.HRCo AND dbo.bHRTC.TrainCode = dbo.bHRCM.Code AND dbo.bHRTC.Type = dbo.bHRCM.Type
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[HRTCHead] TO [public]
GRANT INSERT ON  [dbo].[HRTCHead] TO [public]
GRANT DELETE ON  [dbo].[HRTCHead] TO [public]
GRANT UPDATE ON  [dbo].[HRTCHead] TO [public]
GRANT SELECT ON  [dbo].[HRTCHead] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRTCHead] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRTCHead] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRTCHead] TO [Viewpoint]
GO
