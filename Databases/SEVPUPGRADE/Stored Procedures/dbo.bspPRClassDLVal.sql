SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRClassDLVal    Script Date: 8/28/99 9:33:18 AM ******/
     CREATE        proc [dbo].[bspPRClassDLVal]
     /***********************************************************
      * CREATED BY: EN 2/13/00
      *             EN 3/13/00 - if earnings method = 'V' (variable) return old & new rates = 0
      *	        MV 1/22/02 - issue 15711 validate CalcCategory	
      *			EN 10/7/02 - issue 18877 change double quotes to single
	  *			MV 10/18/10 - #140541 - validate pretax deductions - code reviewed by Curtis S.
      * USAGE:
      * validates PR Dedn or Liab Code from PRDL and if code
      * exists in PRCI (Craft Items), return old and new rates.
      *
      * INPUT PARAMETERS
      *   @prco   	PR Company
      *   @craft     Craft code
      *   @dlcode   	Code to validate
      *
      * OUTPUT PARAMETERS
      *   @dltype	Code type ('D', or 'L')
      *   @method	Method
      *   @oldrate	Old Rate from PRCI (=0 if earnings method is variable)
      *   @newrate	New Rate from PRCI (=0 if earnings method is variable)
      *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
      * RETURN VALUE
      *   0         success
      *   1         Failure
      ******************************************************************/
     	(@prco bCompany = 0, @craft bCraft = null, @dlcode bEDLCode = null,
     	@dltype char(1) output, @method varchar(10) output, @oldrate bUnitCost output,
     	@newrate bUnitCost output, @msg varchar(250) output)
     as
     set nocount on
     declare @rcode int, @PRDLdltype char(1), @calccategory varchar (1), @PreTax bYN
     select @rcode = 0
     if @prco is null
     	begin
     	select @msg = 'Missing PR Company!', @rcode = 1
     	goto bspexit
     	end
     if @craft is null
     	begin
     	select @msg = 'Missing PR Craft Code!', @rcode = 1
     	goto bspexit
     	end
     if @dlcode is null
     	begin
     	select @msg = 'Missing PR Deduction/Liability Code!', @rcode = 1
     	goto bspexit
     	end
     
     -- get description, dltype,method and CalcCategory from PRDL
     SELECT @msg=Description, @dltype=DLType, @method=Method, @calccategory=CalcCategory, @PreTax=PreTax
     	FROM dbo.PRDL
     	WHERE PRCo=@prco AND DLCode=@dlcode
     IF @@rowcount = 0
     	BEGIN
     	SELECT @msg = 'PR Deduction/Liability Code not on file!', @rcode = 1
     	GOTO bspexit
     	END

	-- If DLType is a pretax deduction it must exist in PRCI (PR Craft Master Deductions/Liabilities)
	IF  @dltype = 'D' and @PreTax='Y'
		BEGIN
		--validate calc category
		IF @calccategory <> 'C'
			BEGIN
			SELECT @msg = 'Invalid Calculation Category for Pre-Tax Ded/Liab code.' + char(13)
    		SELECT @msg = @msg + 'Calculation Category must be Craft', @rcode=1
     		GOTO bspexit
			END
		IF NOT EXISTS(SELECT * FROM PRCI WHERE PRCo=@prco AND Craft=@craft AND EDLType='D' AND EDLCode=@dlcode)
			BEGIN
			SELECT @msg = 'Pre tax deductions must be set up at the Craft Master level first.', @rcode = 1
     		GOTO bspexit
			END 
		END
      
     if @calccategory not in ('C','A')
     	begin
     	select @msg = 'Invalid Calculation Category for Ded/Liab code.' + char(13)
    	select @msg = @msg + 'Calculation Category must be Craft or Any', @rcode=1
     	goto bspexit
     	end
     
     -- get old/new rates from PRCI
     select @oldrate = OldRate, @newrate = NewRate
         from bPRCI
         where PRCo = @prco and Craft = @craft and EDLType = @dltype and EDLCode = @dlcode
     
     if @oldrate is null or @method = 'V' select @oldrate = 0
     if @newrate is null or @method = 'V' select @newrate = 0
     
     
     bspexit:
     
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRClassDLVal] TO [public]
GO
