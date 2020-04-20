SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRInitPRGrid]
/****************************************************************
* CREATED BY: kb 8/31/99
* MODIFIED By : ae 11/23/99
*               je 06/06/00  - added EarnCode null check
*		    je 07/26/00  - added PREmp null check
*               je 02/07/01  - added employee check when getting next employee
*			mh 9/19/01 - added ability to exclude inactive employees.
*			sr 07/08/02 ---Issue 17809 - only pull in resources that have a PRCo and PREmployee
*			mh 7/11/03 - #21033 Centralize PR Validation into bspHRPRDefaultsVal
*			mh 8/5/03 - 20805
*			mh 10/1/2004 - issue #25519. Changed stmts to use tables instead of views
*							due to security issues.  
*			mh 10/07/2004 - 25700 - We had several unnecessary select statements validating 
*				HRRM info by just checking if value is null or not.  Those values can be
*				gathered in the cursor and then checked without going back to HRRM.  Also 
*				cleaned up validation of deductions.  We were using a cursor to cycle through
*				them for a Resource and if one was found, poping out of the loop and raising
*				an error.  Don't need the cursor.  Just need to join up to PRDL and get the first 
*				occurance in error.  
*			CHS TK-18912 D-05982 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000 for Ausatralia
*
* USAGE:
* Called by the HR Init PR form to fill grid of which employees in HR or PR will be update
* to PR or HR.
*
* INPUT:
*   @hrco      	PR Company
*   @direction    P = from PR to HR, H = from HR to PR
*   @prco         PR Company
*   @initall      Initialize All? Y or N
*   @begempl      Beginning Employee or Resource for a range update
*   @endempl      Ending Employee or Resource for a range update
*
* OUTPUT:
*   @errmsg		Error message
*
* RETURN:
*   0			Sucess
*   1			Failure
********************************************************/
(@hrco bCompany, @direction char(1), @prco bCompany, @initall bYN, @excludeinact bYN,
	@begempl bEmployee, @endempl bEmployee, @errmsg varchar(200) output)

	as

	set nocount on

	declare @rcode int, @msg varchar(60), @status char(1), @hrref bHRRef, @ssn char(11),
		@employee bEmployee, @race char(2), @prgroup bGroup,
		@inscode bInsCode, @craft bCraft, @class bClass, @department bDept,
		@localcode bLocalCode, @sortname bSortName, @earncode bEDLCode, @activeYN bYN,
		@lastname varchar(30), @firstname varchar(30), @openHRRefcursor tinyint, @openemployeecursor tinyint,
		@opendedncurs tinyint, @dedncode bEDLCode, @occupcat varchar(10), @catstatus char(1),
		@sex char(1), @stdinscode bInsCode, @stdunempstate bState, @stdinsstate bState, 
		@defaultcountry char(2), @SSNString char(3)
	    
	   
	select @rcode = 0, @openHRRefcursor = 0, @openemployeecursor = 0

   	SELECT @defaultcountry = DefaultCountry FROM dbo.HQCO WHERE HQCo = @hrco
   	
   	SELECT @SSNString = 'SSN'
   	
   	IF @defaultcountry = 'AU'
   		BEGIN
   		SELECT @SSNString = 'TFN'
   		END
   		
   	ELSE IF @defaultcountry = 'CA'
   		BEGIN
   		SELECT @SSNString = 'SIN'
   		END


if @initall='Y' 
begin
	select @begempl =0, @endempl=9999999
end

if @hrco is null
begin
	select @errmsg = 'Missing HR Company', @rcode = 1
	goto bspexit
end

if not exists(select 1 from dbo.bHRCO with (nolock) where HRCo = @hrco)
begin
	select @errmsg = 'Invalid HR Company', @rcode = 1
	goto bspexit
end

if @direction is null
begin
	select @errmsg = 'Update direction must be specified', @rcode = 1
	goto bspexit
end

if @direction <> 'P' and @direction <> 'H'
begin
	select @errmsg = 'Update direction must be P or H', @rcode = 1
	goto bspexit
end

if @prco is null
begin
	select @errmsg = 'Missing PR Company', @rcode = 1
	goto bspexit
end

if not exists(select 1 from dbo.bPRCO with (nolock) where PRCo = @prco)
begin
	select @errmsg = 'Invalid PR Company', @rcode = 1
	goto bspexit
end
    
if @direction = 'H'
	begin
   
	declare cHRRef cursor local fast_forward for

	select h.HRRef, h.SSN, h.PREmp, h.Race, h.PRGroup,
   		h.StdInsCode, h.StdCraft, h.StdClass, h.PRDept,
   		h.StdLocal, h.SortName, h.EarnCode, h.ActiveYN,
   		h.LastName, h.FirstName, h.OccupCat, h.CatStatus, 
   		h.Sex, h.StdUnempState, h.StdInsState 
	from dbo.bHRRM h (nolock) 
	where h.HRCo = @hrco and h.ExistsInPR='N' and h.PRCo = @prco and 
		(@begempl is null or (@begempl is not null and h.HRRef >= @begempl)) and
		(@endempl is null or (@endempl is not null and h.HRRef <= @endempl))
   
	open cHRRef
    
	select @openHRRefcursor = 1
    
	fetch next from cHRRef into @hrref, @ssn, @employee, @race, @prgroup, @inscode,
   		@craft, @class, @department, @localcode, @sortname, @earncode, @activeYN,
   		@lastname, @firstname, @occupcat, @catstatus, @sex, @stdunempstate, @stdinsstate
    
	while @@fetch_status = 0
		begin --while loop	
 
		select @status = '0', @msg = null
   
		if @excludeinact = 'Y' 
		begin
			if @activeYN = 'N'
				goto NextHREmployee
		end
   
		if @ssn is null
		begin
			select @msg = 'HRRef ' + @SSNString + ' is missing.', @status='1'
			goto InsertEnd
		end
   
		if exists(select Employee from dbo.bPREH with (nolock) where PRCo = @prco and SortName = @sortname
		and LastName = @lastname and FirstName = @firstname and SSN = @ssn)
		begin
			select @msg = 'Employee already exists in PR Employee Master.', @status = '1'
			goto InsertEnd
		end
		
		
		-- CHS TK-18912 D-05982 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000 for Ausatralia
		--if exists(select Employee from dbo.bPREH with (nolock) where PRCo = @prco and SSN = @ssn)
		--begin
		--	select @msg = 'Employee with this ' + @SSNString + ' already exists in PR.', @status = '1'
		--	goto InsertEnd
		--end
		
    	IF @defaultcountry <> 'AU' OR (@defaultcountry = 'AU' AND @ssn NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
			BEGIN
			if exists(select Employee from dbo.bPREH with (nolock) where PRCo = @prco and SSN = @ssn)
			begin
				select @msg = 'Employee with this ' + @SSNString + ' already exists in PR.', @status = '1'
				goto InsertEnd
			end			
			END		
		
		

		if exists(select 1 from dbo.bPREH with (nolock) where PRCo = @prco and SortName = @sortname)
		begin
			select @msg = 'SortName already exists for another employee in PR.', @status = '1'
			goto InsertEnd
		end
   
		if @race is null
		begin
			select @msg = 'HR Resource Race code is missing.', @status='1'
			goto InsertEnd
		end

		if @prgroup is null
		begin
			select @msg = 'HR Resource PRGroup code is missing.', @status='1'
			goto InsertEnd
		end

		if @department is null
		begin
			select @msg = 'HR Resource PRDept code is missing.', @status='1'
			goto InsertEnd
		end

		if @inscode is null
		begin
			select @msg = 'HR Resource Insurance Code is missing.', @status='1'
			goto InsertEnd
		end
   
		if @stdunempstate is null
		begin
			select @msg = 'HR Resource Unemployment State is missing.', @status='1'
			goto InsertEnd
		end

		if @stdinsstate is null
		begin
			select @msg = 'HR Resource Insurance State is missing.', @status='1'
			goto InsertEnd
		end
   
		if @earncode is null
		begin
			select @msg = 'HR Resource Earning Code is missing.', @status = '1'
			goto InsertEnd
		end
 
		exec @rcode = bspHRPRDefaultsVal @prco, @race, @prgroup, @department, @inscode,
		@craft, @class, @localcode, @earncode, @occupcat, @catstatus, @msg output
    
		if @rcode = 1 
		begin
			select @status = '1', @rcode = 0
		end

	 	select @dedncode = min(h.DednCode)
	 	from dbo.bHRWI h with (nolock)
		join dbo.bHRRM m with (nolock) on h.HRCo = m.HRCo and h.HRRef = m.HRRef 
		join dbo.bPRDL p with (nolock) on m.PRCo = p.PRCo and h.DednCode = p.DLCode
	 	where h.HRCo = @hrco and h.HRRef = @hrref and Method <> 'R'
   
		if @dedncode is not null
		begin
			select @msg = ' Invalid File Status.  Deduction Code ' + convert(varchar(5), @dedncode) + ' is not Routine based.'
			select @status='1', @dedncode = null
			goto InsertEnd
		end

    InsertEnd:
    
		if not exists(select HRCo from dbo.HRHP with (nolock) where HRCo = @hrco and
		(HRRef=@hrref or (HRRef is null and @hrref is null)) and
		PRCo = @prco and (Employee = @employee or (Employee is null
		and @employee is null)))
		begin
			insert dbo.bHRHP (HRCo, HRRef, PRCo, Employee, Status, UpdateOpt, ErrMsg)
			select @hrco, @hrref, @prco, @employee, @status, @direction, @msg
		end

		NextHREmployee:
	    
			fetch next from cHRRef into @hrref, @ssn, @employee, @race, @prgroup, @inscode,
   				@craft, @class, @department, @localcode, @sortname, @earncode, @activeYN,
   				@lastname, @firstname, @occupcat, @catstatus, @sex, @stdunempstate, @stdinsstate
	    
			end
	    
    	end --while loop
    
	if @openHRRefcursor=1
    	begin
    		close cHRRef
    		deallocate cHRRef
    		select @openHRRefcursor = 0
    	end
   --pr to hr 
	if @direction = 'P'
    	begin
    
		declare cEmployee cursor local fast_forward for
   
   		select Employee, FirstName, LastName, SSN, SortName, ActiveYN 
   		from dbo.bPREH with (nolock) 
   		where PRCo = @prco and Employee not in (select distinct(PREmp) from dbo.bHRRM with (nolock) where HRCo = @hrco and
   			PRCo = @prco and PREmp is not null) and (@begempl is null 
   			or (@begempl is not null and Employee >= @begempl)) and 
   			(@endempl is null or (@endempl is not null and Employee <=@endempl))
   
		open cEmployee 
    
		select @openemployeecursor = 1
    
   		fetch next from cEmployee into @employee, @firstname, @lastname, @ssn, @sortname, @activeYN
    
		while @@fetch_status = 0
    		begin
    
    			select @status = '0', @msg = null
    
    			if @excludeinact = 'Y' 
    			begin
    				if @activeYN = 'N'
    					goto NextPREmployee
    			end

				-- CHS TK-18912 D-05982 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000 for Ausatralia		
				--if exists(select HRCo from dbo.bHRRM with (nolock) where HRCo = @hrco and SSN = @ssn)
				--begin
				--	select @msg = 'Resource with this ' + @SSNString + ' already exists in HR.', @status = '1'
				--	goto InsertEnd2
				--end
				
    			IF @defaultcountry <> 'AU' OR (@defaultcountry = 'AU' AND @ssn NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
					BEGIN
					IF exists(SELECT HRCo FROM dbo.bHRRM WITH (NOLOCK) WHERE HRCo = @hrco and SSN = @ssn)
						BEGIN
							SELECT @msg = 'Resource with this ' + @SSNString + ' already exists in HR.', @status = '1'
							GOTO InsertEnd2
						END
					END				
				

				if exists(select HRCo from dbo.HRRM with (nolock) where HRCo = @hrco and SortName = @sortname)
				begin
					select @msg = 'SortName already exists for another employee in HR.', @status = '1'
					goto InsertEnd2
				end
    
		InsertEnd2:
   
				if not exists(select HRCo from dbo.bHRHP with (nolock) where HRCo = @hrco and
					(HRRef=@hrref or (HRRef is null and @hrref is null)) and
					PRCo = @prco and (Employee = @employee or (Employee is null and @employee is null)))
				begin
					insert dbo.bHRHP (HRCo, HRRef, PRCo, Employee, Status, UpdateOpt, ErrMsg)
					select @hrco, @hrref, @prco, @employee, @status, @direction, @msg
				end
    
			NextPREmployee:
   
   			fetch next from cEmployee into @employee, @firstname, @lastname, @ssn, @sortname, @activeYN
    
    		end  -- while @employee = null
    
		if @openemployeecursor = 1
		begin
			close cEmployee
			deallocate cEmployee
			select @openemployeecursor = 0
		end
    
    end
    
	bspexit:
    
    	if @openHRRefcursor=1
    	begin
    		close cHRRef
    		deallocate cHRRef
    		select @openHRRefcursor = 0
    	end
    
    	if @openemployeecursor = 1
    	begin
    		close cEmployee
    		deallocate cEmployee
    		select @openemployeecursor = 0
    	end

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHRInitPRGrid] TO [public]
GO
