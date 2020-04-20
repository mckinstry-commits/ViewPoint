SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPOReOpenVal    Script Date:  ******/
CREATE proc [dbo].[vspPOReOpenVal]
/***********************************************************
* CREATED BY: 		DC  7/25/07  #125114
* MODIFIED By :		DC  04/24/08 #128037  - Can't reopen a PO once it has been closed 
*									and backordered amts zeroed.  Changed the validation
*									procedure to a warning.
*					GF 7/27/2011 - TK-07144 changed to varchar(30)
*
* USAGE:
* Validates PO to Prohibit re-opening a closed PO where backorder was relieved 
*
* INPUT PARAMETERS
*   @co		PO Company
*	@po		PO #
*
* OUTPUT PARAMETERS
*   @msg      error message 
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/ 
  
(@co bCompany, @po VARCHAR(30), @status int, @msg varchar(255) output)
as
  
set nocount on
  
declare @rcode int
  
select @rcode = 0
  
if @co is null
	begin
	select @msg = 'Missing PO Company!', @rcode = 1
	goto vspexit
	end

if @po is null
	begin
	select @msg = 'Missing PO Number!', @rcode = 1
	goto vspexit
	end

	if @status <> 2 
		BEGIN
		if exists (
				SELECT 1 
				FROM POCD with (nolock) 
				JOIN HQBC on HQBC.Co = POCD.POCo and HQBC.Mth = POCD.Mth and HQBC.BatchId = POCD.BatchId
				WHERE POCD.POCo = @co and POCD.PO = @po
					AND HQBC.Source = 'PO Close')
			BEGIN
				SELECT @msg = 'This PO was closed and its backordered amounts were set to zero.  You cannot edit any items that were set to zero.   You can add new items.   If invoices are posted to lines that have been set to zero, negative committed costs will result.', @rcode = 1
				--SELECT @msg = 'This PO was closed and its backordered amounts were set to zero.  You can not re-open this PO!', @rcode = 1
				GOTO vspexit
			END
		END
		
  
vspexit:
  	
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOReOpenVal] TO [public]
GO
