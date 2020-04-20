SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompanyVal    Script Date: 8/28/99 9:34:49 AM ******/
CREATE                       proc [dbo].[vspVADDFSRefresh]
/********************************
* Created: mj 2/18/05 
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
(@company smallint=-1, @module varchar(2)=null, @secgroup smallint=null, @form varChar(30)=null, @username varChar(128)=null, @errmsg varchar(60) output)

as
	set nocount on
	declare @rcode int
	select @rcode = 0

	
	if @secgroup <> null
	begin
	select Co, m.Mod, h.Form, f.SecurityGroup, isnull(Access, null) as Access, RecAdd, RecUpdate, RecDelete
	from DDFHShared h
	join vDDMF m on m.Form = h.Form 
	left join vDDFS f on f.Form = h.Form and isnull(@secgroup,SecurityGroup)=SecurityGroup and isnull(@company, f.Co) = f.Co and isnull(@form, f.Form) = f.Form
	where isnull(@module,m.Mod)=m.Mod
	order by h.Form
	end
	
	if @username <> null
	begin
	select Co, m.Mod, h.Form, f.VPUserName, isnull(Access, null) as Access, RecAdd, RecUpdate, RecDelete
	from DDFHShared h
	join vDDMF m on m.Form = h.Form 
	left join vDDFS f on f.Form = h.Form and isnull(@username,VPUserName)= VPUserName and isnull(@company, f.Co) = f.Co and isnull(@form, f.Form) = f.Form
	where isnull(@module,m.Mod)=m.Mod
	order by h.Form
	end

	if @form <> null
	begin
	select Co, m.Mod, isnull(m.Form, @form) as Form, VPUserName, s.SecurityGroup, isnull(Access, null) as Access, RecAdd, RecUpdate, RecDelete
	from vDDSG s 
	left join vDDFS f on f.SecurityGroup = s.SecurityGroup and isnull(@company, f.Co) = f.Co and isnull(@form, f.Form) = f.Form
	left join vDDMF m on m.Form = f.Form
	--full outer join vDDUP u on u.VPUserName =  f.VPUserName
	union
	select Co, m.Mod, isnull(m.Form, @form) as Form, u.VPUserName, case when SecurityGroup = -1 then null else SecurityGroup end, isnull(Access, null) as Access, RecAdd, RecUpdate, RecDelete
	from vDDUP u 
	left join vDDFS f on f.VPUserName = u.VPUserName and isnull(@company, f.Co) = f.Co and isnull(@form, f.Form) = f.Form
	left join vDDMF m on m.Form = f.Form
	order by s.SecurityGroup, f.VPUserName
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDFSRefresh] TO [public]
GO
