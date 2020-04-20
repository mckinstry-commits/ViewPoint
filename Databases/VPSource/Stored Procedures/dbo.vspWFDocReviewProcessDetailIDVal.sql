SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspWFDocReviewProcessDetailIDVal]
/***********************************************************
* CREATED BY:	GP	05/14/2012
* MODIFIED BY:	
*				
* USAGE:
* Used in WF Document Review to return a step KeyID.
*
* INPUT PARAMETERS
*	UserName
*   ProcessDetailID
*
* OUTPUT PARAMETERS
*	@DetailStepID		Step KeyID
*   @msg				Description of Process Detail record
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@UserName bVPUserName, @ProcessDetailID bigint,
 @DetailStepID bigint output, @msg varchar(255) output)
as
set nocount on

--Validate
if @UserName is null
begin
	select @msg = 'Missing User Name.'
	return 1
end

if @ProcessDetailID is null
begin
	select @msg = 'Missing Process Detail ID.'
	return 1
end


--Get Description and KeyID
select @DetailStepID = min(approver.DetailStepID), @msg = detail.SourceDescription
from dbo.WFProcessDetailApprover approver
join dbo.WFProcessDetailStep step on step.KeyID = approver.DetailStepID
join dbo.WFProcessDetail detail on detail.KeyID = step.ProcessDetailID
where approver.Approver = @UserName and detail.KeyID = @ProcessDetailID
group by detail.SourceDescription
GO
GRANT EXECUTE ON  [dbo].[vspWFDocReviewProcessDetailIDVal] TO [public]
GO
