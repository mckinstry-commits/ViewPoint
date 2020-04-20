SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		CJG
* Create date:  4/11/2011
* Description:	Mirrors vspVPSaveGridColumn for the admin
* Modification : HH 10/29/2012 TK-18922 dummy parameter @FilterValue
*
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridColumnAdmin]
	-- Add the parameters for the stored procedure here
	@ConfigurationId INT,
	@Name VARCHAR(128) ,
    @IsVisible bYN,
    @Position INT,
    --dummy parameters
    @FilterValue VARCHAR(128) = ''
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS (	SELECT 1
				FROM VPDisplayGridColumns
				WHERE GridConfigurationId = @ConfigurationId AND Name = @Name)
		BEGIN
			UPDATE VPDisplayGridColumns
			SET IsVisible = @IsVisible, Position = @Position
			WHERE GridConfigurationId = @ConfigurationId AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPDisplayGridColumns
			        ( GridConfigurationId ,
			          Name ,
			          IsVisible,
			          Position 
			        )
			VALUES  ( 
		 			  @ConfigurationId ,
					  @Name ,
					  @IsVisible,
					  @Position
			        );			
		END
END



GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridColumnAdmin] TO [public]
GO
