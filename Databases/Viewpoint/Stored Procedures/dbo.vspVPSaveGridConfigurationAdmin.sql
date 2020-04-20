SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		CJG
* Create date:  04/11/2011
* Modified Date: 
* Description:	Mirrors vspVPSaveGridConfiguration for the Admin
* Modification : HH 10/29/2012 TK-18922 dummy parameters
*
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridConfigurationAdmin]
	-- Add the parameters for the stored procedure here
	@PartId INT,
	@QueryName VARCHAR(128) ,
    @GridLayout VARCHAR(MAX),
    @Sort VARCHAR(128),
    @MaximumNumberOfRows INT,
    @GridType INT,
    @ShowFilterBar bYN,
    @QueryId INT,
    @ShowConfiguration bYN,
    @ShowTotals bYN = 'N',
    -- dummy parameters
    @CustomName varchar(128) = '',
    @Seq INT = 0,
    @SaveLastQuery bYN = 'N',
    @IsDrillThrough bYN,
    @SelectedRow INT = 1,
    
    @ConfigurationId INT OUTPUT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF EXISTS (	SELECT 1 
				FROM VPDisplayGridSettings
				WHERE	DisplayID = @PartId AND QueryName = @QueryName)
		BEGIN
			UPDATE dbo.VPDisplayGridSettings
			SET QueryName = @QueryName,
				MaximumNumberOfRows = @MaximumNumberOfRows
			WHERE DisplayID = @PartId AND QueryName = @QueryName;
			
			SELECT @ConfigurationId = KeyID
			FROM VPDisplayGridSettings
			WHERE DisplayID = @PartId AND QueryName = @QueryName;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPDisplayGridSettings
			        ( DisplayID,
					  QueryName ,
			          MaximumNumberOfRows ,
			          GridType
			        )
			VALUES  ( @PartId ,
					  @QueryName ,			          
			          @MaximumNumberOfRows ,
			          @GridType
			        );
			SELECT @ConfigurationId = SCOPE_IDENTITY();
		END	
END

GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridConfigurationAdmin] TO [public]
GO
