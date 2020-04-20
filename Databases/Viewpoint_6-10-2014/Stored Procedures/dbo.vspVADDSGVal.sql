SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     proc [dbo].[vspVADDSGVal]
/********************************
* Created: JRK 11/13/06  
* Modified:	AL 9/27/12 Changed group to int
*
* Used to validate a security group.
*
* Input:
*	@group		security group

* Output:
*	1st resultset - available users  
*	2nd resultset - group members
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@group int, @msg varchar(30) output)
as
set nocount on
	
declare @rcode int
select @rcode = 0

if @group < 0 
begin
	Select @rcode = 1, @msg = 'Not a valid Security Group. Group numbers must be in the range 1-32767'
	goto bspexit
end
	
-- get users just for this security group 
select @msg = g.[Name]
from DDSG g
where g.SecurityGroup = @group

if @@rowcount = 0
begin
	select @rcode = 1, @msg='Not a valid security group!'
end


bspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVADDSGVal] TO [public]
GO
