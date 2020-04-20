SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspAPReviewerCustomFields]
   /***************************************************
   *    Created:	MV 05/03/11 - 143194 - update custom field values to bAPUI
   *	Modified	MV 05/17/11 - D-01852 - if UD field is cleared update as 'NULL'			
   *
   *    Purpose: Update APUI custom fields from APUnappInvRev Header
   *					
   *
   *    Input:
   *        @apco
   *        @uimth
   *        @uiseq
   *        @DDSeq
   *        @Value
   *
   *    output:
   *            
   ****************************************************/
   (@APCo INT, @UIMth bMonth, @UISeq INT ,@DDSeq INT, @Value VARCHAR(MAX), 
    @Msg VARCHAR(255) OUTPUT)
   
	AS
	BEGIN TRY	
	DECLARE @ColumnName VARCHAR(100), @DataType VARCHAR(50), @InputType TINYINT,
		@Precision TINYINT, @InputLength INT, @UpdateString VARCHAR(MAX),
		@ValueToUpdate VARCHAR(MAX), @RCode int

	SELECT @RCode = 0
	
	IF ISNULL(@APCo,'') = ''
	BEGIN
		SELECT @Msg = 'Missing APCo.', @RCode=1
		RETURN @RCode
	END
	
	IF ISNULL(@UIMth,'') = ''
	BEGIN
		SELECT @Msg = 'Missing UIMth.', @RCode=1
		RETURN @RCode
	END
	
	IF ISNULL(@UISeq,'') = ''
	BEGIN
		SELECT @Msg = 'Missing UISeq.', @RCode=1
		RETURN @RCode
	END
	
	IF ISNULL(@DDSeq,'') = ''
	BEGIN
		SELECT @Msg = 'Missing DDSeq.', @RCode=1
		RETURN @RCode
	END
	
		
	-- Get DDFI custom field information 
	SELECT @ColumnName=ColumnName,@DataType=Datatype,@InputType=InputType,@Precision=Prec
	FROM vDDFIc 
	WHERE Form = 'APUnappInvRev'
	AND Seq = @DDSeq
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @Msg = 'Could not find custom field to update.', @RCode=1
		RETURN @RCode
	END
	
	IF ISNULL(@DataType,'') <> ''
	BEGIN
		SELECT @InputType=InputType,@InputLength=InputLength,@Precision=Prec
		FROM dbo.DDDT
		WHERE Datatype = @DataType  
	END		
	
	IF @Value = ''
	BEGIN
		SELECT @Value = NULL
	END
	ELSE
	BEGIN
		SELECT @Value = 
			CASE @InputType
					 WHEN 0 THEN '''' + RTRIM(@Value) + '''' -- String
					 WHEN 2 THEN '''' + RTRIM(@Value) + '''' -- Date
					 WHEN 3 THEN '''' + RTRIM(@Value) + '''' -- Month
					 WHEN 4 THEN '''' + RTRIM(@Value) + '''' -- Time
 					 WHEN 5 THEN '''' + RTRIM(@Value) + '''' -- Multipart
					 ELSE RTRIM(@Value)
			END
	END

	-- Update bAPUI
	IF @Value IS NOT NULL
	BEGIN
		SELECT @UpdateString = 'UPDATE dbo.APUI' 
			+ ' SET ' + RTRIM(@ColumnName) + ' = ' + RTRIM(@Value) 
			+ ' WHERE APCo = ' + CONVERT(VARCHAR(3),@APCo)
			+ ' AND UIMth = ''' + CONVERT(VARCHAR(20),@UIMth) 
			+ ''' AND UISeq = ' + CONVERT(VARCHAR(20),@UISeq)
	END
	ELSE
	BEGIN
		SELECT @UpdateString = 'UPDATE dbo.APUI' 
			+ ' SET ' + RTRIM(@ColumnName) + ' = NULL'  
			+ ' WHERE APCo = ' + CONVERT(VARCHAR(3),@APCo)
			+ ' AND UIMth = ''' + CONVERT(VARCHAR(20),@UIMth) 
			+ ''' AND UISeq = ' + CONVERT(VARCHAR(20),@UISeq)
	END

	EXEC (@UpdateString)
	END TRY
	BEGIN CATCH
		SELECT @Msg = ERROR_MESSAGE(), @RCode = 1
		RETURN @RCode
	END CATCH

RETURN @RCode
	
	
				 
---- get DataType info
	--IF ISNULL(@DataType,'') <> ''
	--BEGIN
	--	SELECT @InputType=InputType,@InputLength=InputLength,@Precision=Prec
	--	FROM dbo.DDDT
	--	WHERE Datatype = @DataType  
	--END		
			--+ CASE @InputType
			--		 WHEN 0 THEN RTRIM(@Value)
			--		 WHEN 2 THEN RTRIM(@Value)
			--		 WHEN 3 THEN RTRIM(@Value)
			--		 WHEN 4 THEN RTRIM(@Value)
			--		 WHEN 5 THEN RTRIM(@Value)
			--		 WHEN 1 THEN
			--			CASE @Precision
			--				WHEN 0 THEN CONVERT(TINYINT,RTRIM(@Value))
			--				WHEN 1 THEN CONVERT(SMALLINT,RTRIM(@Value))
			--				WHEN 2 THEN CONVERT(INT,RTRIM(@Value))
			--				WHEN 3 THEN CONVERT(TINYINT,RTRIM(@Value))
			--				WHEN 4 THEN CONVERT(BIGINT,RTRIM(@Value))
			--			END
			--		WHEN 6 THEN
			--			CASE @Precision
			--				WHEN 0 THEN CONVERT(TINYINT,RTRIM(@Value))
			--				WHEN 1 THEN CONVERT(SMALLINT,RTRIM(@Value))
			--				WHEN 2 THEN CONVERT(INT,RTRIM(@Value))
			--				WHEN 3 THEN CONVERT(TINYINT,RTRIM(@Value))
			--				WHEN 4 THEN CONVERT(BIGINT,RTRIM(@Value))
			--			END
			--	END
				








   
    
   




GO
GRANT EXECUTE ON  [dbo].[vspAPReviewerCustomFields] TO [public]
GO
