SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRBICodeVal]
/************************************************************************
* CREATED:	mh 5/23/05    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Validate a Deduction/Liablity or Earnings code against PR and return
*	description.    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @type varchar(2), @edlcode bEDLCode, @edltype char(1) output,
	@calccat char(1) output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int, @prco bCompany

    select @rcode = 0


	--select @hrco 'HRCo', @type 'Type', @edlcode 'EDLCode'

	if @hrco is null
  	begin
  		select @msg = 'Missing HR Company', @rcode = 1
	  	goto bspexit
  	end

	if @type is null
  	begin
  		select @msg = 'Missing EDL Type', @rcode = 1
  		goto bspexit
  	end

	if @edlcode is null
  	begin
  		select @msg = 'Missing EDL Code', @rcode = 1
  		goto bspexit
  	end

	select @prco = PRCo from HRCO where HRCo = @hrco

	if @prco is null
	begin
		select @msg = 'PR Company must be set up in HR Company', @rcode = 1
		goto bspexit
	end

	if @type = 'DL'
	begin
		select @edltype = DLType, @msg = p.Description, @calccat = CalcCategory
		from dbo.PRDL p with (nolock)
		where p.PRCo = @prco and p.DLCode = @edlcode

		if @@rowcount = 0
		begin
			select @msg = 'Code is not a valid Deduction/Liablity code.', @rcode = 1
			goto bspexit
		end

		if @edltype not in ('D', 'L')
		begin
			select @msg = 'Code is not a valid Deduction/Liability code.', @rcode = 1
			goto bspexit
		end
	end

	if @type = 'E'
	begin
		select @edltype = 'E', @msg = Description
		from dbo.PREC p with (nolock)
		where p.PRCo = @prco and p.EarnCode = @edlcode

		if @@rowcount = 0
		begin
			select @msg = 'Code is not a valid Earnings code.', @rcode = 1
			goto bspexit
		end
	end

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRBICodeVal] TO [public]
GO
