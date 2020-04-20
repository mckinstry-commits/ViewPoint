SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  4/6/2012
* Description:	Clear grid settings for User Queries
*				in VPCanvasGridGroupedColumnsUser
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPClearGridGroupColumnUser]
	-- Add the parameters for the stored procedure here
	@QueryName VARCHAR(128) ,
	@CustomName VARCHAR(128)
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @VPUserName bVPUserName
	SELECT @VPUserName = SUSER_SNAME()
	
	DELETE FROM dbo.VPCanvasGridGroupedColumnsUser
	WHERE VPUserName = @VPUserName
	AND QueryName = @QueryName
	AND CustomName = @CustomName;
END
GO
GRANT EXECUTE ON  [dbo].[vspVPClearGridGroupColumnUser] TO [public]
GO
