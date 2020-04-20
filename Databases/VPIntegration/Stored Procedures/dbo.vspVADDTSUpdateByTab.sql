SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[vspVADDTSUpdateByTab]
/**************************************************************
* Created: AL 06/02/08
* Modified: AL 09/27/12 Change Security group to an int
*
* Usage:
*	Updates tab security to DD Tab Security table (vDDTS).
*	
* Inputs:
*	@co					Company # (-1 used for 'all company' entries)
*	@form				Form name
*	@tabnumber			Tab Number
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
  
   (@co smallint = null, @form varchar(30) = null, @tab tinyint = null,
	@securitygroup int = null, @username bVPUserName=null, @access tinyint = null,
    @msg varchar(60) output) 

as
   
set nocount on

declare @rcode int
     
select @rcode = 0
 
-- Ensure that Tab exists  
select Tab from dbo.DDFTShared (nolock) where Form = @form and Tab = @tab
if @@rowcount <> 1
   	begin
   	select @msg = 'Invalid Tab - unable to update Tab Security', @rcode = 1
   	goto vspexit
   	end

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
GRANT EXECUTE ON  [dbo].[vspVADDTSUpdateByTab] TO [public]
GO
