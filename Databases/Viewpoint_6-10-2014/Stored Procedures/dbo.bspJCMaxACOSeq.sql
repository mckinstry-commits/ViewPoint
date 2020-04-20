SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCMaxACOSeq    Script Date: 8/28/99 9:32:59 AM ******/
   CREATE  proc [dbo].[bspJCMaxACOSeq]
   /***********************************************************
    * CREATED BY: JM 8/15/97
    * MODIFIED By: TV - 23061 added isnulls
    *				GF 07/06/2005 - issue #29167 added check for PMOH to get max ACOSequence.
    *
    * USAGE:
    *   Returns next JCOH.ACOSequence available for a JCCo/Job.
    *   Used to default ACOSeq on frmJCOH
    *   An error is returned if any of the following occurs
    * 	no JC Company passed
    *	no Job passed
    *
    * INPUT PARAMETERS
    *	JCCo
    *	Job
    *
    * OUTPUT PARAMETERS
    *   @msg - error message if error occurs otherwise (Max JCOH.ACOSeq)
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/ 
   (@jcco bCompany = 0, @job bJob = null, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @acoseq smallint, @pmacoseq smallint
   
   select @rcode = 0, @acoseq = 0, @pmacoseq = 0
   
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
   
   -- -- -- get max from JCOH
   select @acoseq = Max(ACOSequence) 
   from JCOH with (nolock) where JCCo=@jcco and Job=@job
   if @@rowcount = 0 or @acoseq is null select @acoseq = 0
   -- -- -- get max from PMOH
   select @pmacoseq = Max(ACOSequence) 
   from PMOH with (nolock) where PMCo=@jcco and Project=@job
   if @@rowcount = 0 or @pmacoseq is null select @pmacoseq = 0
   if @acoseq = 0 and @pmacoseq = 0
   	begin
   	select @msg = '0'
   	goto bspexit
   	end
   if @acoseq >= @pmacoseq
   	begin
   	select @msg = convert(varchar(5), @acoseq)
   	goto bspexit
   	end
   if @acoseq < @pmacoseq
   	begin
   	select @msg = convert(varchar(5), @pmacoseq)
   	end
   
   
   -- -- -- if @@rowcount = 0 or @acoseq is null
   -- -- -- 	begin
   -- -- -- 	select @msg = '0'
   -- -- -- else
   -- -- -- 	select @msg = convert(varchar(5),@acoseq)
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCMaxACOSeq] TO [public]
GO
