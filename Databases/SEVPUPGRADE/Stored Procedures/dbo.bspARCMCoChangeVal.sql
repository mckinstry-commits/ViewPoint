SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCMCoChangeVal    Script Date: 8/28/99 9:34:08 AM ******/
   CREATE  proc [dbo].[bspARCMCoChangeVal]
   	(@arco bCompany = 0, @errmsg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JM 8/14/97
    * MODIFIED By:
    *
    * USAGE:
    *   Validates if revision to ARCo.CMCo is OK
    *   Returns error and can't update errmsg if
    * 	no ARCo passed
    *	records exist in ARBH for ARBH.ARCo = @arco and
    *		ARBH.ARTransType = 'M' o 'P'
    *
    *   Returns success, or error if test fails
    *
    * INPUT PARAMETERS
    *   arco - AR Company to validate against
    *
    * OUTPUT PARAMETERS
    *	@rcode only
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure from a missing input or from records
    *	 existing in ARBH
    *****************************************************/
   declare @rcode int
   select @rcode = 0
   select @errmsg = ''
   if @arco is null
   	begin
   	select @errmsg = 'Missing AR Co!', @rcode = 1
   	goto bspexit
   	end
   /* block if records exist for ARCo in ARBH (AR Batch Header) */
   if exists(select * from bARBH b where b.Co = @arco
   and (b.ARTransType = 'M' or b.ARTransType = 'P'))
   	begin
   	select @errmsg = 'Cannot change CM Company -
   		AR Batch entries exist!', @rcode = 1
   	goto bspexit
   	end
   bspexit:
   	if @rcode<>0 select @errmsg=@errmsg			--+ char(13) + char(10) + '[bspARCMCoChangeVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCMCoChangeVal] TO [public]
GO
