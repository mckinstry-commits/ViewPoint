SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [dbo].[vspPMProjectDefaultTemplatesInsert]
/*************************************
* Created By:	TRL 05/13/2013   User Story 13608 Define templates b Project
* Modified By:	SCOTTP 06/10/2013 TFS-13608  Select KeyID so that caller knows the keyID just used/created
*
* Purpose: Add, update and delete records from form PM Project Default Templates
*
*	
*
* Success returns:
* 0
*
* Error returns:
*
**************************************/
(@PMCo bCompany, @Project bProject, @DocumentCategory varchar(10), @DocumentType bDocType, 
@Template varchar(40), @Action varchar(10), @KeyID int, @DefaultYN bYN, @NewKeyID int output, @errmsg varchar(255) output)

AS 

SET NOCOUNT ON

SET @NewKeyID = -1

If @Action = 'delete'
BEGIN
	If @KeyID is NULL
	BEGIN
		SELECT @errmsg = 'Missing KeyID, cannot delete record'
		RETURN 1
	END
	DELETE FROM dbo.PMProjectMasterTemplates WHERE PMProjectMasterTemplates.KeyID  = @KeyID	
END

IF @Action = 'update'
BEGIN
	If @KeyID is NULL
	BEGIN
		SELECT @errmsg = 'Missing KeyID, cannot update record'
		RETURN 1
	END

	UPDATE dbo.PMProjectMasterTemplates 
	SET DefaultYN = IsNULL(@DefaultYN,'N')
	WHERE KeyID = @KeyID
	
	SET @NewKeyID = @KeyID
END

IF @Action = 'add'
BEGIN
	IF @PMCo IS NULL
	BEGIN
		SELECT @errmsg = 'PMCo can not be null'
		RETURN 1
	END

	IF @Project IS NULL
	BEGIN
		SELECT @errmsg = 'Project can not be null'
		RETURN 1
	END

	IF @DocumentCategory IS NULL	
	BEGIN
		SELECT @errmsg = 'Document Category can not be null'
		RETURN 1
	END

	IF @Template IS NULL	
	BEGIN
		SELECT @errmsg = 'Template can not be null'
		RETURN 1
	END

	INSERT INTO dbo.PMProjectMasterTemplates(PMCo,Project,DocCategory,DocType,DefaultTemplate,DefaultYN )
	Select @PMCo,@Project,@DocumentCategory,@DocumentType, @Template, IsNULL(@DefaultYN,'N')	
	
	SET @NewKeyID = SCOPE_IDENTITY()
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectDefaultTemplatesInsert] TO [public]
GO
