SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE  [dbo].[vspFormPropertiesChangeSecurityLink]
-- =============================================
-- Created:	AL 9/10/2007 
-- Modified: GG 04/05/08
--	
-- Called from Form Properties to update Detail Form Security flag in custom DD Form Header
--
-- Inputs:
--	@form					Form
--	@detailformsecurity		Y = maintain security by form, N = security based on SecurityForm
--
-- Outputs:
--	@errmsg					Error message
--
-- Return code:
--	@rcode					0 = success, 1 = error
-- =============================================

(@form varchar(30) = null, @detailformsecurity bYN = null, @errmsg varchar(255) output)	

as
set nocount on

declare @rcode int
set @rcode = 0

-- validate form
if not exists(select 1 from dbo.DDFHShared where Form = @form)
	begin
	select @errmsg = 'Invalid Form - unable to update detail form security flag!', @rcode = 1
	goto vspexit
	end

-- update DetailFormSecurity flag in custom Form Header table
UPDATE dbo.vDDFHc
SET DetailFormSecurity = @detailformsecurity
WHERE Form = @form
if @@rowcount = 0
	begin
	-- add form header override	
	insert dbo.vDDFHc(Form, DetailFormSecurity)
	values (@form, @detailformsecurity)
	end
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspFormPropertiesChangeSecurityLink] TO [public]
GO
