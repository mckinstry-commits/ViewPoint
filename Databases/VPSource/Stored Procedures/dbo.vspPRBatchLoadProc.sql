SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRBatchLoadProc]
/********************************************************
* CREATED BY: 	TRL 02/20/2008 - Issue 21452
* MODIFIED BY:	
*              
* USAGE: Validates PRCo and returns AttachBatchReports Flag from PRCo
*
* INPUT PARAMETERS:
*	@co			Co#
*
* OUTPUT PARAMETERS:
*	@attachbatchreports	bYN
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
 (@co bCompany=0, @attachbatchreports bYN output, @errmsg varchar(255) output)

  as 
set nocount on
declare @rcode int
select @rcode = 0

--Validate the PR Company+
IF not exists(select top 1 1 from dbo.PRCO with (nolock) where PRCo = @co)
BEGIN
	select @errmsg = 'Invalid PR Company.', @rcode = 1
	goto vspexit
end
	
Select @attachbatchreports = IsNull(AttachBatchReportsYN,'N') From dbo.PRCO with(nolock) Where PRCo = @co


vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRBatchLoadProc] TO [public]
GO
