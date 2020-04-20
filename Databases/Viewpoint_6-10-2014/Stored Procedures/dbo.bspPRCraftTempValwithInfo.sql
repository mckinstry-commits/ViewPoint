SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRCraftTempValwithInfo]
   /************************************************************************
   * CREATED:	mh 9/24/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate a Craft Template and return override info along with 
   *	Old/New Cap limits 
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
        
       (@prco bCompany, @craft bCraft, @class bClass, @temp smallint, @nocapcodes bYN output, 
   	@oldlimit bUnitCost output, @newlimit bUnitCost output, @msg varchar(90) output)
   
   as
   set nocount on
   
       declare @rcode int
   
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
   
   	exec @rcode = bspPRCraftTempVal @prco, @craft, @temp, @msg output
   
   	if @rcode = 0
   	begin
   		if not exists(select 1 from dbo.PRCS with (nolock) where PRCo = @prco and Craft = @craft)
   			select @nocapcodes = 'N'
   		else
   			select @nocapcodes = 'Y'
   
   		select @oldlimit = isnull(OldCapLimit,0), @newlimit = isnull(NewCapLimit,0) 
   		from dbo.PRCC with (nolock) 
   		where PRCo = @prco and Craft = @craft and Class = @class
   
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftTempValwithInfo] TO [public]
GO
