SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE                     procedure [dbo].[bspPRHRUpdate]
 	/************************************************************************
 	* CREATED:	MH 8/23/01    
 	* MODIFIED:	GG 11/07/01 - #15198 - Clear TermReason if TermDate is null  
 	* 			MH 1/9/02 - Issue 15496  Need to allows cross company updates. 
 	*		allenn 05/14/02 - issue 17359
 	*			SR 09/16/02 issue 17850 & 18003
 	*          DANF 12/13/02 - Added isnull to hire and term date.
 	*			mh 5/7/03 - Issue 19538
 	*			mh 7/8/03 - Issue 21763	
 	*			mh 11/17/03 - Issue 18913	
	*			mh 1/18/06 - Issue 28966 and 119921
	*			EN 8/30/06 - Issue 120519 added NonResAlienYN flag update
	*			MH 02/22/2008 - Issue 29630 cross update Shift
 	*
 	* Purpose of Stored Procedure
 	*
 	*	Populate HR Resource Master with changes in PR Employee
 	*    
 	*           
 	* Notes about Stored Procedure
 	* 
 	*	When making changes to this procedure check bspHRPRUpdate which
 	*	is a mirror of this sp.
 	*
 	* returns 0 if successfull 
 	* returns 1 and error msg if failed
 	*
 	*************************************************************************/
   
 	(@co bCompany, @premp bEmployee, @msg varchar(80) = '' output)
 	
 	as
 	set nocount on
 	
 	declare @rcode int, @employee bEmployee, @updatenameyn bYN, @updateaddressyn  bYN, 
 	@updatehiredateyn bYN, @updateactiveyn bYN, @updateprgroupyn bYN, 
 	@updatetimecardyn bYN, @updatew4yn bYN, @updateoccupyn bYN, @updatessnyn bYN,
 	@err int, @opencurs tinyint
 	
 	select @rcode = 0, @err = 0, @opencurs = 0
 	
 	--need to get hr co for the employee.
 	declare @hrco bCompany, @hrref bHRRef
 	
 	--need to get the HRRef for employee.  It can be different then
 	--employee number.
 --mark 22525
 --	select @hrco = HRCo, @hrref = HRRef from bHRRM with (nolock) where PREmp = @premp and PRCo = @co
 
 	declare cHRUpdate cursor local fast_forward for
 		select HRCo, HRRef from dbo.bHRRM with (nolock) where
 		PREmp = @premp and PRCo = @co
 
 	open cHRUpdate
 	select @opencurs = 1
 
 	fetch next from cHRUpdate into @hrco, @hrref
 
 	while @@fetch_status = 0
 	begin
 	
 		select @updatenameyn = UpdateNameYN, @updateaddressyn = UpdateAddressYN, 
 		@updatehiredateyn = UpdateHireDateYN, @updateactiveyn = UpdateActiveYN,
 		@updateprgroupyn = UpdatePRGroupYN, @updatetimecardyn = UpdateTimecardYN, 
 		@updatew4yn = UpdateW4YN, @updateoccupyn = UpdateOccupCatYN, @updatessnyn = UpdateSSNYN 
 		from dbo.bHRCO with (nolock)
 		where HRCo = @hrco
 	  
 	  	begin transaction

--Issue 28966
 	  	if @updatessnyn = 'Y'
 	  	begin
 	  
 	  		update dbo.bHRRM
 	  		set SSN = p.SSN
 	  		from dbo.bPREH p, dbo.bHRRM h
 	  		where p.PRCo = @co and p.Employee = @premp and
 	  		h.HRCo = @hrco and h.HRRef = @hrref
 	  
 	  		if @@rowcount <> 1
 	  		begin
 	  			select @err = 1
 	  			goto bspexit
 	  		end
 	  	end
 	
 		if @updateoccupyn = 'Y'
 		begin
 			update dbo.bHRRM
 			set OccupCat = p.OccupCat, CatStatus = p.CatStatus
 			from bPREH p, bHRRM h with (nolock)
 			where p.PRCo = @co and p.Employee = @premp and
 			h.HRCo = @hrco and h.HRRef = @hrref
 			
 			
 			if @@rowcount <> 1
 			begin
 				select @err = 1
 				goto bspexit
 			end
 	
 		end
 	  
 	  	if @updatenameyn = 'Y'
 	  
 	  	begin
 	  
 			update dbo.bHRRM
 			set LastName = p.LastName, FirstName = p.FirstName, MiddleName = p.MidName,Suffix=p.Suffix,
 			SortName = p.SortName, BirthDate = p.BirthDate, Race = p.Race, Sex = p.Sex
 			from dbo.bPREH p, dbo.bHRRM h with (nolock)
 			where p.PRCo = @co and p.Employee = @premp and
 			h.HRCo = @hrco and h.HRRef = @hrref
 			
 			
 			if @@rowcount <> 1
 			begin
 				select @err = 1
 				goto bspexit
 			end
 	  
 	  	end
 	  
 	  	if @updateaddressyn = 'Y'
 	  	begin
 	  
 	  		update dbo.bHRRM
 	  		set Address = p.Address, Address2 = p.Address2, City = p.City, State = p.State,
 	  		Zip = p.Zip, Phone = p.Phone, Email = p.Email
 	  		from dbo.bPREH p, dbo.bHRRM h
 	  		where p.PRCo = @co and p.Employee = @premp and
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
 	  		update dbo.bHRRM
 	  		set PRDept = p.PRDept, StdCraft = p.Craft, StdClass = p.Class, StdInsCode = p.InsCode,
 	  		StdTaxState = p.TaxState, StdUnempState = p.UnempState, StdInsState = p.InsState,
 	  		StdLocal = p.LocalCode, /*SSN = p.SSN,*/ EarnCode = p.EarnCode, Shift = p.Shift
 	  		from dbo.bPREH p, dbo.bHRRM h
 	  		where p.PRCo = @co and p.Employee = @premp and
 	  		h.HRCo = @hrco and h.HRRef = @hrref
 	  
 	  		if @@rowcount <> 1
 	  		begin
 	  			select @err = 1
 	  			goto bspexit
 	  		end
 	  
 	  	end
 	 /*19538 moved the cross update of PRGroup to btPREHu  mh 5/7/03 
 	  	if @updateprgroupyn = 'Y'
 	  	begin
 	 */
 	  /*
 	  		update HRRM
 	  		set PRGroup = p.PRGroup
 	  		from PREH p
 	  		join HRRM h on p.PRCo = h.HRCo and p.Employee = h.PREmp
 	  		where p.PRCo = @co and p.Employee = @premp		
 	  */
 	 /*
 	  		update HRRM
 	  		set PRGroup = p.PRGroup
 	  		from PREH p, HRRM h
 	  		where p.PRCo = @co and p.Employee = @premp and
 	  		h.HRCo = @hrco and h.HRRef = @hrref
 	  
 	  		if @@rowcount <> 1
 	  		begin
 	  			select @err = 1
 	  			goto bspexit
 	  		end
 	  
 	  	end
 	 */ 
 		if @updatehiredateyn = 'Y'
 		begin
 			update dbo.bHRRM
 			set HireDate = p.HireDate, TermDate = p.TermDate,
 			-- clear Termination Reason if Termination Date has been cleared
 			TermReason = case when p.TermDate is null then null else TermReason end  
 			from dbo.bPREH p, dbo.bHRRM h
 			where p.PRCo = @co and p.Employee = @premp and h.HRCo = @hrco and h.HRRef = @hrref and
 			(isnull(p.TermDate,'')<>isnull(h.TermDate,'') or isnull(p.HireDate,'')<>isnull(h.HireDate,'')) 
 		end
 	  
 		if @updateactiveyn = 'Y'
 		begin
 	 /*
 	  		update bHRRM
 	  		set ActiveYN = p.ActiveYN
 	  		from PREH p, HRRM h
 	  		where p.PRCo = @co and p.Employee = @premp and
 	  		h.HRCo = @hrco and h.HRRef = @hrref
 	 */
 
 	 --Issue 21763 - error in the from clause.  Was using view instead of table.  This was 
 	 --causing all the records in HRRM to be updated...or at least @@rowcount to be the 
 	 --total number of rows in HRRM   mh
 	 /*
 	  		update bHRRM
 	  		set ActiveYN = p.ActiveYN
 	  		from bPREH p, bHRRM h
 	  		where p.PRCo = @co and p.Employee = @premp and
 	  		h.HRCo = @hrco and h.HRRef = @hrref
 	 */
 	 
 			update dbo.bHRRM 
 			set ActiveYN = p.ActiveYN
 			from dbo.bPREH p
 			join dbo.bHRRM h on p.PRCo = h.PRCo and p.Employee = h.PREmp
 			where p.PRCo = @co and p.Employee = @premp and
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
 	  		update dbo.bHRRM
 	  		set NonResAlienYN = p.NonResAlienYN
 	  		from dbo.bPREH p, dbo.bHRRM h
 	  		where p.PRCo = @co and p.Employee = @premp and
 	  		h.HRCo = @hrco and h.HRRef = @hrref
 	  
 	  		if @@rowcount <> 1
 	  		begin
 	  			select @err = 1
 	  			goto bspexit
 	  		end
 	  	end


 			if @err = 0
 				commit transaction
 
 		fetch next from cHRUpdate into @hrco, @hrref
 
 	end
  
 bspexit:
 
 	if @opencurs = 1
 	begin	
 		close cHRUpdate
 		deallocate cHRUpdate
 	end
   
   	if @err = 1
   	begin
   		rollback transaction
   		select @msg = 'Error updating HR Resource Master'
   	end
   	--else
   		--commit transaction
   
   	select @rcode = @err
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRHRUpdate] TO [public]
GO
