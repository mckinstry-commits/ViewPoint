SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  procedure [dbo].[vspVPSyncGridQueryLinksParameters]
/******************************************************
* CREATED BY:  HH TK-13346 5/24/2012
* MODIFIED BY: 
*			
*				
* Usage:	Synchronize VPGridQueryLinkParameters based on entry in 
*			VPGridQueryParameters
*
*
* Input params:
*
*	@QueryName - VPGridQuery's name / key
*	@ParameterName - ParameterName
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

@QueryName VARCHAR(50), @ParameterName VARCHAR(50), @msg VARCHAR(100) OUTPUT, @ReturnCode INT OUTPUT  	
   	
AS
BEGIN TRY
    DECLARE @CursorQueryName varchar(50)

	-- Loop through VPGridQueryLinkParameters 
	-- and insert new @Parameter entry and set the LinksConfigured to 'N'
	DECLARE CursorQueries CURSOR FAST_FORWARD FOR 
		SELECT DISTINCT QueryName 
		FROM VPGridQueryLinks
		WHERE  RelatedQueryName = @QueryName; 

	OPEN CursorQueries 
	FETCH NEXT FROM CursorQueries INTO @CursorQueryName 
	WHILE @@FETCH_STATUS = 0 
	  BEGIN 
		  	INSERT INTO VPGridQueryLinkParameters (QueryName, RelatedQueryName, ParameterName, MatchingColumn, UseDefault)
			VALUES (@CursorQueryName, @QueryName, @ParameterName, NULL, 'N')

			UPDATE VPGridQueryLinks 
			SET LinksConfigured = 'N' 
			WHERE QueryName = @CursorQueryName
					AND RelatedQueryName = @QueryName;

		  FETCH NEXT FROM CursorQueries INTO @CursorQueryName 
	  END 
	CLOSE CursorQueries 
	DEALLOCATE CursorQueries 

	SELECT	@msg = 'vspVPSyncGridQueryLinksParameters succeded.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'vspVPSyncGridQueryLinksParameters failed.',@ReturnCode = -1
	RETURN @ReturnCode
END CATCH;
GO
GRANT EXECUTE ON  [dbo].[vspVPSyncGridQueryLinksParameters] TO [public]
GO
