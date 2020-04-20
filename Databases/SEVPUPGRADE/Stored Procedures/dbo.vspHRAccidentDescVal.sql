SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRAccidentDescVal]
/************************************************************************
* CREATED:	mh 10/5/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Return Accident Description
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

        
    (@hrco bCompany, @accident varchar(10), @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null	
	begin
		select @msg = 'Missing HR Company.', @rcode = 0
		goto vspexit
	end

	if @accident is null
	begin
		select @msg = 'Missing Accident.', @rcode = 0
		goto vspexit
	end

	select @msg = Location from dbo.HRAT with (nolock) where HRCo = @hrco and Accident = @accident

vspexit:



     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRAccidentDescVal] TO [public]
GO
