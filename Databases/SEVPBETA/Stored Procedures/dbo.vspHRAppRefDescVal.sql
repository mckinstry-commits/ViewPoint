SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRAppRefDescVal]
/************************************************************************
* CREATED:	mh 1/6/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Return Reference Seq description    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @hrref bHRRef, @seq int, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company parameter.', @rcode = 1
		goto vspexit
	end

	if @hrref is null
	begin
		select @msg = 'Missing HR Resource parameter.', @rcode = 1
		goto vspexit
	end

	if @seq is null
	begin
		select @msg = 'Missing Reference Seq parameter.', @rcode = 1
		goto vspexit
	end

	select @msg = h.Name from dbo.HRAR h where h.HRCo = @hrco and h.HRRef = @hrref and h.Seq = @seq

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRAppRefDescVal] TO [public]
GO
