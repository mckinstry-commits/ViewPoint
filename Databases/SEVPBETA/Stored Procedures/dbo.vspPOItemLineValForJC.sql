SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.vspPOItemLineValForJC    ******/
CREATE  proc [dbo].[vspPOItemLineValForJC]
/***********************************************************
* CREATED BY:	GF 09/07/2011 TK-078225
* MODIFIED BY:
*
* USED BY
*   JC Cost Adjustments to validate PO Item Line
*
*
* USAGE:
* validates PO Item Line
*
* INPUT PARAMETERS
* POCo  PO Co to validate against 
* PO to validate
* PO Item to validate
* PO Item Line to validate
* 
* OUTPUT PARAMETERS
* @itemtype The Purchase orders Item Type
* @Msg      error message if error occurs otherwise Description of PO, Vendor, 
* Vendor group,Vendor Name,BackOrdered
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@POCo bCompany = 0, @PO VARCHAR(30) = NULL, @POItem bItem = NULL, 
 @POItemLine INT = NULL, @Msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @ItemType TINYINT, @RecvYN CHAR(1)
		
SET @rcode = 0
   
if @POCo is null
	BEGIN	
	SELECT @Msg = 'Missing PO Company!', @rcode = 1
	GOTO vspexit
	END

if @PO is null
	BEGIN	
	SELECT @Msg = 'Missing PO!', @rcode = 1
	GOTO vspexit
	END

if @POItem is null
	BEGIN
	SELECT @Msg = 'Missing PO Item!', @rcode = 1
	GOTO vspexit
	END

if @POItemLine is null
	BEGIN
	SELECT @Msg = 'Missing PO Item Line!', @rcode = 1
	GOTO vspexit
	END
   
   
---- get PO Item and line info
SELECT @ItemType = line.ItemType, @RecvYN = item.RecvYN
FROM dbo.POItemLine line
INNER JOIN dbo.POIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
where line.POCo = @POCo 
	AND line.PO = @PO
	AND line.POItem = @POItem
	AND line.POItemLine = @POItemLine
if @@rowcount = 0
   	BEGIN
   	SELECT @Msg = 'PO Item Line does not exist!', @rcode = 1
   	GOTO vspexit
   	END
   

---- Checks if Item Type = 6 SM Work Order
--IF @ItemType = 6
--	BEGIN
--	SET @Msg = 'PO Item Line type is 6 - SM Work Order. Receiving not allowed.'
--	RETURN 1
--	END



vspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineValForJC] TO [public]
GO
