SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            procedure [dbo].[bspHRPRUpdateW4]
     /************************************************************************
     * CREATED:	MH 10/11/01    
     * MODIFIED: MH 2/14/02 issue #18914 - added AddonRate and AddonRateAmt
     *						to insert and updates to PRED.
      *			 mh 4/2/03	more issue 18914 - AddonType cannot be defaulted to 'N' on
      *						an insert like before. Prior to 18914, AddonRateAmt was always
     						0.00 and therefore AddonType cannot always be 'N'.  Since we can now
     						specify AddonRateAmt in HR, AddonType can no longer be hard coded.
     						Corrected oversite.
     *			mh 4/16/03  Corrected parameter list.  Was not supporting cross company insert/updates.
     *						For instance, HRCo = 1 and PRCo = 2
     *			mh 5/1/03 - Changed AddonRateAmt to bUnitCost
     *			mh 9/30/2004 - 25519.  Added .dbo prefix.  Included GLCo in cursor select.
	 *			mh 09/27/07 - Issue 120592. Need to grab vendor group from PRDL and update it 
     *						to PRED.   
     *
     * Purpose of Stored Procedure
     *
     *	Cross update HR W4 info to PR     
     *    
     *           
     * Notes about Stored Procedure
     * 
     *	Sister procedure is bspPRHRUpdateW4
     *
     * returns 0 if successfull 
     * returns 1 and error msg if failed
     *
     *************************************************************************/
     
     
   	(@hrco bCompany, @prco bCompany, @hrref bHRRef, @employee bEmployee, @errmsg varchar(100) = '' output)
   	
   	as
   	set nocount on
     
   	declare @rcode int, @dedncode bEDLCode, @regexemp tinyint, @filestatus char(1), 
   	@addionalexemp int, @overridemiscamtyn bYN, @miscamt1 bDollar, @miscfactor bRate,
   	@glco bCompany, @addontype char(1), @addonrateamt bUnitCost, @opencurs tinyint,
	@vendorgrp bGroup
   
   	select @rcode = 0
    
    	--issue 18914 - Need to validate the deductions.  Can only add Routine
   	--based deductions.
   
   	--looking to see if any deduction is not Method 'R'.  
    	select @dedncode = min(h.DednCode)
    	from dbo.bHRWI h with (nolock)
   	join dbo.bHRRM m with (nolock) on h.HRCo = m.HRCo and h.HRRef = m.HRRef 
   	join dbo.bPRDL p with (nolock) on m.PRCo = p.PRCo and h.DednCode = p.DLCode
    	where h.HRCo = @hrco and h.HRRef = @hrref and Method <> 'R'
   
   	if @dedncode is not null
   	begin
   		select @errmsg = 'Cannot update PR.  Dedn/Liab code ' + convert(varchar(5), @dedncode) + ' is not a Routine based deduction.  Filing status must be null.'
   		select @rcode = 1
   		goto bspexit
   	end		
   
   	--select @glco = GLCo from dbo.bPRCO with (nolock) where PRCo = @prco
    
   	declare w4Updatecurs cursor local fast_forward for
   	
   	select i.DednCode, i.FileStatus, i.RegExemp, i.AddionalExemp,
   	i.OverrideMiscAmtYN, i.MiscAmt1, i.MiscFactor, i.AddonType, i.AddonRateAmt, c.GLCo, p.VendorGroup
   	from dbo.bHRWI i with (nolock)
   	join dbo.bHRRM m with (nolock) on i.HRCo = m.HRCo and i.HRRef = m.HRRef
   	join dbo.bPRDL p with (nolock) on m.PRCo = p.PRCo and i.DednCode = p.DLCode
   	join dbo.bPRCO c with (nolock) on m.PRCo = c.PRCo
   	where i.HRCo = @hrco and i.HRRef = @hrref
   	
   	open w4Updatecurs 
   	select @opencurs = 1
   	
   	fetch next from w4Updatecurs into 
   
   	@dedncode, @filestatus, @regexemp, @addionalexemp, @overridemiscamtyn, @miscamt1, @miscfactor, 
   	@addontype, @addonrateamt, @glco, @vendorgrp
   
   	while @@fetch_status = 0
   	begin
   
     		if exists(select 1 from bPRED with (nolock) where PRCo = @prco and Employee = @employee and 
     			DLCode = @dedncode)	
     
     	        update dbo.bPRED set FileStatus = @filestatus, RegExempts = @regexemp,
         	    AddExempts = @addionalexemp, OverMiscAmt = @overridemiscamtyn,
             	MiscAmt = @miscamt1, MiscFactor = @miscfactor, AddonType = @addontype,
     			AddonRateAmt = @addonrateamt, VendorGroup = @vendorgrp
     			where PRCo = @prco and Employee = @employee and DLCode = @dedncode	  
     
     		else
   
      			insert dbo.bPRED (PRCo, Employee,DLCode,EmplBased, FileStatus,RegExempts,
      			AddExempts,OverMiscAmt,MiscAmt,MiscFactor, OverLimit,NetPayOpt,
      			AddonType, OverCalcs,GLCo, AddonRateAmt, VendorGroup)
      			values (@prco, @employee, @dedncode, 'N', @filestatus, @regexemp, 
      			@addionalexemp, @overridemiscamtyn, @miscamt1, @miscfactor, 'N', 'N', 
      			@addontype, 'N', @glco, @addonrateamt, @vendorgrp) 
   
   		fetch next from w4Updatecurs into 
   		
   		@dedncode, @filestatus, @regexemp, @addionalexemp, @overridemiscamtyn, @miscamt1, @miscfactor, 
   		@addontype, @addonrateamt, @glco, @vendorgrp
   
   	end
   
     
   bspexit:
    
   	if @opencurs = 1
   	begin
   		close w4Updatecurs
   		deallocate w4Updatecurs
   	end
   	
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRUpdateW4] TO [public]
GO
