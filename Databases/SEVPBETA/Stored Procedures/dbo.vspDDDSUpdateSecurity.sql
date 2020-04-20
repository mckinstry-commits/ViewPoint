SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDDSUpdateSecurity]
-- =============================================
-- Created: AL 2/13/2007
-- Modified: GG 06/13/07 - cleanup
--
-- Used by VA Data Security to add or remove vDDDS entries for a
-- specific datatype, qualifier, instance, and security group.
--
-- Inputs:
--	@datatype			Datatype
--	@qualifier			Qualifier (Co#)
--	@instance			Datatype value
--	@securitygroup		Security Group
--	@allowed			Y = grant access (add vDDDS entry), N = deny access (remove vDDDS entry)
--
-- Outputs:
--	@msg				Error message
--
-- Return code:
--	0 = success, 1 = error
--
-- =============================================

	(@datatype varchar(30) = null, @qualifier tinyint = null, @instance char(30) = null,
	 @securitygroup int = null, @allowed char(1), @msg varchar(255) output)
 
AS

SET NOCOUNT ON

declare @rcode int
select @rcode = 0

if @allowed not in ('Y','N')
	begin
	select @msg = 'Access flag must be ''Y'' or ''N''.', @rcode = 1
	goto vspexit
	end

-- datatype and security group validated in vDDDS insert trigger

if @allowed = 'N'
	begin
	-- access not allowed, delete data security entry (OK if it does not exist)
	delete dbo.vDDDS 
	where Datatype = @datatype and Qualifier = @qualifier 
	and Instance = @instance and SecurityGroup = @securitygroup 
	end 
	
if @allowed = 'Y'
	begin
	-- access allowed, add data security entry as needed
	if not exists(select top 1 1 from dbo.vDDDS where Datatype = @datatype and Qualifier = @qualifier 
			and Instance = @instance and SecurityGroup = @securitygroup)
		begin
		insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
		values (@datatype, @qualifier, @instance, @securitygroup)
		end
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDSUpdateSecurity] TO [public]
GO
