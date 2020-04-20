SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vcspPOUniqueVal]
/***********************************************************

***********************************************************/ 
(
	@PO				VARCHAR(30),
	@ReturnMessage	VARCHAR(100) OUTPUT
)

AS 
SET NOCOUNT ON

DECLARE 
	@rcode	INT
	
SELECT 
	@rcode			= 0

/**Check pending purchase order table**/
IF EXISTS(SELECT 1 FROM dbo.POUnique WHERE PO = @PO)
	BEGIN
		SET @ReturnMessage = 'PO ' + @PO + ' already exists.'
		RETURN 1 
	END

bspexit:
	return @rcode


GO
