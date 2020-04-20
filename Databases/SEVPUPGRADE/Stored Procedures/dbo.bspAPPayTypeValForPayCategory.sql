SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTypeVal    Script Date: 8/28/99 9:34:03 AM ******/
    CREATE   proc [dbo].[bspAPPayTypeValForPayCategory]
    /***************************************************
    * CREATED BY    : MV 02/06/04
    * LAST MODIFIED :	MV 03/26/04 - #18769 modified validation
    *						per design changes. 
    *
    * Usage:
    *   Validates AP Pay Types by Pay Category
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
    	(@apco bCompany = null, @paycategory int, @paytype tinyint = 0, @glacct bGLAcct = null output,
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
    
    if @paycategory is null
    	begin
    	select @msg = 'Missing AP Pay Category', @rcode = 1
    	goto bspexit
    	end
    
    if @paytype is null
    	begin
    	select @msg = 'Missing Pay Type', @rcode = 1
    	goto bspexit
    	end
    
    select 1 from bAPPT with (nolock)where APCo=@apco and PayType=@paytype and (PayCategory=@paycategory or
    		PayCategory is null)
    if @@rowcount = 0
    	begin
    	select @msg = 'Not a valid Pay Type for this Pay Category', @rcode=1
    	end
    else
    	begin
    	select @glacct = GLAcct, @msg = Description from bAPPT with (nolock)
    		 where APCo = @apco and PayType = @paytype
    	end
    
    
    
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPayTypeValForPayCategory] TO [public]
GO
