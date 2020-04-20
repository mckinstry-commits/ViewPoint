SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  procedure [dbo].[vspVPGridQueryLinksParametersDefaults]
/******************************************************
* CREATED BY:  HH TK-13346 3/26/2012
* MODIFIED BY: DK TK-13344 04/26/2012
*				- verify param defaults not already configured
*				- verify param defaults configured at VPGridQueryParams
* MODIFIED BY: DK TK-
*			   GPT TK-15320 - use the view when inserting VPGridQueryLinkParameters
* Usage:	Insert Default Parameters into VPGridQueryLinkParameters 
*			for new VPGridQueryLinks entries
*
*
* Input params:
*
*	@QueryName - VPGridQuery's name / key
*	@RelatedQueryName - Related VPGridQuery's name / key
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure, -1 = Params already Configured
*
* 
*******************************************************/

@QueryName VARCHAR(50), @RelatedQueryName VARCHAR(50), @msg VARCHAR(100) OUTPUT, @ReturnCode INT OUTPUT  	
   	
AS
BEGIN

	DECLARE @LocalRowCount BIGINT;
	SET @LocalRowCount = 0 
	
	-- Confirm we have Query Names
   	IF @QueryName IS NULL OR @QueryName = ''
	BEGIN
		SELECT	@msg = 'Missing Query Name.', 
				@ReturnCode = 1
		RETURN @ReturnCode
	END
	
	IF @RelatedQueryName IS NULL OR @RelatedQueryName = ''
	BEGIN
		SELECT	@msg = 'Missing Related Query Name.', 
				@ReturnCode = 1
		RETURN @ReturnCode 
	END
	
	-- Determine if there are already parameters in place for the 
	-- requested @QueryName / @RelatedQueryName combination
	SELECT		*
	FROM		VPGridQueryLinkParameters 
	WHERE		QueryName			= @QueryName 
			AND	RelatedQueryName	= @RelatedQueryName

	-- Keep track of the number of rows from our first selection 
	SET @LocalRowCount = @@RowCount 

	-- If params exist, exit with a notice that they exist
	IF @LocalRowCount <> 0 
	BEGIN

		SELECT	@msg =	'Parameters for Query: '	+ @QueryName +
					' and Related Query: '		+ @RelatedQueryName + 
					' already loaded.',
				@ReturnCode = -1
		RETURN @ReturnCode

	END 
	
	-- If params don't exist, prep a dataset and verify 
	IF @LocalRowCount = 0 
	BEGIN 
		CREATE TABLE	#ParamsToLoad ( QueryName		VARCHAR(50),
								RelatedQueryName	VARCHAR(50),
								ParameterName		VARCHAR(50),
								MatchingColumn		VARCHAR(50),
								UseDefault			VARCHAR(1),
								KeyID				BIGINT )
								

		
		INSERT INTO		#ParamsToLoad ( QueryName,		
							  			RelatedQueryName,
							  			ParameterName,	
							  			MatchingColumn,	
							  			UseDefault,		
							  			KeyID ) 			


		SELECT			@QueryName, 
						@RelatedQueryName, 
						QP.ParameterName, 
						NULL, 
						'N',
						QP.KeyID
		FROM			VPGridQueryParameters QP

		WHERE			QP.QueryName = @RelatedQueryName
		
		ORDER BY		Seq

		-- get a new recordset in memory and keep track of the number of rows
		SELECT * FROM #ParamsToLoad
		SET @LocalRowCount = @@RowCount 
		
		IF @LocalRowCount = 0 
		BEGIN
			
			SELECT	@msg = 'There are no Parameters for ' + @RelatedQueryName,
					@ReturnCode = 1
			
			DROP TABLE	#ParamsToLoad
			RETURN @ReturnCode
			
			
		END 
		
		IF @LocalRowCount <> 0 
		BEGIN
			
			INSERT INTO VPGridQueryLinkParameters (	QueryName,		
							  							RelatedQueryName,
							  							ParameterName,	
							  							MatchingColumn,	
							  							UseDefault) 
			SELECT	QueryName,		
					RelatedQueryName,
					ParameterName,	
					MatchingColumn,	
					UseDefault
					
			FROM	#ParamsToLoad 
		END 
		
	END 


	DROP TABLE	#ParamsToLoad
	
	SELECT	@msg = 'Default VPGridQueryLinkParameters inserted.',
			@ReturnCode = 0
	RETURN @ReturnCode
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGridQueryLinksParametersDefaults] TO [public]
GO
