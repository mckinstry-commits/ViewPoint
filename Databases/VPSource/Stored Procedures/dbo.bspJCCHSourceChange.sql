SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************************************/
CREATE proc [dbo].[bspJCCHSourceChange]
   /****************************************************************************
   * Created By:		GF 06/24/2004
   * Modified By:
   *
   *
   * USAGE:
   * 	Changes the source status for all or a range of phases and cost types
   *	within a specified job.
   *
   * INPUT PARAMETERS:
   *	Company, Job, Beginning Phase, Ending Phase, Beginning CostType, Ending CostType, SourceStatus Flag
   *
   * OUTPUT PARAMETERS:
   *	None
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *****************************************************************************/
   (@jcco bCompany, @job bJob, @bphase bPhase, @ephase bPhase,
    @bcosttype integer, @ecosttype integer, @sourcestatusflag bYN,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode integer, @changed integer
   
   select  @rcode=0, @changed = 0
   
   if (select count(*) from bJCCO where JCCo=@jcco)<>1
   	begin
   	select @msg = 'Company not set up in JC Company file!', @rcode = 1
   	goto bspexit
   	end
   
   if (select count(*) from bJCJM where JCCo=@jcco and Job=@job)<>1
   	begin
   	select @msg = 'Job not in Job Master JCJM!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@sourcestatusflag,'') <> 'Y' and isnull(@sourcestatusflag,'') <> 'N'
   	begin
   	select @msg = 'Source Status flag must be (Y) or (N).', @rcode=1
   	goto bspexit
   	end
   
   
   -- update JCCH.SourceStatus flag
   update bJCCH set SourceStatus = @sourcestatusflag
   where JCCo=@jcco and Job=@job and Phase>=@bphase and Phase<=@ephase
   and CostType>=@bcosttype and CostType<=@ecosttype and SourceStatus in ('Y', 'N')
   and SourceStatus <> @sourcestatusflag
   set @changed = @@rowcount
   
   
   
   
   bspexit:
   	if @rcode = 0 set @msg = convert(varchar(10),@changed)
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCHSourceChange] TO [public]
GO
