SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspHRResourceReviewLoadProc]
/************************************************************************
* CREATED:	mh 1/17/2005    
* MODIFIED: mh 1/18/2005 - Expanded to include frmHRInitRatingsGroup and
*							frmHRInitPositionRatings
*
* Purpose of Stored Procedure
*
*	Get default info for HRResourceReview.
*
*           
* Notes about Stored Procedure
*
*	HRResourceReview has a menu item allowing the user to launch
*	HRResourceSalary.  In order to do this in 6.x we need to know
*	the Assembly and FormClassName in DDFH.
*
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/


    (
@hrco bCompany, @hrsalaryassemblyname varchar(50) output, @hrsalaryformclassname varchar(50) output, 
@hrinitrategroupassemblyname varchar(50) output, @hrinitrategroupformclassname varchar(50) output, 
@hrinitposrateassemblyname varchar(50) output, @hrinitposrateformclassname varchar(50) output,
@msg varchar(100) output
)


as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company', @rcode = 1
		goto bspexit
	end

	if not exists(select 1 from HRCO where HRCo = @hrco) 
	begin
		select @msg = 'Company# ' + convert(varchar(4), @hrco) + ' not setup in HR', @rcode = 1
		goto bspexit
	end

	select @hrsalaryassemblyname = AssemblyName, @hrsalaryformclassname = FormClassName 
	from dbo.vDDFH with (nolock) where Form = 'HRResourceSalary'

	select @hrinitrategroupassemblyname = AssemblyName, @hrinitrategroupformclassname = FormClassName 
	from dbo.vDDFH with (nolock) where Form = 'HRInitRatingGroup'

	select @hrinitposrateassemblyname = AssemblyName, @hrinitposrateformclassname = FormClassName 
	from dbo.vDDFH with (nolock) where Form = 'HRInitPositionRatings'


bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRResourceReviewLoadProc] TO [public]
GO
