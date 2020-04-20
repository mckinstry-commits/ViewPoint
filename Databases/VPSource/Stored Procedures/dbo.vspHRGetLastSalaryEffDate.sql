SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRGetLastSalaryEffDate]
/************************************************************************
* CREATED:  mh 1/17/2005    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Gets the last EffectiveDate from HRSH for a HRRef
*    
*           
* Notes about Stored Procedure
* 
*	Assumes HRRef has previously been resolved to a numeric.  Will not resolve
*	switch-r-oo
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany = null, @hrref bHRRef = null, @lastsalaryeffdate bDate = null output, @msg varchar(80) = null output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HRCo.', @rcode = 1
		goto bspexit
	end

	if @hrref is null
	begin
		select @msg = 'Missing HRRef.', @rcode = 1
		goto bspexit
	end

	if not exists(select 1 from dbo.HRCO with (nolock) where HRCo = @hrco)
	begin
		select @msg = 'Invalid HRCo.', @rcode = 1
		goto bspexit
	end

	if not exists(select 1 from dbo.HRRM with (nolock) where HRCo = @hrco and HRRef = @hrref)
	begin
		select @msg = 'Invalid HRRef.', @rcode = 1
		goto bspexit
	end
	
	select @lastsalaryeffdate = max(EffectiveDate) from dbo.HRSH with (nolock) where HRCo = @hrco and HRRef = @hrref

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRGetLastSalaryEffDate] TO [public]
GO
