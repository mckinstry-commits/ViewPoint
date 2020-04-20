SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSPriceTemplateVal]
   /*************************************
   * Created By:   GF 02/26/2000
   * Modified By:
   *
   * validates MS Price Template
   *
   * Pass:
   *	MS Company and MS Price Template to be validated
   *
   * Success returns:
   *	0 and Description from bMSTH
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @pricetemplate smallint = null, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @pricetemplate is null
   	begin
   	select @msg = 'Missing MS Price Template', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bMSTH where MSCo=@msco and PriceTemplate = @pricetemplate
       if @@rowcount = 0
           begin
   		select @msg = 'Not a valid MS Price Template', @rcode = 1
           goto bspexit
   		end



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPriceTemplateVal] TO [public]
GO
