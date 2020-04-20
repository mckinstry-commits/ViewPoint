SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspAPPayCategoryVal]
   /***************************************************
   * CREATED BY    : MAV 02/03/04 
   * LAST MODIFIED : Jacob VH 4/25/11 - Added SMPayType
   *             
   *
   * Usage:
   *   Validates AP Pay Category and returns Pay Types and GL Accts
   *
   * Input:
   *	@apco         AP Company
   *	@paycategory  AP Pay Category
   *
   * Output:
   *	@exppaytype	  ExpPayType
   *	@jobpaytype   JobPayType
   *	@subpaytype	  SubPayType
   *	@retpaytype   RetPayType
   *	@SMPayType    SM Pay Type
   *   @discoffglacct DiscOffGLAcct
   *	@disctakenglacct DiscTakenGLAcct
   *   @msg          Pay Category description or error message
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@apco bCompany = null, @paycategory int,@exppaytype tinyint output,
   	 @jobpaytype tinyint output,@subpaytype tinyint output,@retpaytype tinyint output, @SMPayType tinyint OUTPUT,
   	 @discoffglacct bGLAcct output,@disctakenglacct bGLAcct output,@msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @apco is null
   	begin
   	select @msg = 'Missing AP Company', @rcode = 1
   	goto bspexit
   	end
   
   if @paycategory is not null
   begin 
   select @exppaytype = ExpPayType,@jobpaytype = JobPayType,
   	   @subpaytype = SubPayType, @retpaytype=RetPayType, @SMPayType = SMPayType,
   	   @discoffglacct = DiscOffGLAcct,@disctakenglacct=DiscTakenGLAcct,
   	   @msg = Description
   from bAPPC
   where APCo = @apco and PayCategory = @paycategory
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Pay Category', @rcode = 1
   	end
   end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPayCategoryVal] TO [public]
GO
