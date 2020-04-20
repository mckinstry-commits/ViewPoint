SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspBatchPublishReport]
/************************************
*  Created: Chris G 04/10/13 - TFS Story 44707
* Modified: Chris G 05/01/13 - Reflect schema changes to remove VDocIntegration.vDocumentSecondaryIdentifierType
*           John D  05/06/13 - Add setting of output params for batch ID and BatchMonth
*			Chris G 05/23/13 - TFS Story 44710 Implemented Participant Generation
*			Chris G 06/05/13 - TFS Bug 52015 - Handle empty secondary ids
*
* Inserts the Report publish batch.
*
************************************/
(@company As bCompany,
 @userEmail varchar(128),
 @userFirstName varchar(32),
 @userLastName varchar(32),
 @documentTypeId uniqueidentifier,
 @documentXml xml,
 @documentKeyIdXML xml OUTPUT,
 @batchId int OUTPUT,
 @batchMonth bMonth OUTPUT
 )
as
	SET nocount ON
    DECLARE @msg varchar(255), @senderId as uniqueidentifier, @companyId as uniqueidentifier
    
	BEGIN TRY
		SELECT @batchMonth = dbo.vfDateOnlyMonth()
	
		BEGIN TRANSACTION
		
		-- CREATE the batch in HQBC
		EXEC @batchId = bspHQBCInsert @company, @batchMonth, 'vDocPub', 'Batch.Document', 'N', 'N', null, null, @msg OUTPUT
			 IF @batchId = 0
				BEGIN
				RAISERROR (@msg, 16, 1 );
				END				

		-- CREATE/SELECT the sender.  If sender is not currently setup, create it
		SELECT @senderId = SenderId FROM Document.vSender WHERE Email = @userEmail
		IF @senderId IS NULL
			BEGIN
				SET @senderId = newid()
				INSERT INTO Document.vSender (SenderId, 
											  FirstName, 
											  LastName, 
											  Email, 
											  DisplayName, 
											  CreatedByUser, 
											  DBCreatedDate,
											  Version)
						VALUES (@senderId, 
								@userFirstName, 
								@userLastName, 
								@userEmail,
								@userFirstName + ' ' + @userLastName, 
								SYSTEM_USER, 
								GETDATE(),
								1)
			END
		
		-- GET the Document company.  If not setup, error.
		SELECT @companyId = CompanyId FROM Document.vCompany WHERE V6Id = @company
		IF @companyId IS NULL
			BEGIN
				RAISERROR ('Document company not setup in Document.vCompany', 16, 1 );
			END
			
		-- INSERT the documents from the XML
		INSERT INTO Batch.Document(DocumentId, 
								   Title, 
								   DocumentDisplay,
								   SenderId, 
								   DocumentTypeId, 
								   SentDate,  
								   CompanyId, 
								   [State], 
								   CreatedByUser, 
								   DBCreatedDate, 
								   Version, 
								   Co, 
								   Mth, 
								   BatchId, 
								   BatchSeq, 
								   ProcessingStatus)
				SELECT D.N.value('@Id', 'uniqueidentifier'),
					   D.N.value('@Title', 'varchar(256)'),
					   D.N.value('@DocumentDisplay', 'varchar(256)'),
					   @senderId,
					   @documentTypeId,
					   GETDATE(),					   
					   @companyId,
					   'New',
					   SYSTEM_USER,
					   GETDATE(),					   
					   1,
					   @company,
					   @batchMonth,
					   @batchId,
					   D.N.value('@BatchSeq', 'int'),
					   'New'
				FROM @documentXml.nodes('/batch/document') AS D(N)
		
		-- INSERT the document secondary identifiers
		INSERT INTO Batch.DocumentDictionary(DocumentId, 
											 SecondaryIdentifierTypeId,
											 DictionaryValue,
											 DocumentDictionaryId,
											 Ordinal,
											 CreatedByUser,
											 DBCreatedDate,
											 Version)
				SELECT D.N.value('@Id', 'uniqueidentifier'),
					   S.N.value('@Id', 'uniqueidentifier'),
					   S.N.value('@Value', 'varchar(256)'),
					   newid(),
					   ROW_NUMBER() OVER(PARTITION BY D.N.value('@Id', 'uniqueidentifier') ORDER BY S.N.value('@Id', 'uniqueidentifier')),
					   SYSTEM_USER,
					   GETDATE(),
					   1
				FROM @documentXml.nodes('/batch/document') as D(N)
				  OUTER apply D.N.nodes('secondaryid') as S(N)
				WHERE @documentXml.exist('//secondaryid') = 1

						
		-- INSERT the document to V6 table records
		INSERT INTO Batch.DocumentV6TableRow(DocumentId, 
											 TableKeyId,
											 TableName,
											 CreatedByUser,
											 DBCreatedDate,
											 Version)
				SELECT D.N.value('@Id', 'uniqueidentifier'),
					   D.N.value('@KeyID', 'int'),
					   D.N.value('@TableName', 'varchar(128)'),
					   SYSTEM_USER,
					   GETDATE(),					   
					   1
				FROM @documentXml.nodes('/batch/document') AS D(N)
						
		-- INSERT Participants
		INSERT INTO Batch.Participant(DocumentId, 
									  DocumentRoleTypeId,
									  FirstName,
									  LastName,
									  Email,
									  DisplayName,
									  Title,
									  CompanyNumber,
									  CompanyName,
									  [Status],
									  ParticipantId,									  
									  CreatedByUser,
									  DBCreatedDate,
									  Version,
									  Co, 
								      Mth, 
									  BatchId, 
									  BatchSeq,
									  Seq)
				SELECT D.N.value('@Id', 'uniqueidentifier'),
					   P.N.value('@DocumentRoleTypeId', 'uniqueidentifier'),
					   P.N.value('@FirstName', 'varchar(32)'),
					   P.N.value('@LastName', 'varchar(32)'),
					   P.N.value('@Email', 'varchar(128)'),
					   P.N.value('@DisplayName', 'varchar(64)'),
					   P.N.value('@Title', 'varchar(128)'),
					   P.N.value('@CompanyNumber', 'tinyint'),
					   c.Name,
					   'Associated',
					   newid(),
					   SYSTEM_USER,
					   GETDATE(),
					   1,
					   @company,
					   @batchMonth,
					   @batchId,
					   D.N.value('@BatchSeq', 'int'),
					   ROW_NUMBER () over(order by (select 0))
			  	  FROM @documentXml.nodes('/batch/document') as D(N)
	       OUTER APPLY D.N.nodes('participant') as P(N)
			INNER JOIN HQCO c ON c.HQCo = P.N.value('@CompanyNumber', 'tinyint')
			     WHERE @documentXml.exist('//participant') = 1
				
		-- Return document -> key map via XML
		SET @documentKeyIdXML = (
		  SELECT DocumentId, KeyID
		    FROM [Batch].[vDocument]
		   WHERE Co = @company
		     AND Mth = @batchMonth
		     AND BatchId = @batchId
		ORDER BY BatchSeq
		FOR XML PATH('document'), root('batch')
		)
		
		COMMIT TRANSACTION
    END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
			BEGIN
				ROLLBACK TRANSACTION
			END
			
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT @ErrorMessage = ERROR_MESSAGE(),
			   @ErrorSeverity = ERROR_SEVERITY(),
			   @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
return


GO
GRANT EXECUTE ON  [dbo].[vspBatchPublishReport] TO [public]
GO
