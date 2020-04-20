SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGetNextInvoiceNumber]
	-- Add the parameters for the stored procedure here
	@SMCo bCompany,
	@NextInvNumber varchar(10) OUTPUT,
	@errmsg varchar(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @arlastinvoice varchar(10), @rcode int, @ARCo bCompany, @trys tinyint
	
	SELECT @trys = 0, @rcode=0
	
	/* Get the Next Invoice Number from ARCo */
	NextInvNo:

	SELECT @arlastinvoice = InvLastNum, @ARCo = ARCO.ARCo
	FROM ARCO WITH (NOLOCK)
	INNER JOIN SMCO ON SMCO.ARCo = ARCO.ARCo
	WHERE SMCO.SMCo = @SMCo
	IF @@rowcount = 0
   	BEGIN
		SELECT @errmsg = 'Unable to get next available AR invoice number!'
		SELECT @rcode = 1
		GOTO bspexit
   	END
   	
   	if isnumeric(@arlastinvoice) = 1
   	BEGIN
   		--Update the Last Invoice Number
   		UPDATE ARCO SET InvLastNum = CONVERT(varchar, CONVERT(bigint, @arlastinvoice)+1), AuditYN = 'N' 
   		WHERE ARCo = @ARCo AND InvLastNum = @arlastinvoice
   		IF @@rowcount = 0
   		BEGIN
   			-- The record wasn't updated so someone else must have changed it first.
   			SELECT @trys = @trys + 1
   			IF (@trys < 10)
	   			GOTO NextInvNo -- Go Try again
	   		SELECT @errmsg = 'Unable to update the NextInvNumber.', @rcode=1
   		END
   		ELSE
   		BEGIN
	   		-- Turn Auditing back on
   			UPDATE ARCO SET AuditYN = 'Y' WHERE ARCo = @ARCo
   		END
	   	
   		SELECT @NextInvNumber = STR((CONVERT(bigint, @arlastinvoice) + 1),10)
	END
	ELSE
   	BEGIN
   		SELECT @errmsg = 'AR Company LastInvoice Number is not numeric and may not be Automatically incremented!'
   		SELECT @rcode = 1
   	END
   	
   	bspexit:
   	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspSMGetNextInvoiceNumber] TO [public]
GO
