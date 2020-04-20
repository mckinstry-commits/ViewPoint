SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************
 * Created: Dan Sochacki - 02/21/2008
 *
 * Purpose: Validates HR PTO/Leave Codes
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
 *
 * Inputs:
 *	@HRCo		Company # 
 *	@Code		PTO/Leave Code
 *
 * Ouput:
 *	@msg		Error message
 * 
 * Return code:
 *	0 = success, 1 = failure
 *
 ******************************************/
--CREATE  PROC [dbo].[vspHRPTOCodeVal]
CREATE  PROC [dbo].[vspHRPTOCodeVal]

	(@HRCo bCompany = NULL, @Code varchar(10) = NULL, @msg varchar(60) output)
AS
SET NOCOUNT ON

	DECLARE @rcode int

	SELECT @rcode = 0

	------------------------------------
	-- CHECK FOR ALL INPUT PARAMETERS --
	------------------------------------
	IF (@HRCo IS NULL) OR
		(@Code IS NULL)
		BEGIN
			SELECT @msg = 'Missing Input Parameter(s)!', @rcode = 1
			GOTO vspexit
		END
   
	------------------------------
	--GET PTO/Leave DESCRIPTION --
	------------------------------
	SELECT @msg = Description
	  FROM HRCM WITH (NOLOCK)
	 WHERE HRCo = @HRCo
	   AND [Type] = 'C' 
	   AND PTOTypeYN = 'Y'
	   AND Code = @Code

	------------------------------
	-- WAS THE CODE A PTO CODE? --
	------------------------------
	IF @@rowcount = 0
		SELECT @msg = 'Not a Valid Leave Code!', @rcode = 1


vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRPTOCodeVal] TO [public]
GO
