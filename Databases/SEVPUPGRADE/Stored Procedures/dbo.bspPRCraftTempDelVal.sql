SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRCraftTempDelVal]
   /************************************************************************
   * CREATED:  MH 9/10/2004	    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@prco bCompany = 0, @craft bCraft = null, @temp smallint = null, @msg varchar(90) output)
   
   as
   set nocount on
   
       declare @rcode int, @testcraft bCraft
   
       select @rcode = 0
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company!', @rcode = 1
   		goto bspexit
   	end
   
   	if @craft is null
   	begin
   		select @msg = 'Missing PR Craft!', @rcode = 1
   		goto bspexit
   	end
   	
   	if @temp is null
   	begin
   		select @msg = 'Missing PR Template!', @rcode = 1
   		goto bspexit
   	end
   
   	select @testcraft = t.Craft, @msg = m.Description from
   	dbo.PRCT t with (nolock) join dbo.PRCM m with (nolock) on 
   	t.PRCo = m.PRCo and t.Craft = m.Craft
   	where t.Craft = @craft and t.PRCo = @prco and t.Template = @temp
   
   	if @testcraft is null
   	begin
   		select @msg = 'Invalid Craft/Template', @rcode = 1
   		goto bspexit
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftTempDelVal] TO [public]
GO
