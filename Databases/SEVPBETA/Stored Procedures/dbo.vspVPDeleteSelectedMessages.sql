SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************************
*  Created by: 	CC 6/9/08
*
*  Modified by:
*
*							
* Usage: Deletes flagged records for a specific user
*
***********************************************************************/

CREATE PROCEDURE [dbo].[vspVPDeleteSelectedMessages] 
	-- Add the parameters for the stored procedure here
	@UserName bVPUserName = null, @errmsg varchar(255)output
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	
	SET @rcode = 0

	IF @UserName IS NULL
		BEGIN
			SELECT @rcode = 1, @errmsg = 'No username supplied.'
			GOTO bspexit
		END

	DELETE FROM vWFMail WHERE UserID = @UserName AND Selected = 'Y'

   bspexit:
   
   IF @rcode = 0            
       SET @errmsg = 'Records deleted successfully.'      

END

GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteSelectedMessages] TO [public]
GO
