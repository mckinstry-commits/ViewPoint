SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLFYFiscalYearUnique    Script Date: 8/28/99 9:32:30 AM ******/
   
   
    CREATE     proc [dbo].[bspGLFYFiscalYearUnique]
    /***********************************************************
     * CREATED BY: EN 8/15/02
     * MODIFIED By :	MV 01/31/03 - #20246 dbl quote cleanup.
     *
     * USAGE:
     *   validates GL FiscalYear to make sure it is not already used in GLFY
     *
     * INPUT PARAMETERS
     *   GLCo      	GL Co
     *   FiscalYear	fiscal year
     *
     * OUTPUT PARAMETERS
     *   @msg     Error message if invalid,
     * RETURN VALUE
     *   0 Success
     *   1 fail
     *****************************************************/
   
    (@glco bCompany, @fiscalyear smallint, @msg varchar(100) output)
    as
   
    set nocount on
   
    declare @rcode int, @batchco bCompany, @batchseq int, @batchmth bMonth, @batchid int
   
    select @rcode = 0
   
    if @glco is null
    	begin
    	select @msg = 'Missing GL Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @fiscalyear is null
    	begin
    	select @msg = 'Missing Fiscal Year!', @rcode = 1
    	goto bspexit
    	end
   
    if exists(select * from bGLFY where GLCo = @glco and FiscalYear= @fiscalyear)
       begin
       select @msg = 'Fiscal Year ' + convert(varchar,@fiscalyear) + ' already in use.', @rcode = 1
       goto bspexit
       end
   
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLFYFiscalYearUnique] TO [public]
GO
