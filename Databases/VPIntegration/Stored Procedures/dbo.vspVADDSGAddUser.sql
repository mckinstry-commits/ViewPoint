SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompanyVal    Script Date: 8/28/99 9:34:49 AM ******/
CREATE       proc [dbo].[vspVADDSGAddUser]
/********************************
* Created: mj 2/15/05 
* Modified:	
*
*Used to add users to the vDDSU table.
*
* Input:
*	@username, @group
* Output:
*	@msg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@group smallint, @username varchar(30),  @errmsg varchar(60) output)
as
	set nocount on
	declare @rcode int
	select @rcode = 0

	begin
	insert vDDSU (SecurityGroup, VPUserName)
	values (@group, @username)
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDSGAddUser] TO [public]
GO
