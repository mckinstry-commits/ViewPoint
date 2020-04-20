SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompanyVal    Script Date: 8/28/99 9:34:49 AM ******/
CREATE                       proc [dbo].[vspVADDFSInit]
/********************************
* Created: mj 11/13/06 
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
(@co smallint=-1, @form varChar(30)=null, @mod varChar(2)=null, @secgroup smallint=null, @vpusername varChar(128)=null,  
@access tinyint = null, @recadd char, @recupdate char, @recdelete char, @errmsg varchar(60) output)

as
	set nocount on
	declare @rcode int
	select @rcode = 0

-- try to update existing record
	if @mod is not null
		begin
		update vDDFS
		set Access = @access, RecAdd = isnull(@recadd, 'N'), RecUpdate = isnull(@recupdate, 'N'), RecDelete = isnull(@recdelete, 'N')
		from vDDFS join dbo.DDMF f (nolock) on f.Form = vDDFS.Form	-- Form's view matches Datatype's master table
		where Co = @co and f.Mod = @mod and SecurityGroup = @secgroup 
		if @@rowcount = 0
		begin
		-- add custom entry for Tab Index override
		insert vDDFS (Co, Form, SecurityGroup, VPUserName, Access, RecAdd, RecUpdate, RecDelete)
		values (@co, @form, @secgroup, @vpusername, @access, isnull(@recadd, 'N'), isnull(@recupdate, 'N'), isnull(@recdelete, 'N'))
		--where f.Mod = @mod --and in (Select * from dbo.DDMF f join dbo.DDFS s (nolock) on f.Form = s.FormName	-- Form's view matches Datatype's master table
	end
end

   
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDFSInit] TO [public]
GO
