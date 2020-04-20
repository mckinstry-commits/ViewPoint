SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
   CREATE proc [dbo].[bspJCJPStatusChange]
   /****************************************************************************
    * Created By: 	GF 07/16/2002
    * Modified By: TV - 23061 added isnulls
    *
    *
    * USAGE:
    * 	Changes the active status for all or a range of phases within a specified job.
    *
    * INPUT PARAMETERS:
    *	Company, Job, Beginning Phase, Ending Phase, Active Flag
    *
    * OUTPUT PARAMETERS:
    *	None
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *****************************************************************************/
   (@jcco bCompany=0, @job bJob=null, @bphase bPhase=null, @ephase bPhase=null,
    @activeflag varchar(1)=null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode integer, @validcnt integer
   
   select  @rcode=0
   
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
   
   if @activeflag is null
   	begin
      	select @msg = 'Active flag must not be null.', @rcode = 1
      	goto bspexit
   	end
   
   if @activeflag <> 'Y' and @activeflag <> 'N'
      	begin
      	select @msg = 'Active flag must be (Y) or (N).', @rcode=1
      	goto bspexit
      	end
   
   
   -- -- -- update JCJP.Active flag
   update bJCJP set ActiveYN=@activeflag
   where JCCo=@jcco and Job=@job and Phase>=@bphase and Phase<=@ephase and ActiveYN <> @activeflag
   select @validcnt = @@rowcount
   select @msg = 'Project Phases with active status updated: ' + convert(varchar(8),isnull(@validcnt,0)) + '.'
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJPStatusChange] TO [public]
GO
