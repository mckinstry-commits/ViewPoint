SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHRBatchLoadProc]
/********************************************************
* CREATED BY: 	TRL 02/20/2008 - Issue 21452
* MODIFIED BY:	
*              
* USAGE: Validates HRCo and returns AttachBatchReports Flag from HRCo
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

--Validate the HR Company+
IF not exists(select top 1 1 from dbo.HRCO with (nolock) where HRCo = @co)
BEGIN
	select @errmsg = 'Invalid HR Company.', @rcode = 1
	goto vspexit
end
	
Select @attachbatchreports = IsNull(AttachBatchReportsYN,'N') From dbo.HRCO with(nolock) Where HRCo = @co


vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRBatchLoadProc] TO [public]
GO
