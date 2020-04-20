SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 10/12/2009 - ISSUE #129350
* Modified By: 
*
*
* USAGE:   Validate associated surcharges
*
*
* INPUT PARAMETERS
*	@MSTBKeyID		Parent Key ID of Surcharge Record(s)
*
* OUTPUT PARAMETERS
*	@msg            Error message
*   
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargesVal]
CREATE  PROC [dbo].[vspMSSurchargesVal]
 
(@MSTBKeyID bigint = NULL, 
	@msg varchar(255) = NULL output)
 

AS
SET NOCOUNT ON

	DECLARE	@rcode			int,
			@RowID			int,		 
			@SurchargeCode	smallint,	
			@SurchargeMatl	bMatl,
			@MatlGroup		bGroup,
			@RowCnt			int,
			@MaxRows		int,
			@RetCode		int

	
	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @MSTBKeyID IS NULL
		BEGIN
			SELECT @msg = 'Missing MS Parent KeyID', @rcode = 1
			GOTO vspexit
		END
		
		
	---------------------------------
	-- CREATE/LOAD SURCHARGE TABLE --
	---------------------------------
	-- CREATE TABLE --
	DECLARE @SurchargesTable TABLE
		(	
			RowID			int			IDENTITY(1,1),	
			SurchargeCode	smallint,					 
			SurchargeMatl	bMatl,
			MatlGroup		bGroup
		)
		 
	-- LOAD TABLE --
	INSERT INTO @SurchargesTable (SurchargeCode, SurchargeMatl, MatlGroup)
		SELECT	s.SurchargeCode, s.SurchargeMaterial, b.MatlGroup
		  FROM	MSSurcharges s WITH (NOLOCK)
		  JOIN  MSTB b WITH (NOLOCK) ON b.KeyID = s.MSTBKeyID
	     WHERE	MSTBKeyID = @MSTBKeyID
	 

	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
	SET @RowCnt = 1
	SELECT @MaxRows = COUNT(*) FROM @SurchargesTable


	-------------------------------
	-- LOOP THROUGH ALL REQUESTS --
	-------------------------------
	WHILE @RowCnt <= @MaxRows
		BEGIN
		
			SELECT	@SurchargeCode = SurchargeCode, @SurchargeMatl = SurchargeMatl, 
					@MatlGroup = MatlGroup
			  FROM  @SurchargesTable
		     WHERE	RowID = @RowCnt

		
			-- VERIFY VALID SURCHARGE CODE --
			IF NOT EXISTS (SELECT SurchargeCode FROM MSSurcharges WITH (NOLOCK) WHERE SurchargeCode = @SurchargeCode)
				BEGIN
					SET @rcode = 1
					SET @msg = 'Invalid Surcharge Code: ' + ISNULL(CAST(@SurchargeCode AS VARCHAR(10)), 'N/A')
					GOTO vspexit
				END
			
			-- VERIFY VALID SURCHARGE MATERIAL --
			IF NOT EXISTS (SELECT Material FROM HQMT WITH (NOLOCK) 
							WHERE MatlGroup = @MatlGroup AND Material = @SurchargeMatl) 
				BEGIN
					SET @rcode = 1
					SET @msg = 'Invalid Surcharge Material: ' + ISNULL(CAST(@SurchargeMatl AS VARCHAR(10)), 'N/A')
					GOTO vspexit
				END
				
				
			----------------------
			-- UPDATE ROW COUNT --
			----------------------
			SET @RowCnt = @RowCnt + 1

		END -- WHILE @RowCnt <= @MaxRows
		
	
-----------------
-- END ROUTINE --
-----------------
vspexit:
	IF @rcode <> 0 
		SET @msg = isnull(@msg,'')
		
	RETURN @rcode
		
		
		
		


		


GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargesVal] TO [public]
GO
