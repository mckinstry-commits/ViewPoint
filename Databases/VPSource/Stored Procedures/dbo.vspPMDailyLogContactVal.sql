SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDailyLogContactVal    Script Date: 7/28/2008 9:33:03 AM ******/
CREATE proc [dbo].[vspPMDailyLogContactVal]
/*************************************
* CREATED BY    :	GP	07/28/08 - Issue 128421 validate employee field on PM Daily Log (employee tab).
* LAST MODIFIED :	GF 06/16/2009 - issue #
*
* Validates PM Daily Log - Employee tab "Employee" field. This validation procedure is a modification of
*						bspPMFirmContactval.
*
* INPUT:
*	VendorGroup
*	Firm - Firm to validate contact in.
*    ContactSort - Contact or contact sort name to validate.
*	PRCo - Payroll company.
*	Employee - Employee number entered.
*
* OUTPUT:
*		ContactOut - The contact number validated
*
*	Success:
*		ContactNumber and Contact Name
*
*	Error:
*		@rcode = 1 and @msg
*	
**************************************/
(@vendorgroup bGroup = null, @firm bFirm = null, @contactsort bSortName, @PRCo bCompany = null, @Employee bEmployee = null,
 @contactout bEmployee = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0
   
   if @firm is null
   	begin
   	select @msg = 'Missing Firm!', @rcode = 1
   	goto vspexit
   	end
   
   if @contactsort is null
   	begin
   	select @msg = 'Missing Contact!', @rcode = 1
   	goto vspexit
   	end

				---- Check PREHName for employee before checking PMPM
				--SELECT @contactout = Employee, @msg = FirstName + ' ' + LastName
				--FROM PREHName with(nolock) WHERE PRCo = @PRCo and Employee = @Employee
				--IF @@rowcount > 0
				--BEGIN
				--GOTO vspexit
				--END

/* If @contact is numeric then try to find contact number */
if isnumeric(@contactsort) = 1
	begin
	select @contactout = ContactCode, @msg=FirstName + ' ' + LastName
	from PMPM with (nolock) 
	where VendorGroup = @vendorgroup and FirmNumber=@firm
	and ContactCode = convert(int,convert(float, @contactsort))
	end
	
---- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @contactout=ContactCode, @msg=FirstName + ' ' + LastName
	from PMPM with (nolock) 
	where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName = @contactsort

	-- if not found,  try to find closest
	if @@rowcount = 0
		begin
		set rowcount 1
		select @contactout=ContactCode, @msg=FirstName + ' ' + LastName
		from PMPM with (nolock) 
		where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName like @contactsort + '%'
		if @@rowcount = 0
			begin
			---- If @contactsort is numeric then try to find Employee number
			if isnumeric(@contactsort) = 1
				begin
				SELECT @contactout = Employee, @msg = FirstName + ' ' + LastName
				FROM PREHName where PRCo=@PRCo and Employee = convert(int,convert(float, @contactsort))
				end

				---- if not numeric or not found try to find as Sort Name
				if @@rowcount = 0
					begin
					SELECT @contactout = Employee, @msg = FirstName + ' ' + LastName
					from PREHName with (nolock) where PRCo=@PRCo and SortName = @contactsort

					---- if not found,  try to find closest
					if @@rowcount = 0
						begin
						set rowcount 1
						SELECT @contactout = Employee, @msg = FirstName + ' ' + LastName
						from PREHName where PRCo= @PRCo and SortName like @contactsort + '%'
						if @@rowcount = 0
							begin
							select @msg = 'PM Contact ' + convert(varchar(15),isnull(@contactsort,'')) + ' not on file!', @rcode = 1
							goto vspexit
							end
						end
					end
				end
			--begin
			--select @msg = 'PM Contact ' + convert(varchar(15),isnull(@contactsort,'')) + ' not on file!', @rcode = 1
			--goto vspexit
			--end
		end
	end
   
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDailyLogContactVal] TO [public]
GO
