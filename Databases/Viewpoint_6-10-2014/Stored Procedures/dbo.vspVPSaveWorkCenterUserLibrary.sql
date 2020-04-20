SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  3/14/2013 (PI day) -Mathematician: "Pi r squared" -Baker:" No! Pies are round, cakes are square!
* Description:	Saves the whole work center tables entries as xml into vVPWorkCenterUserLibrary
*
*	Inputs:
*	@LibraryName	The library name to save for
*	@Owner			The owner of the library
*	@PublicShare	The flag whether or not to share the library with other users
*
*	Outputs:
*	None
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveWorkCenterUserLibrary]
	-- Add the parameters for the stored procedure here
	@LibraryName VARCHAR(50) = NULL,
	@Owner VARCHAR(100) = NULL,
	@PublicShare bYN = 'N',
	@CanvasId INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @WorkCenterInfo xml
	SET @WorkCenterInfo = (
		SELECT 
			(SELECT * FROM VPCanvasSettings WHERE VPUserName = @Owner AND KeyID = @CanvasId FOR XML PATH, TYPE) AS 'VPCanvasSettings',
			(SELECT * FROM VPPartSettings WHERE CanvasId = @CanvasId FOR XML PATH, TYPE) AS 'VPPartSettings',
			(SELECT * FROM VPCanvasTreeItems WHERE CanvasId = @CanvasId FOR XML PATH, TYPE) AS 'VPCanvasTreeItems',
			(SELECT * FROM VPCanvasGridSettings WHERE PartId IN (SELECT KeyID FROM VPPartSettings WHERE CanvasId = @CanvasId ) FOR XML PATH, TYPE) AS 'VPCanvasGridSettings',
			(SELECT * FROM VPCanvasGridPartSettings WHERE PartId IN (SELECT KeyID FROM VPPartSettings WHERE CanvasId = @CanvasId ) FOR XML PATH, TYPE) AS 'VPCanvasGridPartSettings',
			(SELECT * FROM VPCanvasGridColumns WHERE GridConfigurationId IN (SELECT KeyID FROM VPCanvasGridSettings WHERE PartId IN (SELECT KeyID FROM VPPartSettings WHERE CanvasId = @CanvasId )) FOR XML PATH, TYPE) AS 'VPCanvasGridColumns',
			(SELECT * FROM VPCanvasGridGroupedColumns WHERE GridConfigurationId IN (SELECT KeyID FROM VPCanvasGridSettings WHERE PartId IN (SELECT KeyID FROM VPPartSettings WHERE CanvasId = @CanvasId )) FOR XML PATH, TYPE) AS 'VPCanvasGridGroupedColumns',
			(SELECT * FROM VPCanvasGridParameters WHERE GridConfigurationId IN (SELECT KeyID FROM VPCanvasGridSettings WHERE PartId in (SELECT KeyID FROM VPPartSettings WHERE CanvasId = @CanvasId )) FOR XML PATH, TYPE) AS 'VPCanvasGridParameters',
			(SELECT * FROM VPCanvasNavigationSettings WHERE PartId IN (SELECT KeyID FROM VPPartSettings WHERE CanvasId = @CanvasId ) FOR XML PATH, TYPE) AS 'VPCanvasNavigationSettings'
		FOR XML PATH(''), ROOT('root') 
	)
	
	--delete old entry
	IF EXISTS (SELECT * FROM VPWorkCenterUserLibrary WHERE LibraryName = @LibraryName AND [Owner] = @Owner)
		DELETE FROM VPWorkCenterUserLibrary WHERE LibraryName = @LibraryName AND [Owner] = @Owner

	INSERT INTO VPWorkCenterUserLibrary (LibraryName, [Owner], WorkCenterInfo, PublicShare)
	VALUES (@LibraryName, @Owner, @WorkCenterInfo, @PublicShare)

END

GO
GRANT EXECUTE ON  [dbo].[vspVPSaveWorkCenterUserLibrary] TO [public]
GO
