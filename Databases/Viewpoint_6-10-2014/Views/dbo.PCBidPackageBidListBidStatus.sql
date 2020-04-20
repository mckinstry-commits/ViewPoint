SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PCBidPackageBidListBidStatus
AS
SELECT     dbo.PCBidPackageBidList.JCCo, dbo.PCBidPackageBidList.PotentialProject, dbo.PCBidPackageBidList.BidPackage, dbo.PCBidPackageBidList.VendorGroup, 
                      dbo.PCBidPackageBidList.Vendor, dbo.PCBidPackageBidList.ContactSeq, dbo.PCBidPackageBidList.AttendingWalkthrough, dbo.PCBidPackageBidList.Notes, 
                      dbo.PCBidCoverage.BidResponse
FROM         dbo.PCBidPackageBidList LEFT OUTER JOIN
                      dbo.PCBidCoverage ON dbo.PCBidPackageBidList.JCCo = dbo.PCBidCoverage.JCCo AND 
                      dbo.PCBidPackageBidList.PotentialProject = dbo.PCBidCoverage.PotentialProject AND dbo.PCBidPackageBidList.BidPackage = dbo.PCBidCoverage.BidPackage AND 
                      dbo.PCBidPackageBidList.VendorGroup = dbo.PCBidCoverage.VendorGroup AND dbo.PCBidPackageBidList.Vendor = dbo.PCBidCoverage.Vendor AND 
                      dbo.PCBidPackageBidList.ContactSeq = dbo.PCBidCoverage.ContactSeq

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Gartht
-- Create date: 4/18/2011
-- Description:	Multibase table update for response field view.
-- =============================================
CREATE TRIGGER [dbo].[vtPCBidPackageBidListBidStatusu]
   ON  [dbo].[PCBidPackageBidListBidStatus] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF (UPDATE(BidResponse))
BEGIN
	IF (NOT EXISTS (SELECT Top 1 1
	  FROM PCBidCoverage c, inserted i
	  WHERE c.JCCo = i.JCCo AND
			c.PotentialProject = i.PotentialProject AND
			c.BidPackage = i.BidPackage AND
			c.VendorGroup = i.VendorGroup AND
			c.Vendor = i.Vendor AND
			c.ContactSeq = i.ContactSeq))
	
	DECLARE @JCCo bCompany, 
			@PotentialProject varchar(20), 
			@BidPackage varchar(20), 
			@VendorGroup bGroup, 
			@Vendor bVendor, 
			@ContactSeq AS tinyint, 
			@BidResponse char(1), 
			@DoMassUpdate bit
	
	SELECT TOP 1 @JCCo = i.JCCo, @PotentialProject=i.PotentialProject,@BidPackage = i.BidPackage,
				 @VendorGroup = i.VendorGroup, @Vendor = i.Vendor, @ContactSeq = i.ContactSeq,
				 @BidResponse = i.BidResponse, @DoMassUpdate = 1 FROM inserted i
	
	exec dbo.vspPCBidPackageUpdateBidResponse @JCCo, @PotentialProject, @BidPackage, @VendorGroup, @Vendor, @ContactSeq, @BidResponse, @DoMassUpdate
	
END

IF (UPDATE(AttendingWalkthrough))
BEGIN
	UPDATE PCBidPackageBidList
	SET [AttendingWalkthrough] = i.[AttendingWalkthrough]
	FROM PCBidPackageBidList bs INNER JOIN inserted i
	ON
	bs.[JCCo] = i.JCCo AND
	bs.[PotentialProject] = i.PotentialProject AND
	bs.[BidPackage] = i.BidPackage AND
	bs.[VendorGroup] = i.VendorGroup AND
	bs.[Vendor] = i.Vendor AND
	bs.[ContactSeq] = i.ContactSeq	
END	

IF (UPDATE(Notes))
	BEGIN
		UPDATE PCBidPackageBidList
		SET [Notes] = i.[Notes]
		FROM PCBidPackageBidList bs INNER JOIN inserted i
		ON
		bs.[JCCo] = i.JCCo AND
		bs.[PotentialProject] = i.PotentialProject AND
		bs.[BidPackage] = i.BidPackage AND
		bs.[VendorGroup] = i.VendorGroup AND
		bs.[Vendor] = i.Vendor AND
		bs.[ContactSeq] = i.ContactSeq	
	END	

END

GO
GRANT SELECT ON  [dbo].[PCBidPackageBidListBidStatus] TO [public]
GRANT INSERT ON  [dbo].[PCBidPackageBidListBidStatus] TO [public]
GRANT DELETE ON  [dbo].[PCBidPackageBidListBidStatus] TO [public]
GRANT UPDATE ON  [dbo].[PCBidPackageBidListBidStatus] TO [public]
GRANT SELECT ON  [dbo].[PCBidPackageBidListBidStatus] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCBidPackageBidListBidStatus] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCBidPackageBidListBidStatus] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCBidPackageBidListBidStatus] TO [Viewpoint]
GO
