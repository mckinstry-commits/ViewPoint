SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCReferencesGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
SELECT pcr.[VendorGroup]
      ,[Vendor]
      ,[Seq] + 0 AS Seq
      ,pcr.[ReferenceTypeCode]
      ,Description AS ReferenceTypeCodeDescription
      ,[Contact]
      ,[Company]
      ,[Address]
      ,[City]
      ,[State]
      ,[Country]
      ,[Zip]
      ,[Phone]
      ,[Fax]
      ,[Email]
      ,pcr.[KeyID]
      ,pcr.[Notes]
	FROM PCReferences pcr LEFT JOIN PCReferenceTypeCodes pcrtc ON pcr.ReferenceTypeCode = pcrtc.ReferenceTypeCode
	WHERE pcr.VendorGroup = @VendorGroup AND Vendor = @Vendor
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCReferencesGet] TO [VCSPortal]
GO
