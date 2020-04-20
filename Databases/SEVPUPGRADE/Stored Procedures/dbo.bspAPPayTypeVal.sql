SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTypeVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE   proc [dbo].[bspAPPayTypeVal]
   /***************************************************
   * CREATED BY    : SAE
   * LAST MODIFIED : SAE
   *              kb 10/28/2 - issue #18878 - fix double quotes
   *				MV 04/09/04 - #18769 paytype cannot be assigned 
   *								to a Pay Category.
   *				MV 02/13/06 - #120219 Pay Type can be assigned to a Pay Category for PR.
   * Usage:
   *   Validates AP Pay Types
   *
   * Input:
   *	@apco         AP Company
   *	@paytype      AP Pay Type
   *
   * Output:
   *   @glacct       Payable GL Account
   *   @msg          Pay Type description or error message
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@apco bCompany = null, @paytype tinyint = 0, @glacct bGLAcct = null output,
       @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @apco is null
   	begin
   	select @msg = 'Missing AP Company', @rcode = 1
   	goto bspexit
   	end
   
   if @paytype is null
   	begin
   	select @msg = 'Missing Pay Type', @rcode = 1
   	goto bspexit
   	end
   
   select @glacct = GLAcct, @msg = Description
   from bAPPT
   where APCo = @apco and PayType = @paytype --and isnull(PayCategory,0) = 0
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Pay Type', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPayTypeVal] TO [public]
GO
