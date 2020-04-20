SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vspVPUpdateGridConfigurationCustomName]
/*************************************
*	Created by:		HH 5/11/2012 - TK-14882
*	Modified by:	
* 
* 
**************************************/
	@QueryName	varchar(128),
	@Seq		INT,
	@PartId		INT,
	@CustomName varchar(128)
	
AS
BEGIN
	
	UPDATE VPCanvasGridSettings 
	SET CustomName = @CustomName 
	WHERE QueryName = @QueryName
		AND Seq = @Seq
		AND PartId = @PartId
	
END


GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateGridConfigurationCustomName] TO [public]
GO
