IF OBJECT_ID('cspAPVCSyncAttach') IS NOT NULL DROP PROCEDURE cspAPVCSyncAttach
GO

CREATE
--ALTER 
PROCEDURE cspAPVCSyncAttach (
	@Fail int output,
	@ReturnMessage VARCHAR(MAX) OUTPUT,
	@APCo INT,
	@VendorGroup INT,
	@Vendor		INT,
	@CompCode	VARCHAR(10)
	)
AS
/**************************************************************************************************
Client:		McKinstry Co., LLC
Project:	VU15391 - Sync Vendor Compliance Across Companies
Author:		Neil Jones

Purpose:	When this button is clicked, synchronize attachments from the active
			APVC record with this APVC Vendor/CompCode combo for all Companies 
			sharing common VendorGroup

Requirements:
			Button Name: Sync Vendor/Comp Attachments
			
			Button click, or
				EXEC cspAPVCSyncAttach 0,'',1,1,1710,'DL'
			
Change Log:

	20141115	NJ	Initial Coding

**************************************************************************************************/
BEGIN TRY

	SET NOCOUNT ON;
	
	--Declare variables we use
	DECLARE	@FormName		VARCHAR(30),
			@MaxHQATAttachmentID INT,
			@Err_Msg		VARCHAR(MAX),
			@ErrorSeverity	INT,
			@ErrorState		INT,
			@Out_Msg		VARCHAR(MAX),
			@NewAttachmentsToRecords INT,
			@AddAttachmentsToRecords INT,
			@CompCodeDesc	VARCHAR(30)

	--Default @Fail
	SELECT @Fail = 0
	
	--Set the Form Name
	SELECT	@FormName = Form
	FROM	DDFH
	WHERE	ViewName = 'APVC'

	--Identify the last AttachmentID used in HQAT
	SELECT	@MaxHQATAttachmentID = ISNULL(MAX(AttachmentID),0)
	FROM	dbo.HQAT
	
	--Get Description for the Compliance Code (for messaging back to user)
	SELECT	@CompCodeDesc = Description
	FROM	HQCP
	WHERE	CompCode = @CompCode
	
	--Determine if the record wsa saved before button clicked
	--	(Theoretically, even if the button is clicked after the 
	--	 the record is saved, there wouldn't be an attachment at
	--	 that point, but keep this hedge in there.)
	IF	(SELECT KeyID 
		 FROM	dbo.bAPVC
		 WHERE	APCo = @APCo
			AND	VendorGroup = @VendorGroup
			AND Vendor = @Vendor
			AND CompCode = @CompCode) IS NULL
	BEGIN
	
		SELECT	@Fail = 1
		SELECT	@ReturnMessage = 'ERROR: Please save this record before synchronizing attachments.'
		
		--RETURN	@Fail	
	END
	
	--OK to proceed
	IF (@Fail <> 1)
	--begin "record saved: OK to proceed" block
	BEGIN
		--pre-game ReturnMessage
		SELECT	@Out_Msg	= 'Attachments Sychronization for VendorGroup: '
							+ CAST(@VendorGroup AS VARCHAR)
							+ ', Vendor: '
							+ CAST(@Vendor AS VARCHAR)
							+ ', Compliance Code: ' 
							+ CAST(@CompCode AS VARCHAR)
							+ ' (' + @CompCodeDesc + ') '
							+ CHAR(10)
				
		--TempTable to store impacted entries. We will either use their existing UniqueAttachID's (if the records
		--	already had at least one attachment, or set new ones as necessary
		IF OBJECT_ID('tempdb..#APVCNewUniqueAttchIDs') IS NOT NULL
		BEGIN DROP TABLE #APVCNewUniqueAttchIDs END

		CREATE TABLE #APVCNewUniqueAttchIDs (
				new_attach_id	INT IDENTITY(1,1),
				VCAPCo			INT,
				VCVendorGroup	INT,
				VCVendor		INT,
				VCCompCode		VARCHAR(10),
				VCCurrentUniqueAttchID UNIQUEIDENTIFIER,
				VCUniqueAttchID UNIQUEIDENTIFIER,
				VCKeyID			INT
				)

		--Temp table to store the information that will be inserted to HQAT
		IF OBJECT_ID('tempdb..#HQATSync') IS NOT NULL
		BEGIN DROP TABLE #HQATSync END

		CREATE TABLE #HQATSync (
				at_sync_id			INT IDENTITY(1,1),
				VCAPCo			INT,
				VCVendorGroup	INT,
				VCVendor		INT,
				VCCompCode		VARCHAR(10),
				VCUniqueAttchID UNIQUEIDENTIFIER,
				ATOrigAttachID	INT,
				ATHQCo			INT,
				ATFormName		VARCHAR(30),
				ATKeyField		VARCHAR(500),
				ATDescription	VARCHAR(255),
				ATAddedBy		VARCHAR(128),
				ATAddDate		SMALLDATETIME,
				ATDocName		VARCHAR(512),
				ATAttachmentID	INT,
				ATTableName		VARCHAR(128),
				ATUniqueAttchID	UNIQUEIDENTIFIER,
				ATOrigFileName	VARCHAR(512),
				ATDocAttchYN	CHAR(1) NOT NULL DEFAULT('N'),
				ATCurrentState	CHAR(1) NOT NULL DEFAULT('A'),
				ATAttachmentTypeID	INT,
				ATIsEmail		CHAR(1) NOT NULL DEFAULT('N')
				)

		--Temp table to store the information that will be inserted to HQAI
		IF OBJECT_ID('tempdb..#HQAISync') IS NOT NULL
		BEGIN DROP TABLE #HQAISync END

		CREATE TABLE #HQAISync (
				ai_sync_id	INT IDENTITY(1,1),
				AIAttachmentID	INT,
				AIIndexSeq		INT,
				AIAPCo			INT,
				AIVendorGroup	INT,
				AIVendor		INT,
				AICustomYN		CHAR(1) NOT NULL DEFAULT('N')
				)

		/* BEGIN ACTION IF ATTACHMENT EXISTS ON ORIGINATING RECORD */
		IF	(SELECT	vc.UniqueAttchID
			 FROM	dbo.bAPVC AS vc
			 WHERE	vc.APCo = @APCo
				AND	vc.VendorGroup = @VendorGroup
				AND	vc.Vendor = @Vendor
				AND vc.CompCode = @CompCode) IS NOT NULL
		BEGIN
			--BEGIN First Pass: Impacted records with no current attachments 
			BEGIN	
				
				--Get all impcted APVC records with *no* current attachment
				INSERT	#APVCNewUniqueAttchIDs (
						VCAPCo,
						VCVendorGroup,
						VCVendor,
						VCCompCode,
						VCCurrentUniqueAttchID,
						VCUniqueAttchID,
						VCKeyID)
				SELECT	DISTINCT
						vc.APCo,
						vc.VendorGroup,
						vc.Vendor,	
						vc.CompCode,
						[VCCurrentUniqueAttchID] = vc.UniqueAttchID,
						[VCUniqueAttchID] = NEWID(),
						vc.KeyID
				FROM	dbo.bAPVC AS vc
				WHERE	vc.APCo <> @APCo
					AND	vc.VendorGroup = @VendorGroup
					AND	vc.Vendor = @Vendor
					AND vc.CompCode = @CompCode
					AND vc.UniqueAttchID IS NULL
						
				--Get Original APVC Record's HQAT information, make versions for the Impacted APVC Records
				INSERT	#HQATSync (
						VCAPCo,
						VCVendorGroup,
						VCVendor,
						VCCompCode,
						VCUniqueAttchID,
						ATOrigAttachID,
						ATHQCo,
						ATFormName,
						ATKeyField,
						ATDescription,
						ATAddedBy,
						ATAddDate,
						ATDocName,
						ATAttachmentID,
						ATTableName,
						ATUniqueAttchID,
						ATOrigFileName,
						ATDocAttchYN,
						ATCurrentState,
						ATAttachmentTypeID,
						ATIsEmail
						)
				SELECT	--'For #HQATSync',
						--'CurrentMaxAttachID' = @MaxHQATAttachmentID,
						[VCAPCo]			= vc.APCo,
						[VCVendorGroup]		= vc.VendorGroup,
						[VCVendor]			= vc.Vendor,
						[VCCompCode]		= vc.CompCode,
						[VCUniqueAttchID]	= newAttach.VCUniqueAttchID,
						[ATOrigAttachID]	= at.AttachmentID,
						[ATHQCo]			= vc.APCo,
						[ATFormName]		= @FormName,
						[ATKeyField]		= 'KeyID=' + CAST(newAttach.VCKeyID AS VARCHAR),
						[ATDescription] 	= at.Description,
						[ATAddedBy]			= SUSER_SNAME(),
						[ATAddDate]			= GETDATE(),
						[ATDocName]			= at.DocName,
						[ATAttachmentID]	= @MaxHQATAttachmentID +
											  ROW_NUMBER() OVER (PARTITION BY	newAttach.VCVendorGroup,
																				newAttach.VCVendor,
																				newAttach.VCCompCode,
																				at.UniqueAttchID
																	ORDER BY	vc.KeyID ASC,
																				at.AttachmentID ASC),		
						[ATTableName] 		= at.TableName,
						[ATUniqueAttchID]	= newAttach.VCUniqueAttchID,														
						[ATOrigFileName]	= at.OrigFileName,
						[ATDocAttchYN]		= at.DocAttchYN,
						[ATCurrentState]	= at.CurrentState,
						[ATAttachmentTypeID] = at.AttachmentTypeID,
						[ATIsEmail]			= at.IsEmail
				FROM	bAPVC AS vc
				JOIN	#APVCNewUniqueAttchIDs AS newAttach
					ON	newAttach.VCAPCo = vc.APCo
					AND newAttach.VCVendorGroup = vc.VendorGroup
					AND newAttach.VCVendor = vc.Vendor
					AND newAttach.VCCompCode = vc.CompCode
				JOIN	bHQAT AS at
					ON at.UniqueAttchID = (SELECT	UniqueAttchID 		
											FROM	bAPVC
											WHERE	APCo = @APCo
												AND	VendorGroup = @VendorGroup
												AND Vendor = @Vendor
												AND CompCode = @CompCode)
				WHERE	vc.APCo <> @APCo
					AND vc.VendorGroup = @VendorGroup	
					AND	vc.Vendor = @Vendor
					AND vc.CompCode = @CompCode	
					--First touch records with no current attachment
					AND vc.UniqueAttchID IS NULL							
				
				--Get Original APVC Record's HQAI information, make versions for the Impacted APVC Records
				INSERT	#HQAISync (
						AIAttachmentID,
						AIIndexSeq,
						AIAPCo,
						AIVendorGroup,
						AIVendor,
						AICustomYN)
						
				SELECT	--'HQAI',
						[newAttachmentID] = atSync.ATAttachmentID,
						[NewIndexSeq] = ai.IndexSeq,
						[NewAPCo] = atSync.VCAPCo,
						[NewVendorGroup] = atSync.VCVendorGroup,
						[NewVendor] = atSync.VCVendor,
						[NewCustomYN] = ai.CustomYN--,
				FROM	bAPVC AS vc
				JOIN	#APVCNewUniqueAttchIDs AS newAttach
					ON	newAttach.VCAPCo = vc.APCo
					AND newAttach.VCVendorGroup = vc.VendorGroup
					AND newAttach.VCVendor = vc.Vendor
					AND newAttach.VCCompCode = vc.CompCode
				JOIN	#HQATSync as atSync
					ON	atSync.VCAPCo = vc.APCo
					AND atSync.VCVendorGroup = vc.VendorGroup
					AND atSync.VCVendor = vc.Vendor
					AND atSync.VCCompCode = vc.CompCode
				JOIN	bHQAI as ai
					ON	ai.AttachmentID = atSync.ATOrigAttachID
				WHERE	vc.APCo		<> @APCo
					AND	vc.VendorGroup = @VendorGroup
					AND vc.Vendor = @Vendor
					AND vc.CompCode = @CompCode

				/* SYNC TABLES HAVE BEEN CREATED. update APVC and insert HQAT/I appropriately */
				UPDATE	bAPVC 
				SET		UniqueAttchID = VCNewID.VCUniqueAttchID
				FROM	bAPVC AS vc
				JOIN	#APVCNewUniqueAttchIDs AS VCNewID
					ON	VCNewID.VCAPCo = vc.APCo
					AND VCNewID.VCVendorGroup = vc.VendorGroup
					AND VCNewID.VCVendor = vc.Vendor
					AND VCNewID.VCCompCode = vc.CompCode
					
				INSERT	bHQAT (
						HQCo,
						FormName,
						KeyField,
						Description,
						AddedBy,
						AddDate,
						DocName,
						AttachmentID,
						TableName,
						UniqueAttchID,
						OrigFileName,
						DocAttchYN,
						CurrentState,
						AttachmentTypeID,
						IsEmail)
				SELECT	ATHQCo,
						ATFormName,
						ATKeyField,
						ATDescription,
						ATAddedBy,
						ATAddDate,
						ATDocName,
						ATAttachmentID,
						ATTableName,
						ATUniqueAttchID,
						ATOrigFileName,
						ATDocAttchYN,
						ATCurrentState,
						ATAttachmentTypeID,
						ATIsEmail
				FROM	#HQATSync

				INSERT	dbo.bHQAI (
						AttachmentID,
						IndexSeq,
						APCo,
						APVendorGroup,
						APVendor,
						CustomYN)
				SELECT	AIAttachmentID,
						AIIndexSeq,
						AIAPCo,
						AIVendorGroup,
						AIVendor,
						AICustomYN
				FROM	#HQAISync
				
				--Compile results to report to user
				SELECT	@NewAttachmentsToRecords =  COUNT(at_sync_id)
				FROM	#HQATSync
				
				IF (@NewAttachmentsToRecords) > 0
				BEGIN	
					
					SELECT	@Out_Msg =  @Out_Msg	
										+ CHAR(10)
										+ 'Added "'
										+ ATOrigFileName
										+ '" to AP Company '
										+ CAST(VCAPCo AS VARCHAR) + '.'
										+ CHAR(10)
					FROM	#HQATSync
				END
				
			END 
			--END First Pass: Impacted records with no current attachments
			
			-- FIRST PASS DONE clear out Temp Tables and re-init var(s) for re-usage in SECOND PASS
			/*	*/
			DELETE	#APVCNewUniqueAttchIDs;
			DELETE	#HQATSync;
			DELETE	#HQAISync;
			
			SELECT	@MaxHQATAttachmentID = ISNULL(MAX(AttachmentID),0)
			FROM	dbo.HQAT
			
			--BEGIN Second Pass: Impacted APVC records *with* current attachments
			BEGIN
			
				INSERT	#APVCNewUniqueAttchIDs (
						VCAPCo,
						VCVendorGroup,
						VCVendor,
						VCCompCode,
						VCUniqueAttchID,
						VCKeyID) 
				SELECT	DISTINCT
						vc.APCo,
						vc.VendorGroup,
						vc.Vendor,	
						vc.CompCode,
						[VCUniqueAttchID] = vc.UniqueAttchID,
						vc.KeyID
				FROM	dbo.bAPVC AS vc
				WHERE	vc.APCo <> @APCo
					AND	vc.VendorGroup = @VendorGroup
					AND	vc.Vendor = @Vendor
					AND vc.CompCode = @CompCode
				
				--Get Original APVC Record's HQAT information, make versions for the Impacted APVC Records
				INSERT	#HQATSync (
						VCAPCo,						
						VCVendorGroup,				
						VCVendor,					
						VCCompCode,					
						VCUniqueAttchID,			
						ATHQCo,						
						ATFormName,					
						ATKeyField,					
						ATDescription,				
						ATAddedBy,					
						ATAddDate,					
						ATDocName,					
						ATAttachmentID,				
						ATTableName,				
						ATUniqueAttchID,			
						ATOrigFileName,				
						ATDocAttchYN,				
						ATCurrentState,				
						ATAttachmentTypeID,			
						ATIsEmail,
						ATOrigAttachID)					
				SELECT	--'#HQATSync',				
						[VCAPCo] = newAttach.VCAPCo,		
						[VCVendorGroup] = newAttach.VCVendorGroup, 
						[VCVendor] = newAttach.VCVendor,		
						[VCCompCode] = newAttach.VCCompCode,
						[VCUniqueAttchID] = newAttach.VCUniqueAttchID,
						[ATHQCo] =	newAttach.VCAPCo,
						[ATFormName] = orig_at.FormName,
						[ATKeyField] = 	'KeyID=' + CAST(vc.KeyID AS VARCHAR),  
						[ATDescription] = orig_at.Description,
						[ATAddedBy] = SUSER_SNAME(),
						[ATAddDate] = GETDATE(),									
						[ATDocName] = orig_at.DocName,						
						 										
						[ATAttachmentID]	= @MaxHQATAttachmentID +
												ROW_NUMBER() OVER (PARTITION BY	newAttach.VCVendorGroup,
																				newAttach.VCVendor,
																				newAttach.VCCompCode,
																				at.UniqueAttchID
																	ORDER BY	vc.KeyID ASC,
																				at.AttachmentID ASC),
						[ATTableName] =	orig_at.TableName,	
						[ATUniqueAttchID] = newAttach.VCUniqueAttchID,
						[ATOrigFileName] = orig_at.OrigFileName,
						[ATDocAttchYN] = orig_at.DocAttchYN,
						[ATCurrentState] = orig_at.CurrentState,
						[ATAttachmentTypeID] = orig_at.AttachmentTypeID,
						[ATIsEmail)] = orig_at.IsEmail,
						[ATOrigAttachID] = orig_at.AttachmentID
				
				FROM	bAPVC as vc
				JOIN	#APVCNewUniqueAttchIDs AS newAttach
				ON		newAttach.VCAPCo		= vc.APCo
					AND	newAttach.VCVendorGroup = vc.VendorGroup
					AND newAttach.VCVendor		= vc.Vendor
					AND newAttach.VCCompCode	= vc.CompCode
				JOIN bHQAT as orig_at
					ON	orig_at.UniqueAttchID = (SELECT	UniqueAttchID 		
												FROM	bAPVC
												WHERE	APCo = @APCo
													AND	VendorGroup = @VendorGroup
													AND Vendor = @Vendor
													AND CompCode = @CompCode)
															
				LEFT JOIN bHQAT AS at
					ON	at.UniqueAttchID = newAttach.VCUniqueAttchID
					/* Bottom two lines are qustionable but not sure how else we can accomplish this */
					AND	(at.OrigFileName = orig_at.OrigFileName
						OR	at.DocName = orig_at.DocName)
				
				WHERE	vc.VendorGroup = @VendorGroup	
					AND	vc.Vendor = @Vendor
					AND vc.CompCode = @CompCode	
					AND at.HQCo IS NULL
					
				--Get Original APVC Record's HQAI information, make versions for the Impacted APVC Records
				INSERT	#HQAISync (
						AIAttachmentID,
						AIIndexSeq,
						AIAPCo,
						AIVendorGroup,
						AIVendor,
						AICustomYN)
				SELECT	--'HQAI',
						[newAttachmentID] = atSync.ATAttachmentID,
						[NewIndexSeq] = ai.IndexSeq,
						[NewAPCo] = atSync.VCAPCo,
						[NewVendorGroup] = atSync.VCVendorGroup,
						[NewVendor] = atSync.VCVendor,
						[NewCustomYN] = ai.CustomYN--,
				FROM	bAPVC AS vc
				JOIN	#APVCNewUniqueAttchIDs AS newAttach
					ON	newAttach.VCAPCo = vc.APCo
					AND newAttach.VCVendorGroup = vc.VendorGroup
					AND newAttach.VCVendor = vc.Vendor
					AND newAttach.VCCompCode = vc.CompCode
				JOIN	#HQATSync as atSync
					ON	atSync.VCAPCo = vc.APCo
					AND atSync.VCVendorGroup = vc.VendorGroup
					AND atSync.VCVendor = vc.Vendor
					AND atSync.VCCompCode = vc.CompCode
				LEFT JOIN	bHQAI as ai
					ON	ai.AttachmentID = atSync.ATOrigAttachID
				WHERE	vc.APCo		<> @APCo
					AND	vc.VendorGroup = @VendorGroup
					AND vc.Vendor = @Vendor
					AND vc.CompCode = @CompCode
				
				/* SYNC TABLES HAVE BEEN CREATED. update APVC (n/a in this pass, since APVC all has UniqueAttchID's by now )
					and insert HQAT/I appropriately  */
				INSERT	bHQAT (
						HQCo,
						FormName,
						KeyField,
						Description,
						AddedBy,
						AddDate,
						DocName,
						AttachmentID,
						TableName,
						UniqueAttchID,
						OrigFileName,
						DocAttchYN,
						CurrentState,
						AttachmentTypeID,
						IsEmail)
				SELECT	ATHQCo,
						ATFormName,
						ATKeyField,
						ATDescription,
						ATAddedBy,
						ATAddDate,
						ATDocName,
						ATAttachmentID,
						ATTableName,
						ATUniqueAttchID,
						ATOrigFileName,
						ATDocAttchYN,
						ATCurrentState,
						ATAttachmentTypeID,
						ATIsEmail
				FROM	#HQATSync

				INSERT	dbo.bHQAI (
						AttachmentID,
						IndexSeq,
						APCo,
						APVendorGroup,
						APVendor,
						CustomYN)
				SELECT	AIAttachmentID,
						AIIndexSeq,
						AIAPCo,
						AIVendorGroup,
						AIVendor,
						AICustomYN
				FROM	#HQAISync
				
				--Compile results to report to user
				SELECT	@AddAttachmentsToRecords =  COUNT(at_sync_id)
				FROM	#HQATSync
				
				IF (@AddAttachmentsToRecords) > 0
				BEGIN	
					SELECT	@Out_Msg =  @Out_Msg	
										+ CHAR(10)
										+ 'Added "'
										+ ATOrigFileName
										+ '" to AP Company '
										+ CAST(VCAPCo AS VARCHAR) + '.'
										+ CHAR(10)
					FROM	#HQATSync
				END
			END
			--END Second Pass: Impacted APVC records *with* current attachments
			
			--If there was nothing to do becuase all attachments match the Originating Record, report back appropriately.
			SELECT	@Out_Msg = @Out_Msg + CHAR(10) + 'Completed' 
								+ CASE 
									WHEN (@NewAttachmentsToRecords + @AddAttachmentsToRecords) = 0
										THEN '. All other AP Companies in VendorGroup '
												+ CAST(@VendorGroup AS VARCHAR)
												+ ' already have matching attachments for this Vendor/Compliance Code.'
										ELSE '.'
										END
		END
		/* END ACTION IF ATTACHMENT EXISTS ON ORIGINATING RECORD */
		ELSE	-- If we're in this block, originating record had no attachments. Report error to user */

		/* BEGIN ACTION IF NO ATTACHMENT EXISTS ON ORIGINATING RECORD */
		BEGIN
		
			--If there was nothing to do becuase no attachments on the Originating Record, report back appropriately.
			SELECT	@Out_Msg	= @Out_Msg
								+ CHAR(10)
								+ 'No attachments in Company '
								+ CAST(@APCo AS VARCHAR) 
								+ ' to synchronize.'
					
		END
		/* END ACTION IF NO ATTACHMENT EXISTS ON ORIGINATING RECORD */
		
	END
	--end "record saved: OK to proceed" block
	
	--Done: report out results
	BEGIN
		
		--if @Out_Msg IS NULL, then the "record saved: OK to proceed" block was never entered, so use the @ReturnMessage previously set.
		SELECT	@ReturnMessage = ISNULL(@Out_Msg,@ReturnMessage)
		RETURN	@Fail
	END
	
END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRANSACTION
	END


	SELECT	@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE()

	SELECT	@Err_Msg = 'AP Vendor Compliance Attachment Sync failed: '
					 + CHAR(10) 
					 + CHAR(10) 
					 + 'cspAPVCSyncAttach error at line: ' + CAST(ERROR_LINE() AS VARCHAR) + '. '
					 + CHAR(10)
					 + CHAR(10)
					 + ERROR_MESSAGE()
					 
	RAISERROR (@Err_Msg, @ErrorSeverity, @ErrorState);

END CATCH
GO

GRANT EXECUTE ON [cspAPVCSyncAttach] to PUBLIC
GO