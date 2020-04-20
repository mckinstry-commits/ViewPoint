SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPOnCostActionOneCheck    Script Date: 8/28/99 9:34:02 AM ******/
CREATE                    proc [dbo].[vspAPOnCostActionOneCheck]
/***********************************************************
* CREATED BY:   MV	04/30/12	TK-14132 APOnCost Processing
* MODIFIED By :	
*
* USAGE:
* Called from AP OnCost Workfile to check if there are any Action 
* 1s to process. 
*
*
*  INPUT PARAMETERS
*  @APCo				AP Company
*
* OUTPUT PARAMETERS
*  @msg                error message if error occurs
*
* RETURN VALUE
*  0                   success
*  1                   failure
*************************************************************/
   
(@APCo bCompany,
 @ActionOneYN bYN OUTPUT, 
 @Msg varchar(255) OUTPUT)

AS
SET NOCOUNT ON
   
DECLARE @rcode INT,@UserId bVPUserName

SELECT	@rcode = 0, @UserId = SUSER_SNAME() 
--initialize the return flag to 'yes'
SELECT @ActionOneYN = 'Y'

-- validate input parameters
IF @APCo IS NULL
BEGIN
	SELECT @Msg = 'Missing AP Company.'
	RETURN 1
END


IF EXISTS
		(
			SELECT *
			FROM dbo.vAPOnCostWorkFileDetail
			WHERE APCo=@APCo AND OnCostAction = 1 AND UserID = @UserId

		)
BEGIN
	SELECT @ActionOneYN = 'Y'
END
ELSE
BEGIN
	SELECT @ActionOneYN = 'N'
END

RETURN 

GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostActionOneCheck] TO [public]
GO
