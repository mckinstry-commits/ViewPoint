SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vspHQCheckForSchemeID]
/**********************************************************************
* Created:		CHS	05/02/2012
* Modified:
* 
* Updates the Status and InUseBy info on an existing Batch (bHQBC)
* when exiting a posting or processing program.
*
* Resets Status to 'open'(0) if current Status is less than
* 'posting in progress'(4), or 'posted'(5).  Resets Status
* to 'cancelled'(6) if Batch Table is empty.
*
* Resets InUseBy to null if Status <> 5 (posted).
*
* Pass in:
*	@Co          Company
*	@SchemeID    Scheme ID
*
* Returns:
*	0 = success
*	1 = failed, with error message
*********************************************************************/
    
@Co bCompany, @SchemeID smallint, @Msg varchar(255) output
    
    AS
    SET NOCOUNT ON
    
   	DECLARE @rcode int, @OutMessageLeader varchar(60), @AndMessage varchar(4), @TableMessage varchar(70)
   	
   	SELECT @rcode = 0, @AndMessage = '', @OutMessageLeader = 'Cannot delete. Scheme ID ' + cast(@SchemeID as varchar(10)) + ' is in use by', @TableMessage = ''
    
    SELECT @rcode = 1, @AndMessage = ' and ', @TableMessage = ' Payroll Deduction/Liability code(s)'
    FROM bPRDL WHERE PRCo = @Co and SchemeID = @SchemeID
    
    SELECT @rcode = 1, @TableMessage = @TableMessage + @AndMessage + ' AP Vendor Master On-Cost' 
    FROM vAPVendorMasterOnCost WHERE APCo = @Co and SchemeID = @SchemeID
    
    IF @rcode = 1
		BEGIN
		SELECT @Msg = @OutMessageLeader + @TableMessage + '.'
		END
    
    bspexit:
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQCheckForSchemeID] TO [public]
GO
