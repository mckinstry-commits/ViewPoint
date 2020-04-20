SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompanyVal    Script Date: 8/28/99 9:34:49 AM ******/
CREATE                       proc [dbo].[vspVADDFSUpdate]
/********************************
* Created: mj 3/21/05 
* Modified:	
*
* Called from the VADDFS form to retrieve records to fill the bottom grid.
*
* Input:
*	
* 	@company smallint(2)
*	@module varchar(2)
*	@secgroup varchar(2)
*	@form varChar(30)
*	@username varChar(128)
*
* Output:
*	@errmsg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@company smallint=-1, @secgroup smallint=null, @username varChar(128)=null, @form varChar(30)=null,  @access tinyint = null, @recadd char, @recupdate char, @recdelete char, @errmsg varchar(60) output)

as
	set nocount on
	declare @rcode int
	select @rcode = 0

-- try to update existing record
	begin
	update vDDFS
	set Access = @access, RecAdd = isnull(@recadd, 'N'), RecUpdate = isnull(@recupdate, 'N'), RecDelete = isnull(@recdelete, 'N')
	where Co = @company and Form = @form and SecurityGroup = @secgroup and VPUserName = @username
	if @@rowcount = 0
		begin
		-- add custom entry for Tab Index override
		insert vDDFS (Co, Form, SecurityGroup, VPUserName, Access, RecAdd, RecUpdate, RecDelete)
		values (@company, @form, @secgroup, @username, @access, isnull(@recadd, 'N'), isnull(@recupdate, 'N'), isnull(@recdelete, 'N'))
		end
	end

	
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDFSUpdate] TO [public]
GO
