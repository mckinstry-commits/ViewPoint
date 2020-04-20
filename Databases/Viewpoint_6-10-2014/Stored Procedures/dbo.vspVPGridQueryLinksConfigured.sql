SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE  procedure [dbo].[vspVPGridQueryLinksConfigured]

/******************************************************
* CREATED BY:  DK TK-13346 3/26/2012
* Modification: HH TK-15181 5/24/2012 added LinkConfigured = 'N' for no configured links
*				
* Usage:	Update the VPGridQueryLinks.LinksConfigured Flagged from the 
*			VPGridyQueryLinkParameters form. 
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
*	0 = success, 1 = failure,
*
* 
*******************************************************/

@QueryName VARCHAR(50), @RelatedQueryName VARCHAR(50), @msg VARCHAR(100) OUTPUT, @ReturnCode INT OUTPUT

AS 
BEGIN
	SET NOCOUNT ON
	SET @msg = '' 
	
	DECLARE @UnconfiguredParameterCount INT; 
	
	-- Check for NULLS and Empty Strings on the parameters 
	IF @QueryName IS NULL OR @QueryName = '' 
	BEGIN
		SET @msg = 'Query Name is invalid.'
		SET @ReturnCode = 1
		RETURN @ReturnCode
	END 
	
	IF @RelatedQueryName IS NULL OR @RelatedQueryName = '' 
	BEGIN 
		SET @msg = 'Related Query Name is invalid.' 
		SET @ReturnCode = 1
		RETURN @ReturnCode
	END 
	
	-- Determine if the parameters for the specified Query and Related Query combination are configured
	SET @UnconfiguredParameterCount = (	SELECT		COUNT(*) 
										FROM		VPGridQueryLinkParameters 
										WHERE		QueryName			= @QueryName
												AND RelatedQueryName	= @RelatedQueryName
												AND MatchingColumn		IS NULL 
												AND UseDefault = 'N')
						
	-- Update the LinksConfigured Flag if the parameters are all configured		
	IF @UnconfiguredParameterCount <> 0 
	BEGIN
		
		UPDATE	vVPGridQueryLinks SET 
				vVPGridQueryLinks.LinksConfigured	= 'N'
		FROM	vVPGridQueryLinks
		WHERE	vVPGridQueryLinks.QueryName			= @QueryName
			AND vVPGridQueryLinks.RelatedQueryName	= @RelatedQueryName
			AND vVPGridQueryLinks.IsStandard		= 'Y'
			
		UPDATE vVPGridQueryLinksc SET 
				vVPGridQueryLinksc.LinksConfigured	= 'N'
		FROM	vVPGridQueryLinksc
		WHERE	vVPGridQueryLinksc.QueryName		= @QueryName
			AND vVPGridQueryLinksc.RelatedQueryName = @RelatedQueryName
			AND vVPGridQueryLinksc.IsStandard		= 'N'
	
		SET @msg = 'There are still uncofigured parameters for this link.'
		SET @ReturnCode = 1
		RETURN @ReturnCode
	END 
	
	IF @UnconfiguredParameterCount = 0 
	BEGIN 
		UPDATE	vVPGridQueryLinks SET 
				vVPGridQueryLinks.LinksConfigured	= 'Y'
		FROM	vVPGridQueryLinks
		WHERE	vVPGridQueryLinks.QueryName			= @QueryName
			AND vVPGridQueryLinks.RelatedQueryName	= @RelatedQueryName
			AND vVPGridQueryLinks.IsStandard		= 'Y'
			
		UPDATE vVPGridQueryLinksc SET 
				vVPGridQueryLinksc.LinksConfigured	= 'Y'
		FROM	vVPGridQueryLinksc
		WHERE	vVPGridQueryLinksc.QueryName		= @QueryName
			AND vVPGridQueryLinksc.RelatedQueryName = @RelatedQueryName
			AND vVPGridQueryLinksc.IsStandard		= 'N'
	END 
	
	SET @msg = 'The Query Link parameters have been configured.'
	SET @ReturnCode = 0
	RETURN @ReturnCode
END 
GO
GRANT EXECUTE ON  [dbo].[vspVPGridQueryLinksConfigured] TO [public]
GO
