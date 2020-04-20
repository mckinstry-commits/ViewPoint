SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPDeleteCanvasNavigationSetting]  
/***********************************************************
* CREATED BY: HH/DK 4/6/2012 TK-13724 
* MODIFIED By : 
*				
*		
* Usage:	Used by the VP Queries drill through routine to delete
*			the navigation path
*	
* 
* Input params:		@PartId INT,
*					@Step INT
*	
* Output params:
*	
* 
*****************************************************/
@PartId INT,
@Step INT

AS
BEGIN
	
	DELETE VPCanvasNavigationSettings
	FROM VPCanvasNavigationSettings
	WHERE	PartId = @PartId
			AND Step >= @Step;
			
			
	IF @Step = 0
	BEGIN
		DELETE VPCanvasGridSettings 
		FROM VPCanvasGridSettings
		WHERE PartId = @PartId
				AND IsDrillThrough = 'Y'
	END
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteCanvasNavigationSetting] TO [public]
GO
