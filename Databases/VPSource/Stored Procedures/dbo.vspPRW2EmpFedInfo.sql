SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRW2EmpFedInfo]
/***********************************************************
* CREATED BY: TJL 08/24/10 - Issue #137605, Determine if 401K deferred compensation is Catchup
* MODIFIED By : 
*
* USAGE:
*   When users are manually editing the PR W2 Employee Federal Information, and when they are adding
*	a New Item for (10 Deferred Comp - 401K), if the Item being entered is the SECOND sequence
*	(One already exists for this Item), then the form will require a "Year" value be entered.
*
* INPUT PARAMETERS
*   PRCo		PR Co
*   TaxYear		W2 Tax Year
*	Employee	Employee being edited
*	Seq			Indicator whether in Add or Update mode
*
* OUTPUT PARAMETERS
*	@rcode		
*   @allowemptyyear		Y - Sequence 1 is being added or updated and YEAR can remain NULL
*						N - Sequence 1 already exists and YEAR must be entered
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
   
(@prco bCompany = null, @taxyear char(4) = null, @employee bEmployee = null, 
	@seq int = null, @allowemptyyear bYN output, @msg varchar(120) output)
as

set nocount on

declare @rcode int
   
select @rcode = 0, @allowemptyyear = 'Y'
   
if @prco is null
	begin
	select @msg = 'Missing PR Company. Precheck for W2 Employee Federal Info could not be completed.', @rcode = 1
	goto vspexit
	end
if @taxyear is null
	begin
	select @msg = 'Missing Tax Year. Precheck for W2 Employee Federal Info could not be completed.', @rcode = 1
	goto vspexit
	end
if @employee is null
	begin
	select @msg = 'Missing Employee. Precheck for W2 Employee Federal Info could not be completed.', @rcode = 1
	goto vspexit
	end

if isnull(@seq, -1) > 1 
	begin
	/* Sequence value has been passed in.  This means user is updating an existing sequence. 
	   If this sequence is anything other than a '1' then an EMPTY year will not be allowed. 
	   ELSE user is updating Item 10, Seq #1 and an EMPTY year is OK. */
	set @allowemptyyear = 'N'
	end

if isnull(@seq, -1) = -1 
	begin
	/* Sequence value has NOT been passed in.  This means user is adding a record in the grid.
	   If any sequences already exist for this Item and Employee, then the new record
	   Sequence will be greater than '1' and an EMPTY year will not be allowed. 
	   ELSE this is the first Seq being added and an EMPTY year is OK. */
	if exists(select Top 1 1
	from dbo.bPRWA
	where PRCo = @prco and TaxYear = @taxyear and Employee = @employee
		and Item = 10) set @allowemptyyear = 'N'
	end
	   	
vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRW2EmpFedInfo] TO [public]
GO
