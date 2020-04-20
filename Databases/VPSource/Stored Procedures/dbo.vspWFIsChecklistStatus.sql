SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		Charles Courchaine
* Create date:  5/1/2008
* Description:	Validates that status is not a checklist status
*
*	Inputs:
*	@StatusID			StatusID to check if it's in use
*	@IsChecklistStatus	Check checklists or tasks & steps
*
*	Outputs:
*	@msg			Validation message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFIsChecklistStatus] 
	-- Add the parameters for the stored procedure here
	@StatusID int = NULL,
	@msg VARCHAR(512) = NULL OUTPUT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN
	IF EXISTS (SELECT TOP 1 1 FROM WFStatusCodes WHERE [StatusID] = @StatusID AND IsChecklistStatus = 'Y')
		SET @msg = 'Reserved status '
	END
END

GO
GRANT EXECUTE ON  [dbo].[vspWFIsChecklistStatus] TO [public]
GO
