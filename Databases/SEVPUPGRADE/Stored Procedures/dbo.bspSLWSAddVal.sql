SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspSLWSAddVal]
   /***********************************************************
    * CREATED BY	: MV 05/29/03
    * MODIFIED BY	:	DC 06/29/10 - #135813 -  expand subcontract number
    *                
    * USAGE:
    * validates SL for SLWSAdd, returns description for #21222
    * 
    * INPUT PARAMETERS
    *   SLCo  SL Co to validate against
    *	 JCCo  JC Co to validate against
    *   Job   Job to validate against
    *   SL    to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
   (@slco bCompany, @jcco bCompany, @job bJob, @sl VARCHAR(30), -- bSL, DC #135813
   @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint
   
   select @rcode = 0
   
   if @slco is null
   	begin
   	select @msg = 'Missing SL Company!', @rcode = 1
   	goto bspexit
   	end
   
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
   
   if @sl is null
   	begin
   	select @msg = 'Missing Subcontract!', @rcode = 1
   	goto bspexit
   	end
   
   select @status=Status from SLHD
   	where SLCo = @slco and SL = @sl and JCCo=@jcco and Job=@job
   if @@rowcount=0
   	begin
   	select @msg = 'Subcontract not associated with Job: ' + @job, @rcode = 1
   	goto bspexit
   	end
   
   if @status<>0
   	begin
   	select @msg = 'Subcontract not open!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg=Description 
   	from SLHD where SLCo = @slco and SL= @sl and JCCo=@jcco and Job=@job
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLWSAddVal] TO [public]
GO
