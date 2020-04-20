SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROCEDURE [dbo].[vspHRGetResFromVPUser]
CREATE PROCEDURE [dbo].[vspHRGetResFromVPUser]
/**************************************************
* Created:  Dan So 12/19/07
* Modified: mh 7/29/08 - Issue 129149.  Expand message to inform user VPUsers must
*						be setup in HR Resource Master.
*
* Used by frmHRPTORequest to retrieve HRRef value for a specific VPUsername.
* 
* Inputs
*   @UserName
*
* Output
*	@HRResource
*   OR
*   @rcode
*	@errmsg
*
****************************************************/
	(@HRCo bCompany = NULL, @HRResource bHRRef output, @errmsg varchar(255) output)
AS

SET NOCOUNT ON
 
DECLARE @rcode	int

	SELECT @HRResource = 0, @rcode = 0

	-----------------------------------
	-- CHECK FOR INCOMING HR Company --
	-----------------------------------
	IF @HRCo IS NULL
		BEGIN
			SELECT @rcode = 1, @errmsg = 'Missing HR Company parameter.'
			GOTO vspexit
		END

	----------------------------------
	-- RETRIEVE HR RESOURCE (HRRef) --
	----------------------------------
	   SELECT @HRResource = h.HRRef
		 FROM HRRM h
	     JOIN DDUP d on h.HRCo = d.HRCo AND h.HRRef = d.HRRef
		WHERE h.HRCo = @HRCo
		  AND d.VPUserName = SUSER_NAME()

	---------------------------------
	-- CHECK FOR @HRResource VALUE --
	---------------------------------
	IF @HRResource = 0
		BEGIN
			SELECT @rcode = 1, @errmsg = 'Could not find Resource for VPUserName: ' + SUSER_NAME() + 
									     ' in HR Company: ' + convert(varchar,@HRCo) + '.' + 
										CHAR(10) +  'Viewpoint users must be set up in HR Resource Master.'
			GOTO vspexit
		END


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRGetResFromVPUser] TO [public]
GO
