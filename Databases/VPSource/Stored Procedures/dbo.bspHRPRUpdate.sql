SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                      procedure [dbo].[bspHRPRUpdate]
  /************************************************************************
  * CREATED:	MH
  * MODIFIED:	MH 1/9/02 - Issue 15496  Need to allows cross company updates. 
  *		allenn 05/14/02 - issue 17359
  *			SR 07/29/02 - issue 18003-update PREH with HRRM Suffix if Updating Name is checked in HRCO
  *			mh 5/7/03 - issue 19538
  *			mh 11/17/03 issue 18913 
  *			mh 1/18/06	issue 28966 and 119921
  *			EN 8/30/06 - Issue 120519 added NonResAlienYN flag update
  *			MH 02/22/2008 - Issue 29630 cross update Shift
  * Purpose of Stored Procedure
  *
  *	Update PREH with changes in HRRM.  Changes are dependent on flags set in HRCO.
  *
  *
  * Notes about Stored Procedure
  *
  *	Changes to this sp should be implemented into PR sister procedure bspPRHRUpdate
  *
  * returns 0 if successfull
  * returns 1 and error msg if failed
  *
  *************************************************************************/
  
 	(@hrco bCompany, @prco bCompany, @hrref bHRRef, @employee bEmployee, @msg varchar(80) = '' output)
  
 	as
 	set nocount on
  
 	declare @rcode int,  @updatenameyn bYN, @updateaddressyn  bYN, @updatehiredateyn bYN,
 	@updateactiveyn bYN, @updateprgroupyn bYN, @updatetimecardyn bYN, @updatew4yn bYN, @err int,
 	@updateoccupyn bYN, @updatessnyn bYN
  
 	select @rcode = 0, @err = 0
 	
 	--Get the update flags from HRCO
 	
 	select @updatenameyn = UpdateNameYN, @updateaddressyn = UpdateAddressYN,
 	@updatehiredateyn = UpdateHireDateYN, @updateactiveyn = UpdateActiveYN,
 	@updateprgroupyn = UpdatePRGroupYN, @updatetimecardyn = UpdateTimecardYN,
 	@updatew4yn = UpdateW4YN, @updateoccupyn = UpdateOccupCatYN, @updatessnyn = UpdateSSNYN
 	from HRCO with (nolock)
 	where HRCo = @hrco
 
  
  	begin transaction
  
 	if @updateoccupyn = 'Y'
 	begin
 		update bPREH
 		set OccupCat = h.OccupCat, CatStatus = h.CatStatus
 		from bHRRM h, bPREH p
 		where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref
 		
 		if @@rowcount <> 1
 		begin
 			select @err = 1
 			goto bspexit
 		end
 	end
 
 
  	if @updatenameyn = 'Y'
  	begin
 
 		update bPREH
 		set LastName = h.LastName, FirstName = h.FirstName, MidName = h.MiddleName, Suffix=h.Suffix,
 		SortName = h.SortName, BirthDate = h.BirthDate, Race = h.Race, Sex = h.Sex
 		from bHRRM h, bPREH p
 		where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref
 		
 		if @@rowcount <> 1
 		begin
 			select @err = 1
 			goto bspexit
 		end
  
  	end
  
 	if @updateaddressyn = 'Y'
 	begin
 	
 		update bPREH
 		set Address = h.Address, Address2 = h.Address2, City = h.City, State = h.State,
 		Zip = h.Zip, Phone = h.Phone, Email = h.Email
 		from bHRRM h, bPREH p
 		where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref
 		
 		if @@rowcount <> 1
 		begin
 			select @err = 1
 			goto bspexit
 		end
 	
 	end
  
  
 	if @updatetimecardyn = 'Y'
 	begin
--Issue 119921 	
 		update bPREH
 		set PRDept = h.PRDept, Craft = h.StdCraft, Class = h.StdClass, InsCode = h.StdInsCode,
 		TaxState = h.StdTaxState, UnempState = h.StdUnempState, InsState = h.StdInsState,
 		LocalCode = h.StdLocal, /*SSN = h.SSN,*/ EarnCode = h.EarnCode, Shift = h.Shift
 		from bHRRM h, bPREH p
 		where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref
 	
 		if @@rowcount <> 1
 		begin
 			select @err = 1
 			goto bspexit
 		end
 
 --17851
 		if (select GLCo from bPREH p , bHRRM h where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref) is null
 			update bPREH 
 			set GLCo = (select GLCo from bPRCO where PRCo = @prco)
 			from bHRRM h, bPREH p
 			where p.PRCo = @prco and p.Employee = @employee and 
 			h.HRCo = @hrco and h.HRRef = @hrref
 	
 	end
  
  /*  Issue 19538 - Moved this to the btHRRMu update trigger.  mh 5/7/03
  			update PREH
  			set PRGroup = h.PRGroup
  			from HRRM h, PREH p
  			where p.PRCo = @prco and p.Employee = @employee and 
  				h.HRCo = @hrco and h.HRRef = @hrref
  
  
  			if @@rowcount <> 1
  			begin
  				select @err = 1
  				goto bspexit
  			end
  --		end
  	end
  */
  
  	if @updatehiredateyn = 'Y'
  	begin
 
 		update bPREH
 		set HireDate = h.HireDate, TermDate = h.TermDate
 		from bHRRM h, bPREH p
 		where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref
 		
 		if @@rowcount <> 1
 		begin
 			select @err = 1
 			goto bspexit
 		end
  
  	end
  
 	if @updateactiveyn = 'Y'
 	begin
 	
 		update bPREH
 		set ActiveYN = h.ActiveYN
 		from bHRRM h, bPREH p
 		where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref
 	
 		if @@rowcount <> 1
 		begin
 			select @err = 1
 			goto bspexit
 		end
 	
 	end

--Issue 28966
	if @updatessnyn = 'Y'
	begin

 		update bPREH
 		set SSN = h.SSN
 		from bHRRM h, bPREH p
 		where p.PRCo = @prco and p.Employee = @employee and 
 		h.HRCo = @hrco and h.HRRef = @hrref
 	 	
 		if @@rowcount <> 1
 		begin
 			select @err = 1
 			goto bspexit
 		end  

	end

	--issue 120519
 	if @updatew4yn = 'Y'
  	begin
		update bPREH
  		set NonResAlienYN = h.NonResAlienYN
		from bHRRM h, bPREH p
		where p.PRCo = @prco and p.Employee = @employee and 
		h.HRCo = @hrco and h.HRRef = @hrref
 	 	
		if @@rowcount <> 1
		begin
			select @err = 1
			goto bspexit
		end  
  	end

 bspexit:
 
 	if @err = 1
 	begin
 		rollback transaction
 		select @msg = 'Error updating PR Employee Master'
 	end
 	else
 		commit transaction
 	
 		select @rcode = @err
 		return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRUpdate] TO [public]
GO
