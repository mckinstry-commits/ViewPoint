SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  1/30/2008
* Modified: CC 10/06/2008 - Issue #130187 - Corrected check to exclude Checklist statuses
* 

* Description:	Validates default status
*
*	Inputs:
*	@StatusType		Type of status to check for default on
*
*	Outputs:
*	@msg			Validation message
*
*****************************************************/
CREATE PROCEDURE dbo.vspWFValidateDefaultStatus 
	-- Add the parameters for the stored procedure here
	@StatusType int = null,
	@msg varchar(512) = null OUTPUT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF EXISTS(SELECT TOP 1 1 
			FROM WFStatusCodes 
			WHERE StatusType = @StatusType AND IsDefaultStatus = 'Y' AND IsChecklistStatus = 'N')
	SELECT @msg = 'A default ' + 
		CASE StatusType 
			WHEN 0 THEN 'new' 
			WHEN 1 THEN 'in progress' 
			WHEN 2 THEN  'final' 
		END 
		+ ' status already exists ' 
	FROM WFStatusCodes 
	WHERE StatusType = @StatusType AND IsDefaultStatus = 'Y' AND IsChecklistStatus = 'N'
	
END
GO
GRANT EXECUTE ON  [dbo].[vspWFValidateDefaultStatus] TO [public]
GO
