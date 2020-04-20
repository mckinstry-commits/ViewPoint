SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARGLCoChangeVal    Script Date: 8/28/99 9:34:12 AM ******/
   CREATE  proc [dbo].[bspARGLCoChangeVal]
   	(@arco bCompany = 0, @errmsg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JM 10/13/97
    * MODIFIED By:
    *
    * USAGE:
    *   Validates if revision to ARCo.GLCo is OK
    *   Returns error and can't update errmsg if
    * 	no ARCo passed
    *	ARCo exists in ARTH (AR Transactions Header)
    *	ARCo exists in ARRT (AR Receivable Types)
    *
    *   Returns success, or error if test fails
    *
    * INPUT PARAMETERS
    *   glco - GL Company to validate against
    *
    * OUTPUT PARAMETERS
    *	@rcode only
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure from a missing input or from records
    *	 existing in ARTH or ARRT
    *****************************************************/
   declare @rcode int
   select @rcode = 0
   select @errmsg = ''
   if @arco is null
   	begin
   	select @errmsg = 'Missing AR Co!', @rcode = 1
   	goto bspexit
   	end
   if exists(select * from bARTH t where t.ARCo = @arco)
   	begin
   	select @errmsg = 'Cannot change GL Company -
   		AR Transaction entries exist!', @rcode = 1
   	goto bspexit
   	end
   if exists(select * from bARRT r where r.ARCo = @arco)
   	begin
   	select @errmsg = 'Cannot change GL Company -
   		AR Rec Type entries exist!', @rcode = 1
   	goto bspexit
   	end
   bspexit:
   	if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARGLCoChangeVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARGLCoChangeVal] TO [public]
GO
