SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspVPGetWorkCenterLibraries]
  /************************************************************************
  * CREATED: 	HH 03/21/2013 		TFS 43740
  * MODIFIED:   
  *
  * Purpose of Stored Procedure:	Return all items in VPWorkCenterUserLibrary
  *									that user has access to (owner and public from other)  
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
(@Owner bVPUserName = null, @Type int = 0)


as
set nocount on

DECLARE @rcode int
SET @rcode = 0

BEGIN TRY

	IF @Type = 0
	BEGIN

		SELECT LibraryName
				,(SELECT TOP 1 CAST(v2.KeyID AS VARCHAR(5)) + '-' + v2.[Description] 
					FROM WorkCenterInfo.nodes('/root/VPCanvasSettings/row')e(x) 
					INNER JOIN VPCanvasSettingsTemplate v1 on v1.TemplateName = x.value('TemplateName[1]', 'varchar(20)') 
					INNER JOIN VPCanvasTemplateGroup v2 ON v2.KeyID = v1.GroupID) AS [Type]
				,(SELECT x.value('TemplateName[1]', 'varchar(20)') FROM WorkCenterInfo.nodes('/root/VPCanvasSettings/row')e(x)) AS Template
				,CAST(DateModified AS VARCHAR(50)) AS DateModified
				,CASE
					WHEN PublicShare = 'Y' THEN 'Public'
					ELSE 'None'
				END AS PublicShare
				,(SELECT ISNULL(x.value('RefreshInterval[1]', 'int'), 1) FROM WorkCenterInfo.nodes('/root/VPCanvasSettings/row')e(x)) AS RefreshInterval
		FROM VPWorkCenterUserLibrary
		WHERE [Owner] = @Owner
		ORDER BY UPPER(LibraryName), DateModified 

	END
	ELSE
	BEGIN

		SELECT LibraryName
				,(SELECT TOP 1 CAST(v2.KeyID AS VARCHAR(5)) + '-' + v2.[Description] 
					FROM WorkCenterInfo.nodes('/root/VPCanvasSettings/row')e(x) 
					INNER JOIN VPCanvasSettingsTemplate v1 on v1.TemplateName = x.value('TemplateName[1]', 'varchar(20)') 
					INNER JOIN VPCanvasTemplateGroup v2 ON v2.KeyID = v1.GroupID) AS [Type]
				,(SELECT x.value('TemplateName[1]', 'varchar(20)') FROM WorkCenterInfo.nodes('/root/VPCanvasSettings/row')e(x)) AS Template
				,CAST(DateModified AS VARCHAR(50)) AS DateModified
				,[Owner]
				,(SELECT ISNULL(x.value('RefreshInterval[1]', 'int'), 60)/60 FROM WorkCenterInfo.nodes('/root/VPCanvasSettings/row')e(x)) AS RefreshIntervalInMinutes
		FROM VPWorkCenterUserLibrary
		WHERE [Owner] = @Owner OR PublicShare = 'Y'
		ORDER BY UPPER(LibraryName), DateModified 

	END
		
END TRY
BEGIN CATCH
    
     SET @rcode = 1
     
END CATCH

bspexit:
RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspVPGetWorkCenterLibraries] TO [public]
GO
