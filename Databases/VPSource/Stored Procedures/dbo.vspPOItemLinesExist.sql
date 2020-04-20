SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspPOItemLinesExist   Script Date: 10/15/08 9:33:09 AM ******/
CREATE  proc [dbo].[vspPOItemLinesExist]
/***********************************************************
* CREATED BY:	GF 08/09/2011	TK-07770 PO Item Distribution Work
* MODIFIED BY:
*
* USED BY:
* Used in PO Entry to check if PO Item Lines exist.
*
*
* USAGE:
* 
*
* INPUT PARAMETERS
* @POCo		PO Company	
* @PO		Purchase Order
* @POItem	PO Item
* 
* 
* OUTPUT PARAMETERS
* @ItemLinesExist	Returns 'N' if no lines exist for item or 'Y' if true
* @msg      
*	
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@POCo bCompany = NULL, @PO VARCHAR(30) = NULL, @POItem bItem = NULL,
 @ItemLinesExist CHAR(1) = 'N' OUTPUT, @ErrMsg VARCHAR(255) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode INT
  		
	
SET @rcode = 0
SET @ItemLinesExist = 'N'

---- check POItemLine table for lines > 1 for the PO/POitem
IF EXISTS(SELECT 1 FROM dbo.POItemLine WHERE POCo=@POCo
			AND PO=@PO AND POItem=@POItem AND POItemLine > 1)
	BEGIN
	SET @ItemLinesExist = 'Y'
	END
	

vspexit:	
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspPOItemLinesExist] TO [public]
GO
