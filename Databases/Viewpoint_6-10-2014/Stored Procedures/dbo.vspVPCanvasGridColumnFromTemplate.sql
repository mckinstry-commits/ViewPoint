SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************************
* Author:		ScottP
* Create date:  04/02/2013
* Modified Date: 
*
* Description:	Insert a specified Canvas Grid Column into a Grid
*				When a new WC is created, there will be a record
*				created for the Grid Column
*
*	Inputs: @QueryName - Name of Query
*			@FieldName - Name of Field to Insert
*
*	Outputs:
*	
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPCanvasGridColumnFromTemplate]
	@QueryName varchar(128), @FieldName varchar(128), @IsVisible bYN, @Position int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @GridConfigurationId int
	
	SELECT @GridConfigurationId = KeyID FROM dbo.vVPCanvasGridSettingsTemplate WHERE QueryName = @QueryName
	IF (@GridConfigurationId is not null)
	BEGIN
		IF not exists(SELECT 1 FROM dbo.vVPCanvasGridColumnsTemplate WHERE GridConfigurationId = @GridConfigurationId)
		BEGIN
			INSERT INTO dbo.vVPCanvasGridColumnsTemplate
			VALUES (@GridConfigurationId, @FieldName, @IsVisible, @Position)	
		END
	END
END


GO
GRANT EXECUTE ON  [dbo].[vspVPCanvasGridColumnFromTemplate] TO [public]
GO
