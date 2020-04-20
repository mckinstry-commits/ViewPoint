SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRClaimContactDescVal]
/************************************************************************
* CREATED:	mh 1/6/05    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Return Contact Desc 
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

        
    (@hrco bCompany, @claimcontact varchar(10), @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company parameter.', @rcode = 1
		goto vspexit
	end

	if @claimcontact is null
	begin
		select @msg = 'Missing Claim Contact parameter.', @rcode = 1
		goto vspexit
	end

	select @msg = Name from dbo.HRCC where HRCo = @hrco and ClaimContact = @claimcontact
vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRClaimContactDescVal] TO [public]
GO
