SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRLeaveCodeDesc    Script Date: 8/28/99 9:33:25 AM ******/
  CREATE   proc dbo.vspPRLeaveCodeDesc
  /***********************************************************
   * CREATED BY: EN 11/03/05
   * MODIFIED By : 
   *
   * Usage:
   *	Used in PR Leave Codes to return description to the key field.
   *
   * Input params:
   *	@prco		PR company
   *	@leavecode	Leave Code to validate
   *
   * Output params:
   *	@msg		Leave code description
   *
   ************************************************************/
  (@prco bCompany, @leavecode bLeaveCode, @msg varchar(60) output)

  as
  set nocount on

  declare @rcode int

  select @rcode = 0, @msg=''
  
  if @prco is not null and isnull(@leavecode,'') <> ''
	begin
  	select @msg=Description from dbo.PRLV with (nolock) where PRCo=@prco and LeaveCode=@leavecode
    end

  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRLeaveCodeDesc] TO [public]
GO
