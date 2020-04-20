SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		Charles Courchaine
* Create date:  2/1/2008
* Description:	Validates that status is not in use before delete
*
*	Inputs:
*	@StatusID			StatusID to check if it's in use
*	@IsChecklistStatus	Check checklists or tasks & steps
*
*	Outputs:
*	@msg			Validation message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFIsStatusInUse] 
	-- Add the parameters for the stored procedure here
	@StatusID int = null,
	@IsChecklistStatus bYN = null,
	@msg varchar(512) = null OUTPUT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
if @IsChecklistStatus = 'Y'
	begin
	if exists (select top 1 1 from WFChecklists where [Status] = @StatusID)
		set @msg = 'Checklist status in use '
	end
else
	if exists (select top 1 1 from WFChecklistTasks where [Status] = @StatusID) or exists (select top 1 1 from WFChecklistSteps where [Status] = @StatusID)
		set @msg = 'Status in use '
END

GO
GRANT EXECUTE ON  [dbo].[vspWFIsStatusInUse] TO [public]
GO
