SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspVADDTSupdate]
/**************************************************************
* Created: GG 08/16/07
* Modified: CC	07/16/09 - #129922 - Added link for culture text
*           AL Change SEcurity Group to Int
* Usage:
*	Updates tab security to DD Tab Security table (vDDTS).
*	Co/Form/Tab/Group or User access level must already be 'by tab'.
*	Access level 2 (deny) only valid with user level entries
*	Access level 3 (none) removes entry from vDDTS.
*
* Inputs:
*	@co					Company # (-1 used for 'all company' entries)
*	@form				Form name
*	@tab				tab #
*	@securitygroup		Security Group (-1 if user level entry)
*	@username			VP User Name ('' if security group entry)
*	@access				Access level (0=full,1=read only,2=denied,3=none)
*
* Output:
*	@msg				Error message
*
* Return code:
*	0 = success, 1 = error
*
****************************************/
  
   (@co smallint = null, @form varchar(30) = null, @tab TINYINT = null,
	@securitygroup int = null, @username bVPUserName=null, @access tinyint = null,
    @msg varchar(60) output) 

as
   
set nocount on

declare @rcode int
     
select @rcode = 0
 
if @access in (0,1,2)	-- full, read only, deny
	begin
    -- update/insert tab security entry to allow access
    update dbo.vDDTS
    set Access = @access
    where Co = @co and Form = @form and Tab = @tab and SecurityGroup = @securitygroup and VPUserName = @username 
    if @@rowcount = 0     
   		insert dbo.vDDTS (Co, Form, Tab, VPUserName, SecurityGroup, Access)
   		values(@co, @form, @tab, @username, @securitygroup, @access)
	end

if @access = 3		-- none
	begin
    -- delete tab security 
    delete dbo.vDDTS
	where Co = @co and Form = @form and Tab = @tab and SecurityGroup = @securitygroup and VPUserName=@username 
    end
      

vspexit:   
	return @rcode
	

GO
GRANT EXECUTE ON  [dbo].[vspVADDTSupdate] TO [public]
GO
