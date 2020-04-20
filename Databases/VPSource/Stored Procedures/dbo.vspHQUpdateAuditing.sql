SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 12/8/11
-- Description:	Updates auditing for a given HQ
-- Modified:
-- =============================================

CREATE PROCEDURE [dbo].[vspHQUpdateAuditing]
	@ContactGroup bGroup, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @AuditFlagID smallint

	SELECT @AuditFlagID = KeyID
	FROM dbo.vAuditFlags
	WHERE FlagName = 'Contacts' AND Module = 'HQ' 

	IF EXISTS(SELECT 1 FROM dbo.HQCO WHERE ContactGroup = @ContactGroup AND AuditContact = 'Y')
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.vAuditFlagGroup WHERE AuditGroup = @ContactGroup AND AuditFlagID = @AuditFlagID)
		BEGIN
			--Insert the entries needed to allow auditing
			INSERT dbo.vAuditFlagGroup (AuditGroup, AuditFlagID)
			VALUES (@ContactGroup, @AuditFlagID)
		END
	END
	ELSE
	BEGIN
		--Remove the entries needed to prevent auditing
		DELETE dbo.vAuditFlagGroup
		WHERE AuditGroup = @ContactGroup AND AuditFlagID = @AuditFlagID
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspHQUpdateAuditing] TO [public]
GO
