SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPRCraftClassTempPayRateVal]
     /************************************************************************
     * CREATED:  mh 9/13/2004    
     * MODIFIED:    
     *
     * Purpose of Stored Procedure
     *
     *   Get Old and New rates from PRCP.  Used for defaults 
     *	in PR Craft Class Template
     *    
     *           
     * Notes about Stored Procedure
     * 
     *
     * returns 0 if successfull 
     * returns 1 and error msg if failed
     *
     *************************************************************************/
     
         (@prco bCompany = null, @craft bCraft = null, @class bClass = null, @shift tinyint, 
     	 @oldrate bUnitCost output, @newrate bUnitCost output, @msg varchar(80) = '' output)
     
     as
     set nocount on
     
         declare @rcode int
     
         select @rcode = 0
     
     	if @prco is null
     	begin
     		select @msg = 'Missing PR Company.', @rcode = 1
     		goto bspexit
     	end
     
     	if @craft is null
     	begin
     		select @msg = 'Missing Craft.', @rcode = 1
     		goto bspexit
     	end
     
     	if @shift is null
     	begin
     		select @msg = 'Missing Shift.', @rcode = 1
     		goto bspexit
     	end
     
     	select @oldrate = OldRate, @newrate = NewRate from dbo.PRCP with (nolock)
     	where PRCo = @prco and Craft = @craft and Class = @class and Shift = @shift
     
     	/*
     	isnull function will not work with above.  I need @oldrate and @newrate to be 0.00
     	even if no row exists.  isnull will return 0 only if the row exists but the rate is null
     	*/
     	if @oldrate is null
     		select @oldrate = 0
     
     	if @newrate is null
     		select @newrate = 0
     
     
     bspexit:
     
          return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftClassTempPayRateVal] TO [public]
GO
