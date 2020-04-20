SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSMassApprove    Script Date: 8/28/99 9:35:39 AM ******/
     CREATE      proc [dbo].[bspPRTSMassApprove]
     /****************************************************************************
      * CREATED BY: EN 3/31/03
      * MODIFIED By : EN 9/13/04 issue 25503  update statement not checking crew correctly ... causes syntax error
      *					EN 10/12/04 issue 25667  check for PRGroup within timesheet itself (bPRRH), not by overall crew (bPRCR)
      *
      * USAGE:
      * Fills in ApprovedBy field for all timesheets which fit the specified parameter.
      * 
      *  INPUT PARAMETERS
      *   @prco			PR Company
      *	 @prgroup		PR Group
      *   @jcco			JC Company
      *   @job			Job
      *	 @crew			Crew code
      *	 @user			TimeSheet approver
      *
      * OUTPUT PARAMETERS
      *   @msg      		error message if error occurs 
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      ****************************************************************************/ 
     (@prco bCompany = null, @prgroup bGroup = null, @jcco bCompany = null,
      @job bJob = null, @crew varchar(10) = null, @user bVPUserName = null,
      @msg varchar(60) output)
     as
     
     set nocount on
     
     declare @rcode int
     
     select @rcode = 0
     
     -- validate PRCo
     if @prco is null
     	begin
     	select @msg = 'Missing PR Co#!', @rcode = 1
     	goto bspexit
     	end
     -- validate PRGroup
     if @prgroup is null
     	begin
     	select @msg = 'Missing PR Group!', @rcode = 1
     	goto bspexit
     	end
     -- validate user
     if @user is null
     	begin
     	select @msg = 'Missing user name!', @rcode = 1
     	goto bspexit
     	end
     
     -- set ApprovedBy flag for all records awaiting approval
     update PRRH
     set [Status]=2, ApprovedBy=@user
     where PRCo=@prco and
     	PRGroup=@prgroup and --issue 25667
     	JCCo=isnull(@jcco,JCCo) and Job=isnull(@job,Job) and Crew=isnull(@crew,Crew) and
     	Status=1
     
     
     bspexit:
     	--if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPRTSMassApprove]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSMassApprove] TO [public]
GO
