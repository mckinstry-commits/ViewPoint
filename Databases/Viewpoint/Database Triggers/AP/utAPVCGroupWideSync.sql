IF OBJECT_ID('utAPVCGroupWideSync') IS NOT NULL DROP TRIGGER utAPVCGroupWideSync
GO

CREATE TRIGGER [dbo].utAPVCGroupWideSync ON bAPVC AFTER INSERT, UPDATE, DELETE 
AS
/******************************************************************************
Client:		McKinstry Co., LLC
Project:	VU15391 - Sync Vendor Compliance Across Companies
Author:		Neil Jones

			=======================================================================================
			Copyright © 2014 Viewpoint Construction Software (VCS) 
			The T-SQL code in this procedure may not be reproduced, copied, modified,
			or executed without written consent from VCS.
			=========================================================================================

			
Purpose:	For any INSERT, UPDATE /*or DELETE ???*/ to AP Vendor Compliance entries,
			mirror the same insert or update to all Companies' bAPVC entries (if using
			the same vVendorGroup)
			
			bAPVC columns:
				APCo		--Key Field: can't change on front end.
				VendorGroup	--Key Field: can't change on front end.
				Vendor		--Key Field: can't change on front end.
				CompCode	--Key Field: can't change on front end.
				Verify
				ExpDate
				Complied
				Memo  
				UniqueAttchID (n/a? emailed 20141107 *YES, DO ATTACHMENTS. GET A CHANGE ORDER)
				KeyID (n/a)
				
Change Log:

	20141106	NJ	Initial Coding
	20141115	NJ	Separated Attachments handling into custom button proc.
******************************************************************************/
BEGIN TRY

	SET NOCOUNT ON;
	
	--self updating trigger...wrap in IF TRIGGER_NESTLEVEL() < 2
	
	IF TRIGGER_NESTLEVEL() < 2
	BEGIN -- BEGIN TRIGGER NEST_LEVEL DECISION
		
		-- Declare common variables
		DECLARE	@Err_Msg		VARCHAR(MAX),
				@ErrorSeverity	INT,
				@ErrorState		INT
		
		IF OBJECT_ID('tempdb..#APVCChanges') IS NOT NULL 
		BEGIN
			DROP TABLE #APVCChanges
		END
		
		CREATE TABLE #APVCChanges (
				change_id	INT IDENTITY(1,1),
				APCo		TINYINT,
				VendorGroup	TINYINT,
				Vendor		INT,
				CompCode	VARCHAR(10),
				Verify		CHAR(1) NOT NULL DEFAULT('N'),
				ExpDate		SMALLDATETIME,
				Complied	CHAR(1),
				Memo		VARCHAR(255),
				UniqueAttchID UNIQUEIDENTIFIER,
				[Action]		CHAR(1) --'A' = Add/Insert
									--'C' = Change/Update
									--'D' = Remove/Delete
				)
				
		IF OBJECT_ID('tempdb..#APVendGroupComps') IS NOT NULL 
		BEGIN
			DROP TABLE #APVendGroupComps
		END
		
		CREATE TABLE #APVendGroupComps (
				comp_id		INT IDENTITY(1,1),
				VendorGroup	TINYINT,
				APCo		TINYINT)
		
		
		--Collect INSERT's and UPDATE's
		INSERT	#APVCChanges (
				APCo,
				VendorGroup,
				Vendor,
				CompCode,
				Verify,
				ExpDate,
				Complied,
				Memo,
				UniqueAttchID,
				[Action])
		SELECT	i.APCo,
				i.VendorGroup,
				i.Vendor,
				i.CompCode,
				i.Verify,
				i.ExpDate,
				i.Complied,
				i.Memo,
				i.UniqueAttchID,
				[Action] = CASE		
							WHEN d.KeyID IS NULL
								THEN 'A'
							ELSE 'C'
							END
		FROM	inserted AS i
		LEFT JOIN deleted AS d
			ON	d.KeyID = i.KeyID
		
		--Collect DELETE's (looks like delete APVC handles attachments for us)
		INSERT	#APVCChanges (
				APCo,
				VendorGroup,
				Vendor,
				CompCode,
				Verify,
				ExpDate,
				Complied,
				Memo,
				UniqueAttchID,
				[Action])
		SELECT	d.APCo,
				d.VendorGroup,
				d.Vendor,
				d.CompCode,
				d.Verify,
				d.ExpDate,
				d.Complied,
				d.Memo,
				d.UniqueAttchID,
				[Action] = 'D'
		FROM	deleted AS d
		LEFT JOIN inserted AS i
			ON	i.KeyID = d.KeyID
		WHERE	i.KeyID IS NULL
		
		--begin debug
		/*
		BEGIN
			IF NOT EXISTS (	SELECT	TABLE_NAME	
						FROM	INFORMATION_SCHEMA.TABLES
						WHERE	TABLE_NAME = 'VU15391_Debug')
			BEGIN
				CREATE TABLE VU15391_Debug (
					debug_id	INT IDENTITY(1,1),
					change_id	INT,
					APCo		TINYINT,
					VendorGroup	TINYINT,
					Vendor		INT,
					CompCode	VARCHAR(10),
					Verify		CHAR(1) NOT NULL DEFAULT('N'),
					ExpDate		SMALLDATETIME,
					Complied	CHAR(1),
					Memo		VARCHAR(255),
					UniqueAttchID UNIQUEIDENTIFIER,
					[Action]		CHAR(1), --'A' = Add/Insert
										--'C' = Change/Update
										--'D' = Remove/Delete
					debug_ts	DATETIME
					)
			END
			
			INSERT	VU15391_Debug (
					change_id,
					APCo,
					VendorGroup,
					Vendor,
					CompCode,
					Verify,
					ExpDate,
					Complied,
					Memo,
					UniqueAttchID,
					[Action],
					debug_ts
					)
			SELECT	change_id,
					APCo,
					VendorGroup,
					Vendor,
					CompCode,
					Verify,
					ExpDate,
					Complied,
					Memo,
					UniqueAttchID,
					[Action],
					GETDATE() 
			FROM	#APVCChanges
		END
		*/
		--end debug
		
		--Get all Companies sharing the the given Companies Vendor Group
		--	EXCLUDING the company that got the INSERT/UPDATE/DELETE (no need
		--	to sync data that already exists.
		--		*have* to use HQCo because Companies with no Vendor Compliance set up 
		--		yet would be excluded erroneously.
		INSERT	#APVendGroupComps (
				VendorGroup,
				APCo)
		SELECT	hq.VendorGroup,
				ap.APCo
		FROM	dbo.bHQCO as hq
		JOIN	dbo.bAPCO AS ap
			ON	ap.APCo = hq.HQCo
		LEFT JOIN #APVCChanges as chg
			ON	chg.VendorGroup = hq.VendorGroup
		WHERE	chg.APCo <> ap.APCo
		
		--Make any new inserts necessary (items not deleted)
		INSERT	dbo.bAPVC (
				APCo,
				VendorGroup,
				Vendor,
				CompCode,
				Verify,
				ExpDate,
				Complied,
				Memo)
		SELECT	--vc.KeyID,
				others.APCo,			--AS [others.APCo],
				others.VendorGroup,	--AS [others.VendorGroup],
				chg.Vendor,			--AS [chg.Vendor],
				chg.CompCode,		--AS [chg.CompCode],
				chg.Verify,			--AS [chg.Verify],
				chg.ExpDate,			--AS [chg.ExpDate],
				chg.Complied,		--AS [chg.Complied],
				chg.Memo			--AS [chg.Memo],
									--vc.*
		FROM	#APVendGroupComps AS others
		JOIN	#APVCChanges AS chg
			ON	chg.VendorGroup = others.VendorGroup
		LEFT JOIN dbo.bAPVC AS vc
			on	vc.APCo = others.APCo
			AND vc.VendorGroup = others.VendorGroup
			AND vc.Vendor = chg.Vendor
			AND vc.CompCode = chg.CompCode
		WHERE	vc.KeyID IS NULL
			AND chg.Action <> 'D'
		
		--After above insert, all non-deleted entries exist in other companies. Now mirror them. 
		UPDATE	dbo.bAPVC
		SET		Verify = chg.Verify,
				ExpDate = chg.ExpDate,
				Complied = chg.Complied,
				Memo	 = chg.Memo
		FROM	dbo.bAPVC as vc
		JOIN	#APVCChanges AS chg
			--ON	chg.APCo = vc.APCo
			ON	chg.VendorGroup = vc.VendorGroup
			AND chg.Vendor	= vc.Vendor	
			AND chg.CompCode = vc.CompCode
		WHERE	(vc.Verify <> chg.Verify
				OR ISNULL(vc.ExpDate,'1901-01-01') <> ISNULL(chg.ExpDate, '1901-01-01')
				OR ISNULL(vc.Complied,'N') <> ISNULL(vc.Complied,'N')
				OR ISNULL(chg.Memo,'') <> ISNULL(vc.Memo,''))
			AND	chg.Action <> 'D'
		
		--After above UPDATE, all existing entries should now mirror across all companies. 
		--	Now Handle Deletes
		DELETE	dbo.bAPVC
		FROM	dbo.bAPVC AS vc
		JOIN	#APVCChanges AS chg
			ON	chg.VendorGroup = vc.VendorGroup	
			AND chg.Vendor = vc.Vendor
			AND chg.CompCode = vc.CompCode
			AND chg.Action = 'D'
				
	END	-- END TRIGGER NEST_LEVEL DECISION
	
	--COMMIT TRANSACTION
	
END TRY

BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRANSACTION
	END


	SELECT	@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE()

	SELECT	@Err_Msg = ERROR_MESSAGE() + ', custom synchronization trigger for AP Vendor Compliance failed.'
	RAISERROR (@Err_Msg, @ErrorSeverity, @ErrorState);

END CATCH
