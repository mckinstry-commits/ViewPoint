SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  8/15/2010
* Modified Date: ChrisG 3/18/2011 TK-02696 - Added ShowConfiguration
*				HH 4/5/2012 TK-13724 - Added CustomName
*				HH 5/10/2012 TK-14882 - Added Seq
*				HH 6/5/2012 TK-15193 - Added SelectedRow 
* Description:	Saves grid settings for My Viewpoint
*
*	Inputs:
*	
*
*	Outputs:
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridConfiguration]
	-- Add the parameters for the stored procedure here
	@PartId INT,
	@QueryName VARCHAR(128) , 
	@CustomName VARCHAR(128),
    @GridLayout VARCHAR(MAX),
    @Sort VARCHAR(128),
    @MaximumNumberOfRows INT,
    @GridType INT,
    @ShowFilterBar bYN,
    @QueryId INT,
    @ShowConfiguration bYN,
    @ShowTotals bYN = 'N',
    @Seq INT = 1,
    @SaveLastQuery bYN = 'Y',
    @IsDrillThrough bYN = 'N',
    @SelectedRow INT = 0,
    @ConfigurationId INT OUTPUT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	IF @SaveLastQuery ='Y'
	BEGIN
		IF EXISTS ( SELECT 1
					FROM dbo.VPCanvasGridPartSettings
					WHERE PartId = @PartId)
			BEGIN
				UPDATE VPCanvasGridPartSettings
				SET LastQuery = @QueryName,
					Seq = @Seq
				WHERE PartId = @PartId;
			END
		ELSE
			BEGIN
				INSERT INTO dbo.VPCanvasGridPartSettings
						( PartId, LastQuery, Seq)
				VALUES  (@PartId, @QueryName, @Seq);
			END
	END
	
	IF EXISTS (	SELECT 1 
				FROM VPCanvasGridSettings
				WHERE	PartId = @PartId AND QueryName = @QueryName AND Seq = @Seq)
		BEGIN
			UPDATE dbo.VPCanvasGridSettings
			SET QueryName = @QueryName,
				CustomName = @CustomName,
				GridLayout = @GridLayout ,
				Sort = @Sort,
				MaximumNumberOfRows = @MaximumNumberOfRows,
				ShowFilterBar = @ShowFilterBar,
				QueryId = @QueryId,
				ShowConfiguration = @ShowConfiguration,
				ShowTotals = @ShowTotals,
				IsDrillThrough = @IsDrillThrough,
				SelectedRow = @SelectedRow
			WHERE PartId = @PartId AND QueryName = @QueryName AND Seq = @Seq;
			
			SELECT @ConfigurationId = KeyID
			FROM VPCanvasGridSettings
			WHERE PartId = @PartId AND QueryName = @QueryName AND Seq = @Seq;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridSettings
			        ( QueryName ,
			          Seq,
			          CustomName,
			          GridLayout ,
			          Sort ,
			          MaximumNumberOfRows ,
			          ShowFilterBar ,
			          PartId,
			          QueryId,
			          GridType,
			          ShowConfiguration,
			          ShowTotals,
			          IsDrillThrough,
			          SelectedRow
			        )
			VALUES  ( @QueryName ,
					  @Seq , 
			          @CustomName,
			          @GridLayout ,
			          @Sort ,
			          @MaximumNumberOfRows ,
			          @ShowFilterBar ,
			          @PartId,
			          @QueryId,
			          @GridType,
			          @ShowConfiguration,
			          @ShowTotals,
			          @IsDrillThrough,
			          @SelectedRow
			        );
			SELECT @ConfigurationId = SCOPE_IDENTITY();
		END	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridConfiguration] TO [public]
GO
