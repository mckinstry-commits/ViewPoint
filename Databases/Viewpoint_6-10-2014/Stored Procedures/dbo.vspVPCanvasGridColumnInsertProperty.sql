SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************************
* Author:		ScottP
* Create date:  04/02/2013
* Modified Date: 
*
* Description:	Insert specified Property records for a Canvas Grid Column
*				that don't already exist
*
*	Inputs: @QueryName - Name of Query
*			@FieldName - Name of Field Property record to Insert
*
*	Outputs:
*	
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPCanvasGridColumnInsertProperty]
	@QueryName varchar(128), @FieldName varchar(128), @IsVisible bYN, @Position int, @FilterValue varchar(128) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	INSERT INTO dbo.vVPCanvasGridColumns
			( GridConfigurationId,
			  Name ,
			  IsVisible ,
			  Position ,
			  FilterValue
			)
	SELECT KeyID, @FieldName, @IsVisible, @Position, @FilterValue FROM dbo.vVPCanvasGridSettings 
		WHERE QueryName = @QueryName and 
		KeyID not in
			(SELECT GridConfigurationId FROM dbo.vVPCanvasGridColumns WHERE Name = @FieldName)
END


GO
GRANT EXECUTE ON  [dbo].[vspVPCanvasGridColumnInsertProperty] TO [public]
GO
