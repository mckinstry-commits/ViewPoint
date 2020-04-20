SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRJobVal    Script Date: 8/28/99 9:36:32 AM ******/
   CREATE   proc [dbo].[bspPRJobVal]
   /***********************************************************
    * CREATED BY: kb 1/8/98
    * MODIFIED By : kb 1/12/99
    *               EN 8/3/00 - Return @rprstate to be used as default for tax state in PRTimeCards.  @rprstate takes retroactive state agreements into account.
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 2/13/03 - issue 19974  return JCJM_JobStatus and JCJM_Certified
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
	*				GP 06/03/09 - Issue 132805 added null to bspJCJMPostVal
    *
    * USAGE:
    * validates PR Timecard Entry job using the standard job validation.
    * an error is returned if any of the following occurs j
    *
    * INPUT PARAMETERS
    *	 PRCo
    *   JCCo   JC Co to validate agains
    *   Job    Job to validate
    * OUTPUT PARAMETERS
    *	 @jobdesc
    *   @rprstate
    *	 @prstate
    *	 @prlocalcode
    *	 @instemplate
    *	 @crafttemplate
    *	 @lockphases
    *	 @status	JCJM_JobStatus value
    *	 @cert		JCJM_Certified value
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   	(@prco bCompany, @jcco bCompany, @job bJob, @emplstate varchar(4), @jobdesc bDesc = null output,
   	@rprstate varchar(4) = null output, @prstate varchar(4) = null output, @prlocalcode bLocalCode = null output,
   	@instemplate smallint = null output, @crafttemplate smallint = null output,
   	@lockphases bYN = null output, @status tinyint output, @cert bYN output, @msg varchar(60) output)
   as
   
   
   set nocount on
   
   declare @rcode int, @contract bContract, @taxcode bTaxCode,
   	@errmsg varchar(60)

	declare @address varchar(60), @city varchar(30), @state varchar(4), @zip bZip, 
	@pocompgroup varchar(10), @slcompgroup varchar(10), @address2 varchar(60), @country char(2)
   
   select @rcode = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @job is null
   	begin
   	select @msg = 'Missing Job!', @rcode = 1
   	goto bspexit
   
   	end
   
   exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
   	@taxcode output, @address output, @city output, @state output, @zip output,
	@pocompgroup output, @slcompgroup output, @address2 output, @country output, null, 
	@msg=@errmsg output
   
   
   if @rcode = 1
   	begin
   	select @msg=@errmsg
   	goto bspexit
      	end
   
   if @status = 0
   	begin
   	select @msg = 'Job status cannot be pending', @rcode = 1
   	goto bspexit
   	end
   
   select @prstate=PRStateCode, @prlocalcode=PRLocalCode, @instemplate=InsTemplate,
   
   	@crafttemplate=CraftTemplate
   	 from JCJM where JCCo=@jcco and Job=@job
   
   select @rprstate = @prstate
   if @rprstate<>@emplstate and @emplstate is not null and @rprstate is not null
   	begin
   	if exists(select * from HQRS where JobState=@rprstate and ResidentState=@emplstate)
   		begin
   		select @rprstate=@emplstate
   		end
   	end
   
   select @jobdesc=Description, @cert=Certified, @msg=Description from JCJM where JCCo=@jcco and Job=@job
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRJobVal] TO [public]
GO
