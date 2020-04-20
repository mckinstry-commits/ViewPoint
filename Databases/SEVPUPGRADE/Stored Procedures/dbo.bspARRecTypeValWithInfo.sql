SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARRecTypeValWithInfo    Script Date: 8/28/99 9:32:36 AM ******/
   CREATE PROC [dbo].[bspARRecTypeValWithInfo]
   /***********************************************************
   * CREATED BY: CJW 6/2/97
   * MODIFIED By : CJW 6/2/97
   *		TJL 01/27/04:  Issue #20394, Return GLFCWriteOffAcct, Add nolocks
   *
   * USAGE:
   * 	validates Receivable Types in ARRT
   *
   * INPUT PARAMETERS
   *   AR Company
   *   Receivable Type to validate
   *
   * OUTPUT PARAMETERS
   *   @msg      Description or error message
   * RETURN VALUE
   *   0         success
   *   1         failure
   *****************************************************/
   (@arco bCompany = null, @rectype int = null,  @glrevacct bGLAcct output, @glwriteoffacct bGLAcct output,
   	@glfinchgacct bGLAcct output, @glfcwriteoffacct bGLAcct output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   if @arco is null
   	begin
   	select @msg = 'Missing AR Company!', @rcode = 1
   	goto bspexit
   	end
   if @rectype is null
   	begin
   	select @msg = 'Missing Receivable Type!', @rcode = 1
   	goto bspexit
   	end
   
   /* Standard RecType Validation. */
   exec @rcode =  bspARRecTypeVal @arco, @rectype,  @msg output
   if @rcode = 1 goto bspexit
   
   /* Get some account information. */
   select @glrevacct = GLRevAcct, @glwriteoffacct = GLWriteOffAcct, @msg = Description,
   		@glfinchgacct = GLFinChgAcct, @glfcwriteoffacct = GLFCWriteOffAcct 
   from ARRT with (nolock)
   where RecType = @rectype and ARCo = @arco
   
   bspexit:
   	if @rcode<>0 select @msg=@msg		--+ char(13) + char(10) + '[bspARRecTypeValWithInfo]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARRecTypeValWithInfo] TO [public]
GO
