SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTypeVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE    proc [dbo].[vspAPPayTypeVal]
/***************************************************
* CREATED BY    : MV 05/11/05
* Modified by	: MV 01/07/09 - #131682 - for null paycategory commented out isnull clause
*				CHS 01/09/2012	B-08282 fixed problem when patcategory is null
*
* Usage:
*   Validates AP Pay Types with or without Pay Category
*
* Input:
*	@apco         AP Company
*   @paycategory
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
   	(@apco bCompany = null, @paycategory int = null, @paytype tinyint = 0, @glacct bGLAcct = null output,
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

	if @paycategory is not null 
	begin
		if not exists (select 1 from bAPPT with (nolock)where APCo=@apco and PayType=@paytype and (PayCategory=@paycategory or
		   		PayCategory is null))
		   	begin
		   	select @msg = 'Not a valid Pay Type for this Pay Category', @rcode=1
		   	end
		else
		   	begin
		   	select @glacct = GLAcct, @msg = Description from bAPPT with (nolock)
		   		 where APCo = @apco and PayType = @paytype
		   	end
	end   

	if @paycategory is null
	begin
		 select @glacct = GLAcct, @msg = Description
		  from bAPPT with (nolock)
		  where APCo = @apco and PayType = @paytype --and isnull(PayCategory,0) = 0
		  if @@rowcount = 0
		  	begin
		  	select @msg = 'Not a valid Pay Type', @rcode = 1
		  	end
	end

    
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPayTypeVal] TO [public]
GO
