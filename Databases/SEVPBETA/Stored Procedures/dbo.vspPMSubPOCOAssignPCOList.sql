SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspPMSubPOCOAssignPCOList]

/***********************************************************
* CREATED BY:	DAN SO	12/20/2011 - TK-11052
* MODIFIED BY:	GP		5/2/2011 - TK-14635 Added @Notes update to PMSL, PMMF
*				GF 05/22/2012 TK-13889 #145421 DO NOT AUTO APPROVE THE SCO FROM HERE
*				
* USAGE:
*	Used in PM Subcontract CO and Purchase Order CO to
*	assign PCO's to either SubCO's or POCO's
*
* INPUT PARAMETERS
*   @PCOKeyIDs	String of PCO KeyIDs  
*	@Type		SL or PO
*	@CONum		Change Order Number
*
* OUTPUT PARAMETERS
*   @msg      Error message
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

	(@PCOKeyIDs varchar(max), @Type varchar(2), @CONum smallint, @msg varchar(255) output)

	AS
	SET NOCOUNT ON

	DECLARE @KeyID		bigint,
			@PMOLKeyID	bigint,
			@SeqNum		smallint,
			@Notes		bNotes,
			@rcode		tinyint
	
	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @KeyID = 0
	SET @rcode = 0
	SET @PMOLKeyID = 0
	SET @SeqNum	= 0
	SET @msg = 'The following PCOs failed to process: ' + char(13) + char(10)

	--------------------------------
	-- VERIFY INCOMING PARAMETERS --
	--------------------------------
	IF @PCOKeyIDs IS NULL
	BEGIN
		SELECT @msg = 'Missing PCOKeyIDs.', @rcode = 1
		GOTO vspexit
	END
		
	IF (@Type IS NULL) OR (@Type NOT IN ('SL','PO'))
	BEGIN
		SELECT @msg = 'Missing or Invalid SL/PO Type.', @rcode = 1
		GOTO vspexit
	END

	IF @CONum IS NULL
	BEGIN
		SELECT @msg = 'Missing Change Order Number.', @rcode = 1
		GOTO vspexit
	END
	
	--------------------------
	-- LOOP THRU @PCOKeyIDs --
	--------------------------
	WHILE ISNULL(@PCOKeyIDs,'') <> ''
	BEGIN
	
		BEGIN TRY
		BEGIN TRANSACTION
		
			-----------------------
			-- GET NEXT PCOKeyID --
			-----------------------
			IF CHARINDEX(',',@PCOKeyIDs) <> 0
			BEGIN
				SET @KeyID = CAST(SUBSTRING(@PCOKeyIDs, 0, CHARINDEX(',',@PCOKeyIDs)) AS BIGINT)
				
				-- REMOVE KeyID FROM @PCOKeyIDs --
				SET @PCOKeyIDs = SUBSTRING(@PCOKeyIDs, CHARINDEX(',',@PCOKeyIDs) + 1, LEN(@PCOKeyIDs))
			END	
			ELSE
			BEGIN
				-- GET LAST KeyID IN @PCOKeyIDs --
				SET @KeyID = CAST(@PCOKeyIDs AS BIGINT)
				SET @PCOKeyIDs = NULL
			END
			
			
			-------------------
			-- UPDATE TABLES --
			-------------------
			IF @Type = 'SL'
			BEGIN	
				-- GET INFO --
				SELECT @SeqNum = sl.Seq, @PMOLKeyID = ol.KeyID, @Notes = ol.Notes 
				FROM dbo.PMSL sl
				LEFT JOIN dbo.PMOL ol ON ol.PMCo=sl.PMCo AND ol.Project=sl.Project 
					AND ol.PCOType=sl.PCOType AND ol.PCO=sl.PCO AND ol.PCOItem=sl.PCOItem
					AND ol.Phase=sl.Phase AND ol.CostType=sl.CostType
				WHERE sl.KeyID = @KeyID
					
				-- UPDATE PMSL --
				----TK-13889 the IntFlag will control approving the SCO
				UPDATE bPMSL
				SET SubCO = @CONum
					,IntFlag = 'C'
					,Notes = CASE WHEN Notes is null THEN @Notes ELSE Notes + COALESCE(CHAR(32) + CHAR(10) + CHAR(13) + @Notes,'') END
				WHERE KeyID = @KeyID

				-- UPDATE PMOL --
				UPDATE bPMOL
				SET SubCO = @CONum, SubCOSeq = @SeqNum
				WHERE KeyID = @PMOLKeyID
				
				---- TK-13889 RESET IntFlag back to null
				UPDATE bPMSL SET IntFlag = NULL
				WHERE KeyID = @KeyID
			END
			
			ELSE 
				IF @Type = 'PO'
				BEGIN
					-- GET INFO --
					SELECT @SeqNum = mf.Seq, @PMOLKeyID = ol.KeyID, @Notes = ol.Notes
					FROM dbo.PMMF mf
					LEFT JOIN dbo.PMOL ol ON ol.PMCo=mf.PMCo AND ol.Project=mf.Project 
						AND ol.PCOType=mf.PCOType AND ol.PCO=mf.PCO AND ol.PCOItem=mf.PCOItem
						AND ol.Phase=mf.Phase AND ol.CostType=mf.CostType
					WHERE mf.KeyID = @KeyID

					-- UPDATE PMMF --
					UPDATE bPMMF
					SET POCONum = @CONum, 
						Notes = CASE WHEN Notes is null THEN @Notes ELSE Notes + COALESCE(CHAR(32) + CHAR(10) + CHAR(13) + @Notes,'') END
					WHERE KeyID = @KeyID

					-- UPDATE PMOL --
					UPDATE bPMOL
					SET POCONum = @CONum, POCONumSeq = @SeqNum
					WHERE KeyID = @PMOLKeyID					
				END		
		

		--------------------------
		-- UPDATE TABLE SUCCESS --
		--------------------------
		COMMIT TRANSACTION
		END TRY
		
		---------------------------------
		-- UPDATE TABLE ERROR HANDLING --
		---------------------------------
		BEGIN CATCH
			SET @rcode = 1
			SET @msg = @msg + @Type + ' Change Order: ' + CAST(@CONum AS VARCHAR(3)) 
							+ ' Seq: ' + CAST(@SeqNum AS VARCHAR(5)) + CHAR(13) + CHAR(10)
			ROLLBACK TRANSACTION
		END CATCH
		
		--Clear Variables Before Next Insert
		SET @Notes = NULL
		
	END -- @PCOKeyIDs LOOP


	
vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSubPOCOAssignPCOList] TO [public]
GO
