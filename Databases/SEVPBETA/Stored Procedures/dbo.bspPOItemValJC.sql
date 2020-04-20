SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOItemValJC    Script Date: 8/28/99 9:33:09 AM ******/
   CREATE  proc [dbo].[bspPOItemValJC]
   /***********************************************************
    * CREATED BY	: DANF 01/10/2000
    * Modified By:		GF 7/27/2011 - TK-07144 changed to varchar(30) 
    *					GF 09/07/2011 TK-08225 PO Item Line
    *
    *
    * USED BY
    *   JC Cost Adjustments
    *
    *
    * USAGE:
    * validates PO item
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against
    *   PO to validate
    *   PO Item to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PO,
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
(@poco bCompany = 0, @po VARCHAR(30) = null, @poitem bItem=null,
 @POItemLine INT = NULL OUTPUT, @msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON


declare @rcode int

SET @rcode = 0
SET @POItemLine = NULL

if @poco is null
	begin
	select @msg = 'Missing PO Company!', @rcode = 1
	goto bspexit
	end

if @po is null
	begin
	select @msg = 'Missing PO!', @rcode = 1
	goto bspexit
	end


if @poitem is null
	begin
	select @msg = 'Missing PO Item#!', @rcode = 1
	goto bspexit
	end
   
   
select @msg=Description
FROM dbo.POIT
WHERE POCo=@poco
	AND	PO=@po
	AND POItem=@poitem
if @@rowcount = 0
	begin
	select @msg='PO item does not exist!', @rcode=1
	goto bspexit
	END

---- check if we only have one line for the item and if so return 1 as default
IF (SELECT COUNT(POItemLine) FROM dbo.POItemLine WHERE POCo=@poco AND PO=@po AND POItem=@poitem) = 1
	BEGIN
	SET @POItemLine = 1
	END


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOItemValJC] TO [public]
GO
