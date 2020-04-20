SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspBatchPublishPost]
/************************************
*  Created: Chris G 04/10/13 - TFS Task 45420 Story 44708
*
*   Copies a documents from the Batch schema to the Document schema.
*
*  Returns a table containing DocumentID, Batch UnqueAttchId, Batch KeyID, Document KeyID of the documents posted.
*
************************************/
(@co bCompany,
 @mth bMonth,
 @batchid bBatchID,
 @batchseq int
 )
as
	SET nocount ON

	BEGIN TRY
		DECLARE @msg varchar(255), @rcode int, @postdate DateTime, @processingStatus varchar(25), @batchsource bSource, @batchtable varchar(20)
	
		SET @postdate = GETDATE()		
		
		IF @batchseq = -1
			BEGIN
				SET @batchseq = NULL
			END
				
		BEGIN TRANSACTION
		
		DECLARE @documentsToPublish TABLE (DocumentId uniqueidentifier)
		
		-- Get the documents to publish
		INSERT INTO @documentsToPublish (DocumentId)
					SELECT DocumentId
					  FROM Batch.Document
					 WHERE Co = @co
					   AND Mth = @mth
					   AND BatchId = @batchid
					   AND ProcessingStatus = 'Ready'
					   AND BatchSeq = ISNULL(@batchseq, BatchSeq)
		
		-- Insert Batch.Documents
		INSERT INTO Document.Document (DocumentId,
									   Title,
									   SenderId,
									   DocumentTypeId,
									   DueDate,
									   SentDate,
									   DocumentDisplay,
									   CompanyId,
									   [State],
									   CreatedByUser,
									   UniqueAttchID,
									   DBCreatedDate,
									   Version)
					SELECT doc.DocumentId,
						   doc.Title,
						   doc.SenderId,
						   doc.DocumentTypeId,
						   doc.DueDate,
						   doc.SentDate,
						   doc.DocumentDisplay,
						   doc.CompanyId,
						   doc.[State],
						   doc.CreatedByUser,
						   doc.UniqueAttchID,
						   GetDate(), -- DBCreatedDate
						   1 -- Version
					  FROM @documentsToPublish publish
				INNER JOIN Batch.Document doc ON doc.DocumentId = publish.DocumentId
					   
		-- Insert Batch DocumentDictionary
		INSERT INTO Document.DocumentDictionary (DocumentDictionaryId,
												 DocumentId,
												 SecondaryIdentifierTypeId,
												 DictionaryValue,
												 Ordinal,
												 CreatedByUser,
												 DBCreatedDate,
												 Version)
					SELECT newid(), -- DocumentDictionaryId
						   dict.DocumentId, 
						   dict.SecondaryIdentifierTypeId,
						   dict.DictionaryValue,
						   dict.Ordinal,
						   dict.CreatedByUser,
						   GetDate(), -- DBCreatedDate
						   1 -- Version						   
					  FROM @documentsToPublish publish
				INNER JOIN Batch.DocumentDictionary dict ON dict.DocumentId = publish.DocumentId
		
		-- Insert Batch DocumentV6TableRow
		INSERT INTO Document.DocumentV6TableRow (DocumentId,
												 TableName,
												 TableKeyId,
												 CreatedByUser,
												 DBCreatedDate,
												 Version)
					SELECT tablerow.DocumentId,
						   tablerow.TableName,
						   tablerow.TableKeyId,
						   tablerow.CreatedByUser,
						   GetDate(), -- DBCreatedDate
						   1 -- Version						   
					  FROM @documentsToPublish publish
				INNER JOIN Batch.DocumentV6TableRow tablerow ON tablerow.DocumentId = publish.DocumentId
		
		-- Insert Batch Participants
		INSERT INTO Document.Participant (ParticipantId,
										  DocumentId,
										  FirstName,
										  LastName,
										  Email,
										  DisplayName,
										  Title,
										  CompanyName,
										  CompanyNumber,
										  Status,
										  DocumentRoleTypeId,
										  CreatedByUser,
										  DBCreatedDate,
										  Version)
					SELECT newid(), --ParticipantId
						   participant.DocumentId,
						   participant.FirstName,
						   participant.LastName,
						   participant.Email,
						   participant.DisplayName,
						   participant.Title,
						   participant.CompanyName,
						   participant.CompanyNumber,
						   participant.Status,
						   participant.DocumentRoleTypeId,
						   participant.CreatedByUser,
						   GetDate(), -- DBCreatedDate
						   1 -- Version						   
					  FROM @documentsToPublish publish
				INNER JOIN Batch.Participant participant ON participant.DocumentId = publish.DocumentId
			
		-- Update the ProcessingStatus
		UPDATE Batch.Document SET ProcessingStatus = 'Posted'
			FROM Batch.Document
	  INNER JOIN @documentsToPublish publish ON publish.DocumentId = Batch.Document.DocumentId
		
		-- Return the document ids with attachment ids to code.  Re query the table to catch documents
		-- that were previously posted but never sent or errored.  Edge case but makes it more robust.
		SELECT batchDoc.DocumentId, batchDoc.KeyID, batchDoc.UniqueAttchID, doc.KeyID 
		  FROM Batch.Document batchDoc
	INNER JOIN Document.Document doc ON doc.DocumentId = batchDoc.DocumentId
		 WHERE batchDoc.Co = @co
		   AND batchDoc.Mth = @mth
		   AND batchDoc.BatchId = @batchid
		   AND batchDoc.ProcessingStatus = 'Posted'
		   AND batchDoc.BatchSeq = ISNULL(@batchseq, batchDoc.BatchSeq)
		
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
GRANT EXECUTE ON  [dbo].[vspBatchPublishPost] TO [public]
GO
