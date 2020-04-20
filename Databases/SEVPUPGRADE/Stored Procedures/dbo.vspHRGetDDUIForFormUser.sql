SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRGetDDUIForFormUser]
/************************************************************************
* CREATED:    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@formname varchar(30))

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if suser_sname() = 'viewpointcs' goto vspexit

	select Seq, GridCol, ColWidth 
	from vDDUI 
	where VPUserName = suser_sname() and Form = @formname
	Order by GridCol, Seq


vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRGetDDUIForFormUser] TO [public]
GO
