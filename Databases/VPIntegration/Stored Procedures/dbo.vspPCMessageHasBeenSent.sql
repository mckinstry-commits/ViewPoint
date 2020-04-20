SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/5/2010
--				GF 11/17/2010 - issue #141031 change to use date function
--
-- Description:	Should be fired when an invite has successfully or unsuccessfully been sent to update 
--				the status and last sent.
--
-- Modified By:	GP	3/26/2010 - added insert into PCBidMessageHistory
-- =============================================
CREATE PROCEDURE [dbo].[vspPCMessageHasBeenSent]
	@Company bCompany, @PotentialProject VARCHAR(20), @ContactKeyID BIGINT, @SuccessfullySent BIT,
	@BidPackage varchar(20) = null, @DocSubject varchar(200) = null, @DocBody varchar(max) = null, 
	@AttachIDList varchar(max) = null, @FromAddress varchar(60) = null, @Template varchar(40) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @AttachFileNames varchar(max)

	UPDATE PCBidPackageBidList
	SET LastSent = CASE WHEN @SuccessfullySent = 1 THEN dbo.vfDateOnly() ELSE LastSent END,
		MessageStatus = CASE WHEN MessageStatus IS NOT NULL AND MessageStatus <> 'S' AND MessageStatus <> 'F' AND MessageStatus <> 'N' THEN MessageStatus WHEN @SuccessfullySent = 1 THEN 'S' ELSE 'F' END
	FROM PCBidPackageBidList
		INNER JOIN PCContacts ON PCBidPackageBidList.VendorGroup = PCContacts.VendorGroup AND PCBidPackageBidList.Vendor = PCContacts.Vendor AND PCBidPackageBidList.ContactSeq = PCContacts.Seq
	WHERE JCCo = @Company AND PotentialProject = @PotentialProject AND BidPackage = ISNULL(@BidPackage, BidPackage) AND PCContacts.KeyID = @ContactKeyID

	-- save history
	insert dbo.vPCBidMessageHistory(JCCo, PotentialProject, BidPackage, VendorGroup, Vendor, ContactSeq, DateSent,
		DocSubject, DocBody, AttachIDList, FromAddress, Template)
	select @Company, @PotentialProject, ISNULL(@BidPackage, ''), VendorGroup, Vendor, Seq, dbo.vfDateOnly(),
		@DocSubject, @DocBody, @AttachIDList, @FromAddress, @Template
	from dbo.PCContacts with (nolock)
	where KeyID=@ContactKeyID
END

GO
GRANT EXECUTE ON  [dbo].[vspPCMessageHasBeenSent] TO [public]
GO
