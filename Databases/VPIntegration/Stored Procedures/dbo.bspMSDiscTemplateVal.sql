SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSDiscTemplateVal]
   /*************************************
   * Created By:   GF 02/24/2000
   * Modified By:
   *
   * validates MS Discount Template
   *
   * Pass:
   *	MS Company and MS Discount Template to be validated
   *
   * Success returns:
   *	0 and Description from bMSDH
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @disctemplate smallint = null, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @disctemplate is null
   	begin
   	select @msg = 'Missing MS Discount Template', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bMSDH where MSCo=@msco and DiscTemplate = @disctemplate
       if @@rowcount = 0
           begin
   		select @msg = 'Not a valid MS Discount Template', @rcode = 1
           goto bspexit
   		end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSDiscTemplateVal] TO [public]
GO
