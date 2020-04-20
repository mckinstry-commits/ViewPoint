SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE       PROCEDURE [dbo].[vspDeleteConnectsUserByVPUserName]
/************************************************************
* CREATED:     KSE 6/29/2012
* MODIFIED:    
*
* USAGE:
*   Deletes a User and associated Records by the associated VPUserName
*
* CALLED FROM:
*	V6
*
* INPUT PARAMETERS
*     user       
*
* RETURN VALUE
*   
************************************************************/
   (@user bVPUserName)
AS
SET NOCOUNT OFF;
declare @userid int
select @userid=UserID from pUsers where VPUserName=@user
exec dbo.vspDeleteConnectsUserById @userid


GO
GRANT EXECUTE ON  [dbo].[vspDeleteConnectsUserByVPUserName] TO [public]
GO
