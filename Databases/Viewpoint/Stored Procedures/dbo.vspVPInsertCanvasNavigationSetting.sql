SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPInsertCanvasNavigationSetting]  
/***********************************************************
* CREATED BY: HH/DK 4/6/2012 TK-13724 
* MODIFIED By : HH 6/11/2012 TK-15609 removed step logic and let it 
*							 handle by the application by passing in a @Step
*							 and added routine for UserDefaultDrillThrough routine
*				
*		
* Usage:	Used by the VP Queries drill through routine to store
*			the navigation path
*	
* 
* Input params:		@PartId INT,
*					@GridConfigurationID INT
*	
* Output params:
*	
* 
*****************************************************/
@PartId INT,
@GridConfigurationID INT,
@ParentGridConfigurationID INT = null,
@Step INT = 0

AS
BEGIN
	
	--Reset UserDefaultDrillThrough 
	UPDATE VPCanvasNavigationSettings
	SET UserDefaultDrillThrough = 'N'
	WHERE PartId = @PartId 
		AND ParentGridConfigurationID = @ParentGridConfigurationID
		AND Step = @Step
	
	IF NOT EXISTS (SELECT 1 FROM VPCanvasNavigationSettings 
					WHERE PartId = @PartId AND GridConfigurationID = @GridConfigurationID)
		BEGIN
			INSERT INTO VPCanvasNavigationSettings (PartId, GridConfigurationID, Step, ParentGridConfigurationID, UserDefaultDrillThrough)
			VALUES (@PartId, @GridConfigurationID, @Step, @ParentGridConfigurationID, 'Y');	
		END
	ELSE
		BEGIN
			UPDATE VPCanvasNavigationSettings
			SET UserDefaultDrillThrough = 'Y'
			WHERE PartId = @PartId 
				AND GridConfigurationID = @GridConfigurationID
		END
END
GO
GRANT EXECUTE ON  [dbo].[vspVPInsertCanvasNavigationSetting] TO [public]
GO
