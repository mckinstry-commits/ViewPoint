SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVCContactTypesVal]
/*************************************
* Created By:	SDE 7/1/2008
*
*	Validation procedure for ContactTypeID
*	
* Pass:
*	ContactTypeID
*
* Success returns:
*	Description for ContactTypeID
*
* Error returns:
*	1 and error message
**************************************/
(@contactTypeID int = null, @msg varchar(60) = '' output)
	as 
	set nocount on

	declare @rcode int
	select @rcode = 0


	if @contactTypeID < 0
		begin
			select @msg = 'Missing Contact Type ID#.', @rcode = 1
			goto bspexit
		end
   
	select @msg = Description from pContactTypes with (nolock) where @contactTypeID = ContactTypeID

	if @@rowcount = 0
   		begin
	   		select @msg = 'Not a valid Contact Type ID#', @rcode = 1
   		end


   bspexit:
   	return @rcode
   





GO
GRANT EXECUTE ON  [dbo].[vspVCContactTypesVal] TO [public]
GO
