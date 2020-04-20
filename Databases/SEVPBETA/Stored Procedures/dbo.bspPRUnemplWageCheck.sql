SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUnemplWageCheck    Script Date: 10/23/2003 ******/
   CREATE    procedure [dbo].[bspPRUnemplWageCheck]
   /************************************************************
    * Created By:	GF 10/23/2003
    * MODIFIED By:	GF 11/06/2003 - issue #22884 - changed description to electronic filing
    *				GF 01/21/2005 - issue #26901 - for NY last quarter (12) show employees w/SUI Wages = zero
    *				GF 03/15/2005 - issue #27361 - 'MN' uses gross wages for total wages not SUI
    *				GF 07/14/2005 - issue #29280 - 'MN' change to SUI wages.
    *				GF 05/04/2007 - issue #124487 - 'ME' allows for employees with no SUTA wages.
    *				MH 11/06/2007 - issue #126041 -  'KS' allows for employees with no SUTA wages.
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
	*				mh 01/21/09 - #131924 'CA' may have employees with no suta but still need to be reported
	*					due to PIT reporting requirements.
	*				mh 05/17/10 - 139559 MA using a combined reporting system.  May have employees with no
	*					SUTA but income tax.
    *
    *
    *
    * USAGE:
    * Called from PRUnemplGenerate to check for employees with negative or zero SUI wages.
    * Returns warning message if true.
    *
    *
    *
    * INPUT PARAMETERS
    *   @prco      PR Co#
    *   @state		PR State
    *   @quarter   quarter ending month
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0   	success
    *   1   	fail
    ************************************************************/
   @prco bCompany, @state varchar(4), @quarter bMonth, @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int, @negative_count int, @zero_count int
   
   select @rcode = 0, @negative_count = 0, @zero_count = 0, @errmsg = ''
   
---- 'ME' and 'KS' - may have employees with no suta, but still need to generate because of state tax
--if @state = 'ME' goto bspexit
--if @state = 'KS' goto bspexit
if @state = 'ME' or @state = 'KS' or @state = 'CA' or @state = 'MA'
begin
	goto bspexit
end

   -- -- -- 'MN' uses gross wages and the state calculates taxes owed.
   -- -- -- issue #29280 - changed to use SUIWages
   if @state = 'MN'
   	begin
   	-- -- -- count employees with negative SUI Wages
   	select @negative_count = count(*) from bPRUE with (nolock)
   	where PRCo=@prco and State=@state and Quarter=@quarter and SUIWages < 0
   	-- -- -- count employees with zero SUI Wages
   	select @zero_count = count(*) from bPRUE with (nolock)
   	where PRCo=@prco and State=@state and Quarter=@quarter and SUIWages = 0
   	if @negative_count = 0 and @zero_count = 0 goto bspexit
   	goto build_msg
   	end
   else
   	begin
   	-- -- -- count employees with negative SUI Wages
   	select @negative_count = count(*) from bPRUE with (nolock)
   	where PRCo=@prco and State=@state and Quarter=@quarter and SUIWages < 0
   	-- -- -- count employees with zero SUI Wages
   	select @zero_count = count(*) from bPRUE with (nolock)
   	where PRCo=@prco and State=@state and Quarter=@quarter and SUIWages = 0
   	if @negative_count = 0 and @zero_count = 0 goto bspexit
   	-- -- -- 4 quarter for 'NY' need to include employees with no SUI wages
   	if @zero_count <> 0 and @state = 'NY' and month(@quarter) = 12 goto bspexit
   	goto build_msg
   	end
   
   
   build_msg:
   if @negative_count <> 0
   	set @errmsg = 'There are ' + convert(varchar(6),@negative_count) + ' employees with negative wages.' + CHAR(13)
   
   if @zero_count <> 0
   	set @errmsg = @errmsg + 'There are ' + convert(varchar(6),@zero_count) + ' employees with zero wages.' + CHAR(13)
   
   
   
   
   
   set @errmsg = @errmsg + 'These employees will not be included in the electronic filing.' + CHAR(13)
   set @rcode = 1
   
   
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRUnemplWageCheck] TO [public]
GO
