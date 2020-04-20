SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROC [dbo].[vspHRApprovalGroupDesc]
CREATE PROC [dbo].[vspHRApprovalGroupDesc]
/***********************************************************
* CREATED BY:  Dan Sochacki 12/13/07 - Issue #123780
* MODIFIED BY: 
*
* USAGE:
* 	Return Description to VCSLabelDesc on record save
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
*
* INPUT PARAMETERS
*   HR Company
*   PTO/Leave Approval Group
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@HRCo bCompany = NULL, @AppGroup bGroup = NULL, @msg varchar(255) output)
AS
SET NOCOUNT ON

	DECLARE @rcode int
	SET @rcode = 0

	------------------------------------
	-- GET APPROVAL GROUP DESCRIPTION --
	------------------------------------
	IF ((@HRCo IS NULL) OR (@AppGroup IS NULL))
		BEGIN
 			SELECT @rcode = 1, @msg = 'Missing HRCompnay and/or Approval Group inputs.'
			GOTO vspexit
		END
	ELSE
		BEGIN
			SELECT @msg = AppvrGrpDesc
			  FROM HRAG WITH (NOLOCK)
			 WHERE HRCo = @HRCo
			   AND PTOAppvrGrp = @AppGroup
		END
	

vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRApprovalGroupDesc] TO [public]
GO
