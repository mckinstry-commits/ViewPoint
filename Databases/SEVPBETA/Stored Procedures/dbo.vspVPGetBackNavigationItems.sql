SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetBackNavigationItems]  
/***********************************************************
* CREATED BY: HH/DK 4/6/2012 TK-13724 
* Modified:	HH 6/1/2012	 TK-15193 added QueryTitle
*			HH 6/11/2012 TK-15609 added PartId and parent child logic
*		
* Usage:	Get the BackNavigation items for VP Queries
*			drill through routine
*	
* 
* Input params:		@PartId INT
*	
* Output params:
*	
* 
*****************************************************/
@PartId INT,
@GridConfigurationID INT,
@Step INT

AS
BEGIN

	;WITH ParentNavigationItems
	AS
	(
		SELECT parent.GridConfigurationID
				,parent.ParentGridConfigurationID
				,parent.PartId
				,parent.Step
				,parent.KeyID
		FROM VPCanvasNavigationSettings parent
		WHERE parent.GridConfigurationID = @GridConfigurationID

		UNION ALL

		SELECT child.GridConfigurationID
				,child.ParentGridConfigurationID
				,child.PartId
				,child.Step
				,child.KeyID
		FROM VPCanvasNavigationSettings child
		INNER JOIN ParentNavigationItems parent 
			ON parent.ParentGridConfigurationID = child.GridConfigurationID
	)
	SELECT n.PartId
			,n.GridConfigurationID
			,n.Step
			,s.QueryName
			,s.Seq 
			,q.QueryTitle
	FROM ParentNavigationItems n
	INNER JOIN VPCanvasGridSettings s 
			ON n.GridConfigurationID = s.KeyID
				AND n.PartId = @PartId	
	INNER JOIN VPGridQueries q
			ON s.QueryName = q.QueryName
	WHERE n.Step < @Step
	ORDER BY n.Step DESC
	
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetBackNavigationItems] TO [public]
GO
