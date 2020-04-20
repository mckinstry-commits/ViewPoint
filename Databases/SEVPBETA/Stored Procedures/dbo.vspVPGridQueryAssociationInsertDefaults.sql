SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  procedure [dbo].[vspVPGridQueryAssociationInsertDefaults]
/******************************************************
* CREATED BY:  HH TK-13339 3/26/2012
* MODIFIED By: 
*
* Usage:	Insert Default Templates into VPGridQueryAssociation 
*			for new VPGridQueries entries
*	
*
* Input params:
*
*	@QueryName - VPGridQuery's name / key
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

@QueryName varchar(max), @msg varchar(100) OUTPUT   	
   	
AS
BEGIN
	SET NOCOUNT ON
   	
   	IF @QueryName IS NULL
	BEGIN
		SET @msg = 'Missing Query Name.'
		RETURN 1
	END
	
	DECLARE @TemplateName varchar(20)
   	DECLARE @Active varchar(1)
   	DECLARE @IsStandard bYN
   	
   	SET @Active = 'Y'
   	
	SELECT	@IsStandard = IsStandard
	FROM  dbo.VPGridQueries
	WHERE QueryName = @QueryName
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = @QueryName + ' does not exists in VPGridQueries.'
		RETURN 1
    END
	
	-- Loop through VPCanvasSettingsTemplate that have grid parts 
	-- and insert those into VPGridQueryAssociation			
	DECLARE CursorTemplateName CURSOR FAST_FORWARD FOR 
		SELECT DISTINCT c.TemplateName 
		FROM VPCanvasSettingsTemplate c 
			INNER JOIN VPPartSettingsTemplate p 
			ON c.TemplateName = p.TemplateName 
		WHERE  p.PartName = 'VCS.Viewpoint.VCSCanvasParts.VCSCanvasGrid' 

	OPEN CursorTemplateName 
	FETCH NEXT FROM CursorTemplateName INTO @TemplateName 
	WHILE @@FETCH_STATUS = 0 
	  BEGIN 
		  	INSERT INTO VPGridQueryAssociation (QueryName, TemplateName, Active, IsStandard)
			VALUES (@QueryName, @TemplateName, @Active, @IsStandard)
			
		  FETCH NEXT FROM CursorTemplateName INTO @TemplateName 
	  END 
	CLOSE CursorTemplateName 
	DEALLOCATE CursorTemplateName 

	SET @msg = 'Default VPGridQueryAssociation inserted.'
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGridQueryAssociationInsertDefaults] TO [public]
GO
