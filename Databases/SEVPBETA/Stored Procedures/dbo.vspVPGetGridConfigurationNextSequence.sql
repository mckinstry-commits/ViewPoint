SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  TK-14882 5/10/2012
* Modified Date: 
*				
* Description:	Get the next Sequence number base on 
*				QueryName and PartId in VPCanvasGridSettings
*	Inputs:
*	
*
*	Outputs:
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPGetGridConfigurationNextSequence]
	-- Add the parameters for the stored procedure here
	@PartId INT,
	@QueryName VARCHAR(128) , 
    @NextSequence INT OUTPUT
	  
AS
BEGIN
		
	SELECT @NextSequence = MAX(Seq) + 1
	FROM VPCanvasGridSettings 
	WHERE PartId = @PartId 
			AND QueryName = @QueryName;
	
	IF @NextSequence IS NULL
	BEGIN 
		SELECT @NextSequence = 0;
	END
	
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetGridConfigurationNextSequence] TO [public]
GO
