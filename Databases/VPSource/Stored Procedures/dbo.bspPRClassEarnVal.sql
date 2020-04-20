SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRClassEarnVal    Script Date: 8/28/99 9:33:15 AM ******/
   CREATE  proc [dbo].[bspPRClassEarnVal]
   /***************************************************************************************
    * CREATED BY: kb 11/19/97
    * MODIFIED By : kb 11/19/97
    *               EN 2/13/00 - added output params for PRCI oldrate and newrate and ability to suppress PRCF/PRCE validation for use by PRCraftTemplate
    *               EN 3/13/00 - if earnings method = 'V' (variable) return old & new rates = 0
    *				EN 10/7/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Earn Code from PREC, called from PRCraftClass
    * an error is returned if any of the following occurs
    *   -no PRCompany is sent
    *   -no earning code is sent
    *   -earning code does not exist for this company
    *   -earnings code is used as an addon for this craft class
    *
    * INPUT PARAMETERS
    *   @prco      PR Co to validate against
    *   @edlcode   Earnings code to validate against
    *   @craft     Craft code
    *   @class     Class code
    *   @source    'V' = variable, 'A' = addon, 'X' = do not validate in PRCF/PRCE
    * OUTPUT PARAMETERS
    *   @method
    *   @oldrate  Old rate from PRCI (=0 if earnings method is variable)
    *   @newrate  New rate from PRCI (=0 if earnings method is variable)
    *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ****************************************************************************************/
   
   	(@prco bCompany = 0, @edlcode bEDLCode = null, @craft bCraft=null,
   		@class bClass=null, @source char(1)=null, @method varchar(10) output,
   		@oldrate bUnitCost output, @newrate bUnitCost output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @edlcode is null
   	begin
   	select @msg = 'Missing PR Earnings Code!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @method=Method
   	from PREC where PRCo = @prco and EarnCode=@edlcode
   
   
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Earnings Code not on file!', @rcode = 1
   
   	goto bspexit
   	end
   
   if @source='V'
   	begin
   	if exists(select * from PRCF where PRCo=@prco and EarnCode=@edlcode
   		and Craft=@craft and Class=@class)
   		begin
   		select @msg = 'Variable earnings code must not be used as an addon', @rcode=1
   		goto bspexit
   		end
   	end
   if @source='A'
   	begin
   	if exists(select * from PRCE where PRCo=@prco and EarnCode=@edlcode
   		and Craft=@craft and Class=@class)
   		begin
   		select @msg = 'This earnings code exists as a variable earnings code.', @rcode=1
   		goto bspexit
   		end
   	end
   
   -- get old/new rates from PRCI
   select @oldrate = OldRate, @newrate = NewRate
       from bPRCI
       where PRCo = @prco and Craft = @craft and EDLType = 'E' and EDLCode = @edlcode
   
   if @oldrate is null or @method = 'V' select @oldrate = 0
   if @newrate is null or @method = 'V' select @newrate = 0
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRClassEarnVal] TO [public]
GO
