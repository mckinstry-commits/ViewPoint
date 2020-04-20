USE [Viewpoint]
GO

/****** Object:  StoredProcedure [dbo].[mckspPMFirmContactInitializeAll]    Script Date: 11/03/2014 09:15:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckspPMFirmContactInitializeAll]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mckspPMFirmContactInitializeAll]
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 8/20/2014
-- Description:	Copy Employees from PREH to PMPM (PM Firm Contacts)
-- =============================================
CREATE PROCEDURE [dbo].[mckspPMFirmContactInitializeAll] 
	-- Add the parameters for the stored procedure here
	@vendorgroup bGroup = 0, 
	@firm bFirm = 0, @msg VARCHAR(255) OUTPUT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--DECLARE @vendorgroup bGroup = 1, @firm bFirm = 800000, @msg VARCHAR(255)
	DECLARE @rcode INT = 0

	insert PMPM(VendorGroup, FirmNumber, ContactCode, LastName, FirstName, MiddleInit,
				SortName, Title, Phone, PrefMethod, EMail, UseFaxServerName)
	SELECT @vendorgroup, @firm, Employee, LastName, isnull(FirstName,''), substring(MidName,1,1),
				SortName, pc.Description, Phone, CASE WHEN Email IS NOT NULL THEN 'E'ELSE 'M' END, Email, 'N'
	from PREH e with (nolock) 
	LEFT JOIN PRCC pc WITH (NOLOCK) ON e.PRCo = pc.PRCo and e.Craft = pc.Craft and e.Class = pc.Class
	where e.PRCo IN (
			SELECT DISTINCT PRCo 
			FROM dbo.PREH
			INNER JOIN dbo.HQCO ON PRCo = HQCo AND HQCO.udTESTCo = 'N') 
		and ActiveYN = 'Y'
		--and Employee >=@beginemployee and Employee <=@endemployee
		and not exists (select TOP 1 1 from PMPM c with (nolock) where c.VendorGroup=@vendorgroup and
     				c.FirmNumber=@firm and (e.Employee=c.ContactCode or e.SortName=c.SortName))




select @msg = 'Firm: '+ CONVERT(VARCHAR(30),@firm) + 'Number of contacts initialized: ' + isnull(convert(varchar(6),@@rowcount),'') + ' !', @rcode=0


--SELECT @msg
bspexit:
	return @rcode

END

GO


