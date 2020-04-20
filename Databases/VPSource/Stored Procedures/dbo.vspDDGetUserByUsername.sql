SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDGetUserByUsername]
/**************************************************
* Created:  Chris Crewdson 2012-03-15
* Modified: 
* 
*  Returns the VPUsername for the given VPUsername
*   This is used by the ISystemData.IsValidPrincipalName method 
*  in the implementation by RemoteHelper.
* 
* Inputs: 
*   @username VPUsername used when logging in.
*
* Output
*   
*
****************************************************/
	(@username bVPUserName = null)
as

set nocount on 

select VPUserName 
from DDUPExtended with (nolock)
where @username = VPUserName
GO
GRANT EXECUTE ON  [dbo].[vspDDGetUserByUsername] TO [public]
GO
