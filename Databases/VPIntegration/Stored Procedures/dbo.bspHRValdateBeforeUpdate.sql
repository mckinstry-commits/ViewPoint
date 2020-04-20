SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        procedure [dbo].[bspHRValdateBeforeUpdate]
/****************************************************************
* CREATED BY: kb 7/
* MODIFIED By mh 4/16/03 - Issue 18914
*			mh 7/11/03 - #21033 Centralize PR Validation into bspHRPRDefaultsVal
*			mh 9/29/2004 - added dbo. prefix, changed views to tables, added nolock hint.
*			see 25519
*			CHS TK-18912 D-05982 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000 for Ausatralia
*
* USAGE:
*
* INPUT:
*
* OUTPUT:
*   @errmsg		Error message
*
* RETURN:
*   0			Sucess
*   1			Failure
********************************************************/
   
   	(@hrco bCompany, @direction char(1), @prco bCompany, @employee bEmployee,
   	@hrref bHRRef, @errmsg varchar(200) output)
   
   	as
   
   	set nocount on
    
   	declare @rcode int, @status char(1), @ssn char(11), @race char(2), @prgroup bGroup,
   	@inscode bInsCode, @craft bCraft, @class bClass, @department bDept, @localcode bLocalCode, 
   	@sortname bSortName, @earncode bEDLCode, @opencurs tinyint, @dedncode bEDLCode, 
   	@occupcat varchar(10), @catstatus char(1), @defaultcountry char(2), @SSNString char(3)
   	
   	select @rcode = 0, @opencurs = 0
   	
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
    
   	if @direction = 'H'
   	begin
   		select @ssn = SSN, @employee = PREmp, @race = Race, @prgroup = PRGroup,
   		@inscode = StdInsCode, @craft = StdCraft, @class = StdClass, @department = PRDept,
   		@localcode = StdLocal, @sortname = SortName, @earncode=EarnCode, @occupcat = OccupCat,
   		@catstatus = CatStatus from dbo.bHRRM with (nolock)
   		where HRCo = @hrco and HRRef = @hrref
    
   		if exists(select 1 from dbo.bPREH with (nolock) where PRCo = @prco and SortName = @sortname)
   		begin
   			select @errmsg = 'SortName already exists for another employee in PR.', @rcode = 1
   			goto bspexit
   		end
   
   		exec @rcode = bspHRPRDefaultsVal @prco, @race, @prgroup, @department, @inscode,
   		@craft, @class, @localcode, @earncode, @occupcat, @catstatus, @errmsg output
   
   		if @rcode = 1 
   			goto bspexit
    
   		if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref and SSN is null)
   		begin
   			select @errmsg = @SSNString + ' is missing in HR.',@rcode = 1
   			goto bspexit
   		end
    
   		if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref and Race is null)
   		begin
   			select @errmsg = 'Race is missing in HR.', @rcode = 1
   			goto bspexit
   		end
   
   		if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref and PRGroup is null)
   		begin
   			select @errmsg = 'PRGroup is missing in HR.',@rcode = 1
   			goto bspexit
   		end
   
   		if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref and PRDept is null)
   		begin
   			select @errmsg = 'PRDept is missing from HR', @rcode = 1
   			goto bspexit
   		end
   
   		if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref and StdInsCode is null)
   		begin
   			select @errmsg = 'Insurance Code is missing from HR.', @rcode = 1
   			goto bspexit
   		end
   
   		if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref and StdUnempState is null)
   		begin
   			select @errmsg = 'Unemployment State is missing from HR.', @rcode = 1
   			goto bspexit
   		end
   
   		if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref and StdInsState is null)
   		begin
   			select @errmsg = 'Insurance State is missing from HR.', @rcode = 1
   			goto bspexit
   		end
   
		-- CHS TK-18912 D-05982 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000 for Ausatralia
   		--if exists(select 1 from bPREH with (nolock) where PRCo = @prco and SSN = @ssn)
   		--begin
   		--	select @errmsg = 'Employee with this SSN already exists in PR.', @rcode = 1
   		--	goto bspexit
   		--end
    	
    	IF @defaultcountry <> 'AU' OR (@defaultcountry = 'AU' AND @ssn NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
			BEGIN
			IF exists(SELECT 1 FROM bPREH WITH (NOLOCK) WHERE PRCo = @prco and SSN = @ssn)
				BEGIN
					SELECT @errmsg = 'Employee with this ' + @SSNString + ' already exists in PR.', @rcode = 1
					GOTO bspexit
				END			
			END   		
   
   		--issue 18914 - Need to validate the deductions
   		declare cDednCode cursor local fast_forward for
   		select DednCode
   		from dbo.bHRWI 
   		where HRCo = @hrco and HRRef = @hrref 
   		
   		open cDednCode
   		select @opencurs = 1
   
   		fetch next from cDednCode into @dedncode
   
   		while @@fetch_status = 0
   		begin
   		
   			if (select Method from dbo.bPRDL with (nolock)
   			where PRCo = @prco and DLCode = @dedncode) <> 'R'
   			begin
   				select @errmsg = 'Dedn/Liab code ' + convert(varchar(5), @dedncode) + ' is not a Routine based deduction.'
   				select @rcode = 1
   				goto bspexit
   			end				
   		
   			fetch next from cDednCode into @dedncode
   		end
   
   		close cDednCode
   		deallocate cDednCode
   		select @opencurs = 0
   
   	--end issue 18914
   	end
    
   	if @direction = 'P'
   	begin
   		select @ssn = SSN, @sortname = SortName from dbo.bPREH with (nolock)
   		where PRCo = @prco and Employee = @employee
   		
   		-- CHS TK-18912 D-05982 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000 for Ausatralia
   		--if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and SSN = @ssn)
   		--begin
   		--	select @errmsg = 'Resource with this SSN already exists in HR.', @rcode = 1
   		--	goto bspexit
   		--end
    	
    	IF @defaultcountry <> 'AU' OR (@defaultcountry = 'AU' AND @ssn NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
			BEGIN
   			IF exists(SELECT 1 FROM dbo.bHRRM WITH (NOLOCK) WHERE HRCo = @hrco AND SSN = @ssn)
   				BEGIN
   					SELECT @errmsg = 'Resource with this ' + @SSNString + ' already exists in HR.', @rcode = 1
   					GOTO bspexit
   				END			
			END   		
   		
   		if exists(select 1 from dbo.bHRRM where HRCo = @hrco and SortName = @sortname)
   		begin
   			select @errmsg = 'SortName already exists for another employee in HR.', @rcode = 1
   			goto bspexit
   		end
   	end
    
   	bspexit:
   	
   	if @opencurs = 1
   	begin
   		close cDednCode
   		deallocate cDednCode
   		select @opencurs = 0
   	end
   
   	if @rcode <> 0
   	begin
   		if @direction = 'H'
   		begin
   			select @errmsg = @errmsg + ' HR Resource ' + convert(varchar(10),@hrref)
   		end
   
   		if @direction = 'P'
   		begin
   			select @errmsg = @errmsg + ' PR Employee ' + convert(varchar(10),@employee)
   		end
   	end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRValdateBeforeUpdate] TO [public]
GO
