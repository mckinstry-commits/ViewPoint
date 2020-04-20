SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspVACopySecurityGroupSecurity]
  
  /**************************************************
  *
  * Created By:  MJ 04/07/06 
  * Modified: JRK 12/04/06 Correct DDFS copying stmt.	
  *			  JonathanP 05/22/08 - Issue #127459. Attachment Type security will now be copied. 
  *			  AL 7/22/07 - Issue #128987 Added joins to shared views. 
  *			  AL 12/8/08 - Issue #131035 Added QuerySecurity 
  *			  AL 2/2/09	 - Issue #131035 Added TemplateSecurity
  *			  JonathanP 02/25/09 - #132390 - Updated to handle attachment security level column in DDFS
  * USAGE:
  *
  * Copies form, tab, report, and attachment type security for one user from one company to another.
  * Note that unlike copying user security in DDUP, this does not copy DDDU or PRGS
  * because those are secured only by VPUserName, not SecurityGroup.
  *
  * INPUT PARAMETERS
  *    FromCo - Company from which to copy user security.
  *	 ToCo   - Company to which user security will be copied.
  *    Username - User for whom security will be copied.
  *	 Replace - "Y" to replace destination company security.
  *
  * RETURN PARAMETERS
  *    Error Message and
  *	 0 for success, or
  *    1 for failure
  *
  *************************************************/
  (@FromCo smallint, @ToCo smallint, @SecurityGroup varchar(10), @Replace bYN, @msg varchar(255) = null output)
  
  AS
set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  --check for all required parameters
  if @FromCo is null
  begin
  	select @rcode = 1, @msg = 'From Company cannot be null'
  	goto bspexit
  end
  
  if @ToCo is null
  begin
  	select @rcode = 1, @msg = 'To Company cannot be null'
  	goto bspexit
  end
  
  if @SecurityGroup is null
  begin
  	select @rcode = 1, @msg = 'Username cannot be null'
  	goto bspexit
  end
  
  if @FromCo = @ToCo
  begin
 	select @rcode = 1, @msg = 'From Company and To Company cannot be the same.'
 	goto bspexit
  end
 
  if @Replace = 'Y' 
  begin
  --delete current security in the ToCo
  	delete from dbo.vDDTS
  	where SecurityGroup = @SecurityGroup and Co = @ToCo
  
  	delete from dbo.vDDFS
  	where SecurityGroup = @SecurityGroup and Co = @ToCo
  
  	delete from dbo.vRPRS
  	where SecurityGroup = @SecurityGroup and Co = @ToCo
  	
  	delete from dbo.vVAAttachmentTypeSecurity
  	where SecurityGroup = @SecurityGroup and Co = @ToCo
  	
  	delete from dbo.VPQuerySecurity
  	where SecurityGroup = @SecurityGroup and Co = @ToCo
  end
  
    
  --copy Form Security
  
  	insert into vDDFS(Co,Form,SecurityGroup,VPUserName,Access,RecAdd,RecUpdate,RecDelete, AttachmentSecurityLevel)
  	select @ToCo,f.Form,SecurityGroup,'',Access,RecAdd,RecUpdate,RecDelete, f.AttachmentSecurityLevel 
	from dbo.vDDFS f (nolock)
	Join dbo.DDFHShared s(nolock)
	on s.Form = f.Form
  	where SecurityGroup = @SecurityGroup and Co = @FromCo
  	and f.Form not in (select Form from dbo.vDDFS (nolock) where SecurityGroup = @SecurityGroup and Co = @ToCo and VPUserName = '')
  	
  --copy Tab Security
  
  	insert into vDDTS(Co,Form,Tab,SecurityGroup,VPUserName,Access)
  	select @ToCo,a.Form,a.Tab,SecurityGroup,'',Access 
	from dbo.vDDTS a (nolock)
	Join dbo.DDFTShared s (nolock)
	on s.Form = a.Form and s.Tab = a.Tab
  	where a.SecurityGroup = @SecurityGroup and a.Co = @FromCo
  	and not exists (select 1 from dbo.vDDTS b (nolock) where b.SecurityGroup = @SecurityGroup and b.Co = @ToCo
  	and b.Form = a.Form and b.Tab = a.Tab and VPUserName = '')
  
  
  --copy Report Security
  
  	insert into vRPRS(Co,ReportID,SecurityGroup,VPUserName,Access)
  	select @ToCo,ReportID,SecurityGroup,'',Access 
	from dbo.vRPRS (nolock)
  	where SecurityGroup = @SecurityGroup and Co = @FromCo
  	and ReportID not in (select ReportID from dbo.vRPRS (nolock) where SecurityGroup = @SecurityGroup and Co = @ToCo and VPUserName = '')
  
  -- copy Attachment Type Security
  
  	insert into vVAAttachmentTypeSecurity(Co,AttachmentTypeID,SecurityGroup,VPUserName,Access)
  	select @ToCo,AttachmentTypeID,SecurityGroup,'',Access 
	from dbo.vVAAttachmentTypeSecurity (nolock)
  	where SecurityGroup = @SecurityGroup and Co = @FromCo
  	and AttachmentTypeID not in (select AttachmentTypeID from dbo.vVAAttachmentTypeSecurity (nolock) where SecurityGroup = @SecurityGroup and Co = @ToCo and VPUserName = '') 
  
  --copy Query Security
  
				insert into VPQuerySecurity(Co, QueryName, SecurityGroup, VPUserName, Access)
				select @ToCo, QueryName, SecurityGroup, VPUserName, Access
				from VPQuerySecurity (nolock)
				where SecurityGroup = @SecurityGroup and Co = @FromCo
				and QueryName not in (select QueryName from VPQuerySecurity (nolock) where SecurityGroup = @SecurityGroup and Co = @ToCo and VPUserName = '')
  
    --copy Template Security
  
				insert into VPCanvasTemplateSecurity(Co, TemplateName, SecurityGroup, VPUserName, Access)
				select @ToCo, TemplateName, SecurityGroup, VPUserName, Access
				from VPCanvasTemplateSecurity (nolock)
				where SecurityGroup = @SecurityGroup and Co = @FromCo
				and TemplateName not in (select TemplateName from VPCanvasTemplateSecurity (nolock) where SecurityGroup = @SecurityGroup and Co = @ToCo and VPUserName = '')
  
  
  bspexit:
  
  return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVACopySecurityGroupSecurity] TO [public]
GO
