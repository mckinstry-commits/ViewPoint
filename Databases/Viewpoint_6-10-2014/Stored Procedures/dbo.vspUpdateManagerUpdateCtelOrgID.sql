SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspUpdateManagerUpdateCtelOrgID]
   /***************************************************
   *    Created:	TMS 06/29/2010 - Want to store the validated Clientele OrgID from VCS Update Manager
   *
   *    Purpose: Called from VCSUpdateManager after successful validation of the Clientele Organization ID  
   *	via FLEXnet Connect.  
   *
   *    Input:
   *        @ClienteleOrgID - Validated GUID OrgID from Clientele CRM
   *        
   *                
   ***************************************************************************************************/
   (@ClienteleOrgID uniqueidentifier)
   
   as
   set nocount on
   
     
-- Check if OrgID column is in the table and update only if it is --

IF EXISTS (select 1 from sys.columns where object_name(object_id) = 'DDVS' and name = 'OrganizationID')
	BEGIN 
	UPDATE dbo.DDVS
	SET [OrganizationID] = @ClienteleOrgID  
	END  



GO
GRANT EXECUTE ON  [dbo].[vspUpdateManagerUpdateCtelOrgID] TO [public]
GO
