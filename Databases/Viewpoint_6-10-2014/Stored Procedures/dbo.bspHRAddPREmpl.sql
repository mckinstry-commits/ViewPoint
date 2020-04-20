SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                    procedure [dbo].[bspHRAddPREmpl]
/****************************************************************
* CREATED BY:	kb 9/1/99
* MODIFIED By : kb 1/19/00 - if trying to add an pr employee and the hr's ssn exists on
*                             some other employee in pr give an error, same with sort name
*				SR 07/29/02 - issue 18003-update PREH with HRRM Suffix field
*				MV 02/03/03 - #20246 dbl quote cleanup. 
*				mh 4/15/03 - #18914 - Shell out to bspHRUpdatePRW4 to insert the Add on info
*							Validate DednCodes.  Verify they are Routine based.
*				mh 7/11/03 - #21033 Centralize PR Validation into bspHRPRDefaultsVal
*				mh 7/23/03 - #18913 Add validation for OccupCat
*				mh 08/15/03 - #17851.  Get GLCo from PRCO and use it in insert into PREH
*				mh 1/13/04 = #23485 - Default PREH.CertYN = 'Y' 
*				mh 08/07/08 - #129198 - Added HDAmt, F1Amt, LCFStock, LCPStock to PREH insert
*				TJL 03/08/10 - #135490, Add new fields for Work Office Tax State and Work Office Local Code 
*				CHS	01/02/2013	- D-05992 TK-20456 145358 fix the omission of Cell Phone
*
* USAGE:
* Called by the HR Resource Master to add record to PREH
*
* INPUT:
*	@hrco		PR Company
*   @prco       PR Company
*   @employee   Beginning Employee or Resource for a range update
*
* OUTPUT:
*   @errmsg		Error message
*
* RETURN:
*   0			Success
*   1			Failure
********************************************************/
		(@hrco bCompany, @prco bCompany, @employee bEmployee, @hrref bHRRef, @msg varchar(200) output)

	as

	set nocount on
    
	declare @rcode int,  @status char(1),  @ssn char(11),
	@race char(2), @prgroup bGroup, @glco bCompany,
	@inscode bInsCode, @craft bCraft, @class bClass, @department bDept,
	@localcode bLocalCode, @sortname bSortName, @w4complete bYN, @earncode bEDLCode,
	@dedncode bEDLCode, @occupcat varchar(10), @opencurs tinyint, @begtrans tinyint,
	@catstatus char(1)
    
   	select @rcode=0, @opencurs = 0, @begtrans = 0
    
   	select @glco = GLCo from dbo.PRCO (nolock) where PRCo = @prco
    
   	select @ssn = SSN, @prco = PRCo, @race = Race, @prgroup = PRGroup,
	@inscode = StdInsCode, @craft = StdCraft, @class = StdClass, @department = PRDept,
	@localcode = StdLocal, @sortname = SortName, @w4complete=W4CompleteYN, 
	@earncode = EarnCode, @occupcat = OccupCat, @catstatus = CatStatus 
	from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref

  	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and SSN is null)
   	begin
   		select @msg = 'HR''s SSN is missing.', @rcode=1
   		goto bspexit
   	end
    
   	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and Race is null)
   	begin
   		select @msg = 'HR''s Race is missing.', @rcode=1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and PRGroup is null)
   	begin
   		select @msg = 'HR''s PRGroup is missing.', @rcode=1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and PRDept is null)
   	begin
   		select @msg = 'HR''s PRDept is missing.', @rcode=1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and StdInsCode is null)
   	begin
   		select @msg = 'HR''s Insurance Code is missing.', @rcode=1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and
   		StdUnempState is null)
   	begin
   		select @msg = 'HR''s Unemployment State is missing.', @rcode=1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and
   		StdInsState is null)
   	begin
   		select @msg = 'HR''s Insurance State is missing.', @rcode=1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.HRRM (nolock) where HRCo = @hrco and HRRef = @hrref and
   		EarnCode is null)
   	begin
   		select @msg = 'HR''s Earning Code is missing.', @rcode = 1
   		goto bspexit
   	end
   
   	if exists(select 1 from dbo.bPREH (nolock) where PRCo = @prco and SSN = @ssn)
   	begin
   		select @msg = 'Employee with this SSN already exists in PR.', @rcode =1
   		goto bspexit
   	end
   
    
   	if exists(select Employee from dbo.bPREH (nolock) where PRCo = @prco and Employee = @employee)
   	begin
   		if (select SSN from dbo.bPREH (nolock) where PRCo = @prco and Employee = @employee) <> @ssn
   		begin
   			select @msg = 'Employee exists in PR with a different SSN', @rcode = 1
   			goto bspexit
   		end
   	end
    
    
   	if exists(select 1 from dbo.bPREH (nolock) where PRCo = @prco and SortName = @sortname)
     	begin
     		select @msg = 'SortName already exists for another employee in PR.',@rcode=1
     		goto bspexit
     	end
   
   	exec @rcode = bspHRPRDefaultsVal @prco, @race, @prgroup, @department, @inscode,
   	@craft, @class, @localcode, @earncode, @occupcat, @catstatus, @msg output
   
   	if @rcode = 1 
   		goto bspexit
    
   begin transaction
   
   	select @begtrans = 1
   --Issue 23485 - set CertYN = 'Y' 
   --Issue #135490 - add WOTaxState, WOLocalCode, UseUnempState, UseInsState
   	INSERT bPREH (
		PRCo, Employee,LastName,FirstName,MidName,
		SortName,Address,City,State,Zip,
		Address2,Phone,CellPhone,SSN,Race,Sex,
		BirthDate,HireDate,TermDate,PRGroup,PRDept,
		Craft,Class,InsCode,TaxState,UnempState,
		InsState,LocalCode,GLCo,UseState,UseLocal,
		UseIns,JCCo,Job,Crew,LastUpdated,EarnCode,
		HrlyRate,SalaryAmt,OTOpt,OTSched,JCFixedRate,
		EMFixedRate,YTDSUI,OccupCat,CatStatus,DirDeposit,
		RoutingId,BankAcct,AcctType,ActiveYN,PensionYN,
		PostToAll,CertYN,ChkSort,AuditYN, Suffix,Email,Shift, Country, 
		HDAmt, F1Amt, LCFStock, LCPStock,
		WOTaxState, WOLocalCode, UseUnempState, UseInsState)    
   	SELECT 
		@prco, @employee, LastName, FirstName, MiddleName,
		SortName,Address,City,State,Zip,
		Address2,Phone,CellPhone,SSN,Race,Sex,
		BirthDate,HireDate,TermDate,PRGroup,PRDept,
		StdCraft,StdClass,StdInsCode,StdTaxState,StdUnempState,
		StdInsState,StdLocal,@glco, 'N', 'N',
		'N', null, null, null, null, 
		EarnCode,0,0,OTOpt,OTSched,
		0,0,0,OccupCat,CatStatus,
		'N', null, null, null, ActiveYN,
		'N','N','Y',null,'Y', 
		Suffix,Email,Shift,Country, HDAmt, F1Amt, LCFStock, LCPStock,
		WOTaxState, WOLocalCode, 'N', 'N'  
	FROM bHRRM 
	WHERE HRCo = @hrco and HRRef = @hrref
   
	if @@rowcount<>0
		update bHRRM set ExistsInPR='Y', PREmp=@employee where HRCo = @hrco and HRRef = @hrref

	if @w4complete ='Y' and exists(select 1 from bHRWI (nolock) where HRCo = @hrco and
		HRRef = @hrref)
	begin
   
   /* Issue 18914 mh 4/15
                     insert bPRED (PRCo, Employee,DLCode,EmplBased,
                         FileStatus,RegExempts,AddExempts,OverMiscAmt,MiscAmt,MiscFactor,
                         OverLimit,NetPayOpt,AddonType, OverCalcs,GLCo)
                     select @prco, @employee, DednCode, 'N',
                         FileStatus, RegExemp,AddionalExemp,isnull(OverrideMiscAmtYN,'N'),MiscAmt1,MiscFactor,
                         'N','N','N','N', @glco from HRWI where HRCo = @hrco and HRRef = @hrref
   */
   
   
   --validate the dls
   			declare cDednCode cursor for
   			select DednCode
   			from HRWI 
   			where HRCo = @hrco and HRRef = @hrref 
   
   			open cDednCode
   			select @opencurs = 1
   
   			fetch next from cDednCode into @dedncode
   
   			while @@fetch_status = 0
   			begin
   		
   				if (select Method from bPRDL (nolock)
   				where PRCo = @prco and DLCode = @dedncode) <> 'R'
   
   				begin
   					select @msg = 'Dedn/Liab code ' + convert(varchar(5), isnull(@dedncode,'')) + ' is not a Routine based deduction.'
   					select @rcode = 1
   					goto bspexit
   				end				
   	
   				fetch next from cDednCode into @dedncode
   			end
   
   			close cDednCode
   			deallocate cDednCode
   			select @opencurs = 0
   
   			exec @rcode = bspHRPRUpdateW4 @hrco, @prco, @hrref, @employee, @msg
   		end
   
   commit transaction
   --end Issue 18914 mh 4/15
   			 
       bspexit:
   
   	if @rcode = 1 and @begtrans = 1
   		rollback transaction
   
   	if @opencurs = 1
   	begin
   		close cDednCode
   		deallocate cDednCode
   	end
   
     	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHRAddPREmpl] TO [public]
GO
