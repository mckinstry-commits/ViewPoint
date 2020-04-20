SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCraftClassTempEDLVal    Script Date: 8/28/99 9:33:15 AM ******/
   CREATE    proc [dbo].[bspPRCraftClassTempEDLVal]
   /***************************************************************************************
    * CREATED BY: EN 2/13/00 - created to replace using bspPREarnDedLiabVal to validate Earn, Dedn and Liab codes from PRCraftClassTemp
    *             EN 3/13/00 - if earnings method = 'V' (variable) return old & new rates = 0
    *	       MV 1/22/02 - issue 15711 - validate CalcCategory for ded/liab code	
    *				EN 10/7/02 - issue 18877 change double quotes to single
	*				MV 10/18/10 - #140451 - pretax deduction must be set up at the craft master level first.
    *
    * USAGE:
    * Validates Earn Code from PREC or Dedn/Liab Code from PRDL.
    * If @source = 'V' returns old and new rates from the standard craft class
    * level.  Returns 0 if none is found.
    * If @source = 'O' returns old and new rates first looking for them at the
    * Craft Template level, then the standard craft class level and finally the
    * standard craft level.  Returns 0 if none is found.
    *
    * INPUT PARAMETERS
    *   @prco      PR Co to validate against
    *   @edltype	Code type to validate ('E' = Earnings, 'X' = Dedn or Liab)
    *   @edlcode   Earn/Dedn/Liab code to validate
    *   @craft     Craft code
    *   @class     Class code
    *   @temp      Template code
    *   @source    'V' = variable, 'O' = other
    *   @shift     Shift code (only used if @source = 'V')
    * OUTPUT PARAMETERS
    *   @edltypeout    Code type ('E', 'D', or 'L')
    *   @method
    *   @oldrate  Old rate from PRCI (=0 if earnings method is variable)
    *   @newrate  New rate from PRCI (=0 if earnings method is variable)
    *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ****************************************************************************************/
   
   	(@prco bCompany = 0, @edltype char(1) = null, @edlcode bEDLCode = null, @craft bCraft = null,
   		@class bClass = null, @temp smallint = null, @source char(1) = null, @shift tinyint = null,
           @edltypeout char(1) output, @method varchar(10) output, @oldrate bUnitCost output,
           @newrate bUnitCost output, @msg varchar(250) output)
   as
   
   set nocount on
   
   declare @rcode int, @calccategory varchar (1), @PreTax bYN
   
   select @rcode = 0
   
   -- validate input parameters
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @edltype <> 'E' and @edltype <> 'X'
       begin
       select @msg = 'Code type must be ''E'' or ''X''', @rcode = 1
       goto bspexit
       end
   
   if @edlcode is null
       begin
       if @edltype = 'E'
       	begin
       	select @msg = 'Missing PR Earnings Code!', @rcode = 1
       	goto bspexit
       	end
       if @edltype = 'X'
       	begin
       	select @msg = 'Missing PR Deduction/Liability Code!', @rcode = 1
       	goto bspexit
       	end
       end
   
   if @source <> 'V' and @source <> 'O'
       begin
       select @msg = 'Code type must be ''V'' or ''O''', @rcode = 1
       goto bspexit
       end
   
   -- get description, method and edltypeout
   if @edltype='E'
   	begin
   	select @msg = Description, @method = Method
   		from PREC
   		where PRCo = @prco and EarnCode = @edlcode
   	if @@rowcount = 0
   		begin
   		select @msg = 'PR Earnings Code not on file!', @rcode = 1
   		goto bspexit
   		end
   	select @edltypeout = @edltype
   	end

   IF @edltype='X'
   	BEGIN
   	SELECT @msg = Description, @edltypeout = DLType, @method = Method, @calccategory=CalcCategory, @PreTax = PreTax
   	FROM dbo.PRDL
   	WHERE PRCo = @prco AND DLCode = @edlcode
   	IF @@rowcount = 0
   		BEGIN
   		SELECT @msg = 'PR Deduction/Liability Code not on file!', @rcode = 1
   		GOTO bspexit
   		END
	-- If EDLType is a pretax deduction it must exist in PRCI (PR Craft Master Deductions/Liabilities)
	IF  @edltypeout = 'D' and @PreTax='Y'
		BEGIN
		IF @calccategory <> 'C'
			BEGIN
			SELECT @msg = 'Invalid Calculation Category for Pre-Tax Ded/Liab code.' + char(13)
    		SELECT @msg = @msg + 'Calculation Category must be Craft', @rcode=1
     		GOTO bspexit
			END
		IF NOT EXISTS(SELECT * FROM PRCI WHERE PRCo=@prco AND Craft=@craft AND EDLType='D' AND EDLCode=@edlcode)
			BEGIN
			SELECT @msg = 'Pre tax deductions must be set up at the Craft Master level first.', @rcode = 1
     		GOTO bspexit
			END 
		END
   	IF @calccategory NOT IN ('C','A')
   		BEGIN
   		SELECT @msg = 'Invalid Calculation Category for Ded/Liab code.' + char(13)
   		SELECT @msg = @msg + 'Calculation Category must be Craft or Any', @rcode=1
   		GOTO bspexit
   		END
	
   	end
   
   if @source = 'V'
       -- get old/new rates from PRCE
       select @oldrate = OldRate, @newrate = NewRate
           from bPRCE
           where PRCo = @prco and Craft = @craft and Class = @class and Shift = @shift and EarnCode = @edlcode
   
   if @source = 'O'
       begin
       -- get old/new rates from PRCI
       select @oldrate = OldRate, @newrate = NewRate
           from bPRCI
           where PRCo = @prco and Craft = @craft and EDLType = @edltypeout and EDLCode = @edlcode
       -- get old/new rate overrides from PRCF
       if @edltypeout = 'E'
           select @oldrate = OldRate, @newrate = NewRate
               from bPRCF
               where PRCo = @prco and Craft = @craft and Class = @class and EarnCode = @edlcode
       if @edltypeout <> 'E'
           select @oldrate = OldRate, @newrate = NewRate
               from bPRCD
               where PRCo = @prco and Craft = @craft and Class = @class and DLCode = @edlcode
        -- get old/new rate overrides from PRTI
       select @oldrate = OldRate, @newrate = NewRate
           from bPRTI
           where PRCo = @prco and Craft = @craft and Template = @temp and EDLType = @edltypeout
               and EDLCode = @edlcode
       end
   
   if @oldrate is null or @method = 'V' select @oldrate = 0
   if @newrate is null or @method = 'V' select @newrate = 0
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftClassTempEDLVal] TO [public]
GO
