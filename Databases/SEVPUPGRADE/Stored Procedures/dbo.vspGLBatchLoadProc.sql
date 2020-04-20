SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspGLBatchLoadProc]
/********************************************************
* CREATED BY: 	TRL 02/20/2008 - Issue 21452
* MODIFIED BY:	
*              
* USAGE: Validates GLCo and returns AttachBatchReports Flag from GLCo
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

--Validate the GL Company+
IF not exists(select top 1 1 from dbo.GLCO with (nolock) where GLCo = @co)
BEGIN
	select @errmsg = 'Invalid GL Company.', @rcode = 1
	goto vspexit
end
	
Select @attachbatchreports = IsNull(AttachBatchReportsYN,'N') From dbo.GLCO with(nolock) Where GLCo = @co


vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGLBatchLoadProc] TO [public]
GO
