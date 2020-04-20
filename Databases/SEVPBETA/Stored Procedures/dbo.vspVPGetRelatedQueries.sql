SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************
* Created:	HH 5/14/2012 TK-14882 Get RelatedQueries 
* Modified:	HH 6/1/2012	TK-15193 added QueryTitle
*			HH 6/11/2012 TK-15609 added GridConfigurationID and UserDefaultDrillThrough
*
* Retrieves all Related Query informations based on the starting query
*	needed to load a related query.
*
* Input:
*	@QueryName
*	@Company INT
*
* Output:
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
   
CREATE PROCEDURE [dbo].[vspVPGetRelatedQueries]
    @QueryName VARCHAR(128), 
    @Company INT,
    @GridConfigurationID INT
    
AS 
    BEGIN
        SET NOCOUNT ON ;

		DECLARE @User bVPUserName
		SELECT @User = SUSER_SNAME()
		
		--Existing User GridConfigurations
		;WITH ExistingUserNavigations
		AS
		(
			SELECT * 
			FROM VPCanvasNavigationSettings
			WHERE ParentGridConfigurationID = @GridConfigurationID
		),
		ExistingUserGridSettings
		AS
		(
			SELECT VPCanvasGridSettings.*, 
					ExistingUserNavigations.UserDefaultDrillThrough
			FROM ExistingUserNavigations 
			INNER JOIN VPCanvasGridSettings 
				ON ExistingUserNavigations.GridConfigurationID = VPCanvasGridSettings.KeyID
		)
		
		SELECT	VPGridQueryLinks.*, 
				VPGridQueries.QueryTitle AS RelatedQueryTitle,
				ExistingUserGridSettings.KeyID AS GridConfigurationId,
				ExistingUserGridSettings.Seq,
				ExistingUserGridSettings.PartId,
				ExistingUserGridSettings.UserDefaultDrillThrough
		FROM VPGridQueryLinks 
		INNER JOIN dbo.vfVPGetQuerySecurity(@User, @Company) AS AvailableQueries 
			ON VPGridQueryLinks.RelatedQueryName = AvailableQueries.QueryName AND AvailableQueries.Access = 0
		INNER JOIN VPGridQueries 
			ON VPGridQueryLinks.RelatedQueryName = VPGridQueries.QueryName
		
		LEFT OUTER JOIN ExistingUserGridSettings
			ON ExistingUserGridSettings.QueryName = VPGridQueryLinks.RelatedQueryName
			
		WHERE VPGridQueryLinks.QueryName = @QueryName
				AND VPGridQueryLinks.LinksConfigured = 'Y'
		ORDER BY DefaultDrillThrough DESC, DisplaySeq
		
		SELECT * 
		FROM VPGridQueryLinkParameters
		INNER JOIN dbo.VPGridQueryLinks ON VPGridQueryLinks.QueryName = VPGridQueryLinkParameters.QueryName
										AND VPGridQueryLinks.RelatedQueryName = VPGridQueryLinkParameters.RelatedQueryName
		INNER JOIN dbo.vfVPGetQuerySecurity(@User, @Company) AS AvailableQueries 
			ON VPGridQueryLinkParameters.RelatedQueryName = AvailableQueries.QueryName AND AvailableQueries.Access = 0
		INNER JOIN VPGridQueryParameters ON VPGridQueryLinkParameters.RelatedQueryName = VPGridQueryParameters.QueryName
										AND VPGridQueryLinkParameters.ParameterName = VPGridQueryParameters.ParameterName
		WHERE VPGridQueryLinkParameters.QueryName = @QueryName
				AND VPGridQueryLinks.LinksConfigured = 'Y'

    END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetRelatedQueries] TO [public]
GO
