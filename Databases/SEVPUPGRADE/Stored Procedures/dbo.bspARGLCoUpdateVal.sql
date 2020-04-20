SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARGLCoUpdateVal    Script Date: 8/28/99 9:34:12 AM ******/
   CREATE  proc [dbo].[bspARGLCoUpdateVal]
   	(@arco bCompany = 0, @glco bCompany = 0, @errmsg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JM 5/9/97
    * MODIFIED By:
    *
    * USAGE:
    *   Validates GLCo update on ARCO maint form
    *   Returns error and can't update errmsg if
    * 	no ARCo passed
    *	no GLCo passed
    *	GLCo not setup in HQCO
    *	ARCo exists in ARTH (AR Transactions Header)
    *	ARCo exists in ARRT (AR Receivable Types)
    *
    *   Returns success and warning errmsg if
    *	GLCo not setup in GLCO
    *
    * INPUT PARAMETERS
    *   ARCo - AR Company to validate against
    *   GLCo - GLCo to validate against
    *
    * OUTPUT PARAMETERS
    *   @errmsg - Desc of GL Co if success or error message if
    *	       error/warning occurs
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
   if @glco is null
   	begin
   	select @errmsg = 'Missing GL Co!', @rcode = 1
   	goto bspexit
   	end
   /* block if GLCo not setup in HQCO */
   select @cnt = count(*) from bHQCO h where h.HQCo = @glco
   if @cnt = 0
   	begin
   	select @errmsg = 'Not a valid GL Company', @rcode = 1
   	goto bspexit
   	end
   --/* block if ARCo exists in ARTH (AR Transactions Header) */
   --select @cnt = count(*) from bARTH t where t.ARCo = @arco
   --if @cnt > 0
   --	begin
   --	select @errmsg = 'Cannot change GL Co - AR Trans exist!', @rcode = 1
   --	goto bspexit
   --	end
   --
   --/* block if ARCo exists in ARRT (AR Receivable Types) */
   --select @cnt = count(*) from bARRT r where r.GLCo <> @glco and r.ARCo = @arco
   --if @cnt > 0
   --	begin
   --	select @errmsg = 'Cannot change GL Co - Rec Types exist!', @rcode = 1
   --	goto bspexit
   --	end
   /* warn if GLCo not setup in GLCO */
   select @cnt = count(*) from bGLCO g where g.GLCo = @glco
   if @cnt = 0
   	begin
   	select @errmsg = 'GL Co not setup in GL - Warning!', @rcode = 2
   	goto bspexit
   	end
   /* pull Desc of GLCo from HQCO if success */
   if exists(select * from bGLCO where GLCo = @glco)
   	begin
   	select @errmsg = Name from bHQCO where HQCo = @glco
   	goto bspexit
   	end
   else
   	begin
   	select @errmsg = 'Not a valid GL Co!', @rcode = 1
   	end
   bspexit:
   	if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARGLCoUpdateVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARGLCoUpdateVal] TO [public]
GO
