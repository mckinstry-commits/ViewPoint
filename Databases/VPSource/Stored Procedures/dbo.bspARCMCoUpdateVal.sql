SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCMCoUpdateVal    Script Date: 8/28/99 9:34:08 AM ******/
   CREATE  proc [dbo].[bspARCMCoUpdateVal]
   	(@arco bCompany = 0, @cmco bCompany = 0, @errmsg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JM 5/9/97
    * MODIFIED By:
    *
    * USAGE:
    *   Validates CMCo update on ARCO maint form
    *   Returns error and errmsg if
    * 	no ARCo passed
    *	no CMCo passed
    *	CMCo not setup in HQCO
    *	ARCo exists in ARBH (AR Batch Header) with ARBH.TransType = P or M
    *
    *   Returns success and errmsg (ie warning) if
    *	CMCo not setup in CMCO
    *
    * INPUT PARAMETERS
    *   ARCo - AR Company to validate against
    *   CMCo - CMCo to validate against
    *
    * OUTPUT PARAMETERS
    *   @errmsg - desc if successful or error message if
    *   warning/error occurs
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *   2 - Warning
    *****************************************************/
   declare @rcode int, @cnt int
   select @rcode = 0
   if @arco is null
   	begin
   	select @errmsg = 'Missing AR Co!', @rcode = 1
   	goto bspexit
   	end
   if @cmco is null
   	begin
   	select @errmsg = 'Missing CM Co!', @rcode = 1
   	goto bspexit
   	end
   /* block if CMCo not setup in HQCO */
   select @cnt = count(*) from bHQCO h where h.HQCo = @cmco
   if @cnt = 0
   	begin
   	select @errmsg = 'CM Co not setup!', @rcode = 1
   	goto bspexit
   	end
   /* block if ARCo exists in ARBH (AR Batch Header) with ARBH.TransType = P or M */
   select @cnt = count(*) from bARBH b where b.Co = @arco and b.TransType in ('P', 'M')
   if @cnt > 0
   	begin
   	select @errmsg = 'Cannot change CM Co - Pmt Batch exists!', @rcode = 1
   	goto bspexit
   	end
   /* warn if CMCo not setup in CMCO */
   select @cnt = count(*) from bCMCO c where c.CMCo = @cmco
   if @cnt = 0
   	begin
   	select @errmsg = 'Warning! CM Co not setup!', @rcode = 2
   	goto bspexit
   	end
   if exists(select * from CMCO where @cmco = CMCo)
   	begin
   	select @errmsg = Name from bHQCO where HQCo = @cmco
   	goto bspexit
   	end
   else
   	begin
   	select @errmsg = 'Not a valid CM Co', @rcode = 1
   	end
   bspexit:
   	if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARCMCoUpdateVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCMCoUpdateVal] TO [public]
GO
