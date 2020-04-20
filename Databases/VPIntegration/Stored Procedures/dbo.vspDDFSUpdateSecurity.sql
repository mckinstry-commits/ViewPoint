SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==============================================================================
-- Author:		<Aaron Lang, vspDDFSUpdateSecurity>
-- Create date: <5/30/2007>
-- Description:	<Updates the DDFS table>
-- Modified:	04/28/08 AL If security is set to be By Tab then a tab record is 
--							created in DDTS Taht makes the info tab read only.
--				06/02/08 AL Made modifications to ensure that default tab records are
--							getting written out properly.
--				08/04/08 AL	Updated to remove tab security records before deleting DDFS records
--				09/02/08 AL Added additional code to ensure that read only tab records would be
--							created when records are being created or updated. #129638, #129640
--				
--				02/23/09 AL Added Attachment to update #126160
-- ==============================================================================
CREATE PROCEDURE [dbo].[vspDDFSUpdateSecurity]

	-- Add the parameters for the stored procedure here
	(@company SMALLINT, @form VARCHAR(30), @securitygroup INT, @username VARCHAR(128),
	@access TINYINT, @add CHAR(1), @update CHAR(1), @delete CHAR(1), @attach tinyint, @msg varchar(80) = '' output)



AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @rcode int
select @rcode = 0

 

declare @tab tinyint
select @tab = min(Tab) from DDFT where Tab > 0 and Form = @form and GridForm is null
declare @tabaccess tinyint
Select @tabaccess = 1



if @rcode <> 0 	goto bsperror

if @attach =3
Begin
select @attach = NULL
end

--ensure form secirity record exists before acting on it.
IF EXISTS (SELECT [Co], [Form], [SecurityGroup], [VPUserName]
FROM [DDFS]
WHERE [Co] = @company AND [Form] = @form and [SecurityGroup] = @securitygroup and [VPUserName]= ISNULL(@username, ''))
BEGIN

	--remove records existing when access is set to none
	IF @access = 3
		begin	
		--remove any potential tab security records	
		DELETE [DDTS]
		WHERE [Co] = @company AND [Form] = @form and [SecurityGroup] = @securitygroup and [VPUserName]= ISNULL(@username, '')
		
		--remove form security records
		DELETE [DDFS]
		WHERE [Co] = @company AND [Form] = @form and [SecurityGroup] = @securitygroup and [VPUserName]= ISNULL(@username, '')
		end		
	ELSE
		
		--If access is set to "by tab" then write out a read only record for the info tab.
		--otherwise remove tab security records for the form.
		if @access = 1 and @tab is not null
			BEGIN
			exec @rcode = vspVADDTSUpdateByTab @company, @form, @tab, @securitygroup, @username, @tabaccess, @msg output
			END
		ELSE
			BEGIN
			DELETE [DDTS]
			WHERE [Co] = @company AND [Form] = @form and [SecurityGroup] = @securitygroup and [VPUserName]= ISNULL(@username, '')
			END
			
		UPDATE [DDFS]
		SET [RecAdd] = @add, [RecUpdate] = @update, [RecDelete] = @delete, [Access] = @access, [AttachmentSecurityLevel] = @attach
		WHERE [Co] = @company AND [Form] = @form and [SecurityGroup] = @securitygroup and [VPUserName]= ISNULL(@username, '')

	end
	
--if no form security record currently exists go ahead and create one.
ELSE
	IF @access <> 3
	BEGIN	 
	INSERT INTO [DDFS]
		(AttachmentSecurityLevel,[RecAdd], [RecUpdate], [RecDelete], [Access], [Co], [Form], [SecurityGroup], [VPUserName])
	VALUES  
		(@attach, @add, @update, @delete, @access, @company, @form, @securitygroup, ISNULL(@username, ''))
	END
	
	if @access = 1 and @tab is not null
		BEGIN
		exec @rcode = vspVADDTSUpdateByTab @company, @form, @tab, @securitygroup, @username, @tabaccess, @msg output
		END
	END


 bsperror:
    
    if @rcode <> 0 select @msg = @msg + char(13) + char(20) + '[vspDDFSUpdateSecurity]'
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDFSUpdateSecurity] TO [public]
GO
