SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[PCIntentToBidTemplate]
AS

-- This view is meant to join the information for the generation of Intent to Bid templates
-- It is important to note that this view should always have a where clause that includes a list of the 
-- ContactKeyIDs and the PotentialProject Company and the PotentialProject Id

SELECT
	PCPotentialWork.JCCo, PCPotentialWork.PotentialProject, PCPotentialWork.[Description] AS ProjectDescription,
	PCPotentialWork.JobSiteStreet, PCPotentialWork.JobSiteCity, PCPotentialWork.JobSiteState, PCPotentialWork.JobSiteZip,
	PCPotentialWork.StartDate, PCPotentialWork.CompletionDate,
	PCPotentialWork.DocOtherPlanLoc, PCPotentialWork.DocURL,
	HQCO.Name AS CompanyName, HQCO.[Address] AS CompanyAddress, HQCO.City AS CompanyCity, HQCO.[State] AS CompanyState, HQCO.Zip AS CompanyZip,
	PCContacts.KeyID AS ContactKeyID, PCContacts.Seq AS ContactSeq, PCContacts.Name AS RecipientName, PCContacts.Title AS RecipientTitle,
	PCQualifications.VendorGroup, PCQualifications.Vendor, PCQualifications.Name AS VendorName, PCQualifications.SortName,
	PCQualifications.[Address], PCQualifications.City, PCQualifications.[State], PCQualifications.Zip,
	PCBidPackage.BidPackage, PCBidPackage.[Description] AS BidPackageDescription, PCBidPackage.PackageDetails AS BidPackageDetails, PCBidPackage.BidDueDate, PCBidPackage.BidDueTime,
	PCBidPackage.WalkthroughDate, PCBidPackage.WalkthroughTime, PCBidPackage.WalkthroughNotes,
	PCBidPackage.PrimaryContact, PCBidPackage.PrimaryContactPhone, PCBidPackage.PrimaryContactEmail,
	PCBidPackage.SecondaryContact, PCBidPackage.SecondaryContactPhone, PCBidPackage.SecondaryContactEmail
FROM dbo.PCPotentialWork
	INNER JOIN dbo.HQCO ON PCPotentialWork.JCCo = HQCO.HQCo
	INNER JOIN dbo.PCBidPackage ON PCPotentialWork.JCCo = PCBidPackage.JCCo AND PCPotentialWork.PotentialProject = PCBidPackage.PotentialProject
	INNER JOIN dbo.PCBidPackageBidList ON PCBidPackage.JCCo = PCBidPackageBidList.JCCo AND PCBidPackage.PotentialProject = PCBidPackageBidList.PotentialProject AND PCBidPackage.BidPackage = PCBidPackageBidList.BidPackage
	INNER JOIN dbo.PCContacts ON PCBidPackageBidList.VendorGroup = PCContacts.VendorGroup AND PCBidPackageBidList.Vendor = PCContacts.Vendor AND PCBidPackageBidList.ContactSeq = PCContacts.Seq
	INNER JOIN dbo.PCQualifications ON PCContacts.VendorGroup = PCQualifications.VendorGroup AND PCContacts.Vendor = PCQualifications.Vendor










GO
GRANT SELECT ON  [dbo].[PCIntentToBidTemplate] TO [public]
GRANT INSERT ON  [dbo].[PCIntentToBidTemplate] TO [public]
GRANT DELETE ON  [dbo].[PCIntentToBidTemplate] TO [public]
GRANT UPDATE ON  [dbo].[PCIntentToBidTemplate] TO [public]
GO
