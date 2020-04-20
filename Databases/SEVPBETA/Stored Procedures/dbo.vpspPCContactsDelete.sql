SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPCContactsDelete]
-- =============================================
-- Author:		<Jeremiah Barkley>
-- Create date: <1/21/09>
-- Description:	<PCContactsDelete Script>

-- Modified:
--				JG	12/15/2012	TK-11003 - Added validation to check that the contact can be deleted.
--				JG  12/29/2012  TK-00000 - Modified message to tell the first package the contact is on.
-- =============================================
	-- Add the parameters for the stored procedure here
	(@Original_KeyID INT)
AS
SET NOCOUNT ON;

DECLARE @rcode int, @potentialProject VARCHAR(20), @bidPackage VARCHAR(20), @Message varchar(255)
SET @rcode = 0
SET @Message = ''

SELECT TOP 1 @potentialProject = PotentialProject, @bidPackage = BidPackage
FROM  dbo.PCContacts
	RIGHT JOIN dbo.PCBidPackageBidList 
	ON	PCContacts.VendorGroup = PCBidPackageBidList.VendorGroup
		AND PCContacts.Vendor = PCBidPackageBidList.Vendor
		AND Seq = ContactSeq
WHERE PCContacts.KeyID = @Original_KeyID

IF @@ROWCOUNT > 0
BEGIN
			
	SET @rcode = 1
	SET @Message = 'Contact exists on Potential Project: ' + @potentialProject + ', Bid Package: ' + @bidPackage + '. Cannot remove!'
	GoTo bspmessage
END


DELETE FROM PCContacts
WHERE KeyID = @Original_KeyID

RETURN;

bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vpspPCContactsDelete] TO [VCSPortal]
GO
