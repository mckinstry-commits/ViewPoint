SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRBLRateAmtVal]
   /************************************************************************
   * CREATED: mh 9/12/02    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate Rate Amount for an Override Calculation option.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@overridecalc varchar(1), @rateamt bUnitCost, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @overridecalc is null	
   	begin
   		select @msg = 'Missing Override Calc', @rcode = 1
   		goto bspexit
   	end
   
   	if @rateamt is null
   	begin	
   		select @msg = 'Missing Rate Amount', @rcode = 1
   		goto bspexit
   	end
   
   --Rate must be 0.00 if Override is N.  Otherwise trigger error
   --will occur in btPREDu when you post this to PR
   	if @overridecalc = 'N' and @rateamt <> 0.00
   		begin
   		select @rcode = 1
   		select @msg = 'Rate/Amount must be zero when Calculation Override Option is set to ''N''. '
   		select @rateamt = 0.00
   		end 
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBLRateAmtVal] TO [public]
GO
