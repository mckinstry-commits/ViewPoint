SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPGetToolbarActionsOld]
/***********************************************************************
*  Created by: 	CC 11-17-10
* 
*  Altered by: 	
*              
* 
* Used by My Viewpoint work center to get available custom actions
***********************************************************************/
	@RecordType VARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT *
	FROM DDCustomActions
	INNER JOIN DDCustomActionRecordTypes ON DDCustomActions.ActionId = DDCustomActionRecordTypes.ActionId
	WHERE RecordTypeName = @RecordType;
	
	SELECT * 
	FROM DDCustomActionParameters
	INNER JOIN DDCustomActionRecordTypes ON DDCustomActionParameters.ActionId = DDCustomActionRecordTypes.ActionId
	WHERE RecordTypeName = @RecordType;
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGetToolbarActionsOld] TO [public]
GO
