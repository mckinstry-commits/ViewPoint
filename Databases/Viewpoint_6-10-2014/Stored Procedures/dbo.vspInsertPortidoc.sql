SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.vspInsertPortidoc
@Title NVARCHAR(256),
@DocumentDisplay NVARCHAR(256),
@CreateUser NVARCHAR(128),
@TableName NVARCHAR(128),
@KeyId BIGINT,
@FileName NVARCHAR(128),
@DocumentData VARBINARY(MAX),
@DocumentSize int,
@ContentType nvarchar(32),
@DocType nvarchar(60),
@Company bCompany,
@DocumentId uniqueidentifier OUTPUT ,
@ParticipantId uniqueidentifier OUTPUT

AS  

BEGIN
SET NOCOUNT ON;

	DECLARE @now datetime,
			@docTypeId uniqueidentifier,
			@SenderId uniqueidentifier
			;
	
	SELECT	@DocumentId = NEWID(),
			@ParticipantId = NEWID(),
			@now = GETDATE();
	
	SELECT @docTypeId = DocumentTypeId
	FROM Document.DocumentType
	WHERE DocumentTypeName = @DocType;
	
	IF NOT EXISTS(SELECT TOP 1 1 FROM Document.Company WHERE V6Id = @Company)
	BEGIN
		INSERT INTO Document.Company ( CompanyId, CompanyName, CreatedByUser, DBCreatedDate, Version, V6Id )
		SELECT	NEWID(), 
				HQCO.Name, 
				@CreateUser, 
				GETUTCDATE(),
				1,
				@Company
		FROM dbo.bHQCO HQCO
		WHERE HQCo = @Company;
	END
	

	SELECT @SenderId = SenderId
	FROM dbo.vDDUP DDUP
	INNER JOIN Document.Sender ON Document.Sender.Email = DDUP.EMail
	WHERE DDUP.VPUserName = @CreateUser;
			
	INSERT INTO Document.Document 
	( 
		DocumentId, 
		Title, 
		SenderId, 
		DocumentTypeId, 
		DueDate, 
		SentDate, 
		DocumentDisplay, 
		CompanyId, 
		State, 
		CreatedByUser, 
		DBCreatedDate, 
		Version )
		SELECT
			@DocumentId,
			@Title,
			@SenderId,
			@docTypeId, --DocTypeId
			DATEADD(D,7,@now),
			@now,
			@DocumentDisplay,
			Company.CompanyId,
			'Open',
			@CreateUser,
			@now,
			1
		FROM Document.Company
		WHERE Company.V6Id = @Company;					
	
	INSERT INTO Document.Participant ( ParticipantId, FirstName, LastName, Email, DisplayName, Title, CompanyName, CompanyNumber, DocumentId, Status, DocumentRoleTypeId, CreatedByUser, DBCreatedDate, Version )
	SELECT	@ParticipantId,
			FirstName,
			LastName,
			Email,
			DisplayName,
			Title,
			'', --CompanyName,
			@Company,
			@DocumentId,
			'Associated',
			'DA219A84-5E3F-4346-911D-48251E4D6D8C', -- Publisher from DocumentRoleType
			@CreateUser,
			GETUTCDATE(),
			1
	FROM Document.Sender
	WHERE Document.Sender.SenderId = @SenderId;
		
	INSERT INTO Document.DocumentV6TableRow (DocumentId, TableName, TableKeyId, CreatedByUser, DBCreatedDate, Version)
	VALUES (@DocumentId, @TableName, @KeyId, @CreateUser, @now, 1);
	
	INSERT INTO Document.DocumentAttachment ( AttachmentId, FullName, AttachmentData, AttachmentSize, ContentType, DocumentId, DocumentImage, ParticipantId, CreatedByUser, DBCreatedDate, Version)
	VALUES (NEWID(), @FileName , @DocumentData, @DocumentSize, @ContentType, @DocumentId, 1, @ParticipantId, @CreateUser, @now, 1);

END
GO
GRANT EXECUTE ON  [dbo].[vspInsertPortidoc] TO [public]
GO
