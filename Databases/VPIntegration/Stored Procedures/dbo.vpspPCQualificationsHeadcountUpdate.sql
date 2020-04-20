SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsHeadcountUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @CurrentExecutiveEmployees INT, @AverageExecutiveEmployees INT, @CurrentOfficeEmployees INT, @AverageOfficeEmployees INT, @CurrentShopEmployees INT, @AverageShopEmployees INT, @CurrentJobSiteEmployees INT, @AverageJobSiteEmployees INT, @CurrentTradesEmployees INT, @AverageTradesEmployees INT, @OwnersOut SMALLINT, @OwnersIn SMALLINT, @ManagementOut SMALLINT, @ManagementIn SMALLINT, @PMOut SMALLINT, @PMIn SMALLINT, @ShopType CHAR(1))
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCQualifications
	SET
		CurrentExecutiveEmployees = @CurrentExecutiveEmployees,
		AverageExecutiveEmployees = @AverageExecutiveEmployees,
		CurrentOfficeEmployees = @CurrentOfficeEmployees,
		AverageOfficeEmployees = @AverageOfficeEmployees,
		CurrentShopEmployees = @CurrentShopEmployees,
		AverageShopEmployees = @AverageShopEmployees,
		CurrentJobSiteEmployees = @CurrentJobSiteEmployees,
		AverageJobSiteEmployees = @AverageJobSiteEmployees,
		CurrentTradesEmployees = @CurrentTradesEmployees,
		AverageTradesEmployees = @AverageTradesEmployees,
		OwnersOut = @OwnersOut,
		OwnersIn = @OwnersIn,
		ManagementOut = @ManagementOut,
		ManagementIn = @ManagementIn,
		PMOut = @PMOut,
		PMIn = @PMIn,
		ShopType = @ShopType
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsHeadcountUpdate] TO [VCSPortal]
GO
