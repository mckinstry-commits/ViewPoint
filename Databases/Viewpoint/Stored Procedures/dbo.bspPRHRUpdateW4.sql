SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRHRUpdateW4    Script Date: 5/1/2003 10:58:30 AM ******/
    
    /****** Object:  Stored Procedure dbo.bspPRHRUpdateW4    Script Date: 2/21/2003 7:33:15 AM ******/
    
    /****** Object:  Stored Procedure dbo.bspPRHRUpdateW4    Script Date: 2/14/2003 8:25:36 AM ******/
    
    /****** Object:  Stored Procedure dbo.bspPRHRUpdateW4    Script Date: 10/11/2001 2:41:49 PM ******/
    
    CREATE        procedure [dbo].[bspPRHRUpdateW4]
    /************************************************************************
    * CREATED:	MH 10/11/01    
    * MODIFIED: 5/1/03 - Changed AddonRateAmt to bUnitCost   
	*			EN 10/14/2009 #133605 verify that only dedns are copied to HRWI, not liabs such as AUS superannuation liab
    *
    * Purpose of Stored Procedure
    *
    *	Cross update HR with PR W4 info.    
    *    
    *           
    * Notes about Stored Procedure
    * 
    *	Sister procedure is bspHRPRUpdateW4
    *	
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
        (@prco bCompany, @employee bEmployee, @errmsg varchar(80) = '' output)
    
    as
    set nocount on
    
    
   	declare @dlcode bEDLCode, @DednCode bEDLCode, @regexemp tinyint, 
   	@filestatus char(1), @addionalexemp int, @overridemiscamtyn bYN,
   	@miscamt1 bDollar, @miscfactor bRate, @hrco bCompany, @hrref bEmployee,
   	@addontype char(1), @addonrateamt bUnitCost, @opencurs tinyint, @rcode int
   
   	select @rcode = 0
   
   	declare w4Update_curs cursor fast_forward for 
   
   	select d.DLCode, d.FileStatus, d.RegExempts, d.AddExempts, d.OverMiscAmt,
   	isnull(d.MiscAmt, 0) as 'MiscAmt', isnull(d.MiscFactor, 0) as 'MiscFactor', 
   	d.AddonType, d.AddonRateAmt, h.HRCo, h.HRRef
   	from bPRED d with (nolock)
   	join bPRDL l with (nolock) on d.PRCo = l.PRCo and d.DLCode = l.DLCode
   	join bHRRM h with (nolock) on d.PRCo = h.PRCo and d.Employee = h.PREmp
   	where d.PRCo = @prco and d.Employee = @employee and l.Method = 'R' and l.DLType = 'D' --#133605 added Type check
   
   	open w4Update_curs
   	select @opencurs = 1
   
   	fetch next from w4Update_curs into
   	@dlcode, @filestatus, @regexemp, @addionalexemp, @overridemiscamtyn,  
   	@miscamt1, @miscfactor, @addontype, @addonrateamt, @hrco, @hrref
   
   	while @@fetch_status = 0
   	begin
   
    		if exists (select 1 from bHRWI with (nolock) 
   					where HRCo = @hrco and HRRef = @hrref and 
   					DednCode = @dlcode)
            
   			update bHRWI set FileStatus = @filestatus, RegExemp = @regexemp,
   			AddionalExemp = @addionalexemp, OverrideMiscAmtYN = @overridemiscamtyn,
   			MiscAmt1 = @miscamt1, MiscFactor = @miscfactor, AddonType = @addontype,
   			AddonRateAmt = @addonrateamt
   			from bHRWI 
   			where HRCo = @hrco and HRRef = @hrref  and DednCode = @dlcode
   
   		else
   
   			insert bHRWI ( HRCo, HRRef, DednCode, FileStatus, RegExemp, 
   			AddionalExemp, OverrideMiscAmtYN, MiscAmt1, MiscFactor, 
   			AddonType, AddonRateAmt)
   			values (@hrco, @hrref, @dlcode, @filestatus, @regexemp, 
   			@addionalexemp, @overridemiscamtyn, @miscamt1, @miscfactor, 
   			@addontype, @addonrateamt)
   
   			--make sure W4 complete flag is updated.
   			if exists (select 1 from bHRWI with (nolock) where HRCo = @hrco and HRRef = @hrref)
   				update bHRRM set W4CompleteYN = 'Y' where HRCo = @hrco and HRRef = @hrref
   			else
   				update bHRRM set W4CompleteYN = 'N' where HRCo = @hrco and HRRef = @hrref
   
   			fetch next from w4Update_curs into
   			@dlcode, @filestatus, @regexemp, @addionalexemp, @overridemiscamtyn,  
   			@miscamt1, @miscfactor, @addontype, @addonrateamt, @hrco, @hrref
   		   
   	end
    
    
    bspexit:
    
   	if @opencurs = 1
   	begin
   		close w4Update_curs
   		deallocate w4Update_curs
   	end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHRUpdateW4] TO [public]
GO
