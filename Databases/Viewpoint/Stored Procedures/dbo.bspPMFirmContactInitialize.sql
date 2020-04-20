SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMFirmContactInitialize    Script Date: 8/28/99 9:35:11 AM ******/
CREATE    procedure [dbo].[bspPMFirmContactInitialize]
/*******************************************************************
 * Created By:
 * Modified By:	DV 03/17/2003 - issue #20745 get PRCo from bPMCO. Was getting PMCo.
 *				GF 02/19/2004 - issue #23763 added parameter to initialize active employees only
 *				GF 06/17/2007 - issue #124779 added PREH.Email to insert statement.
 *				Dan So - 03/24/08 - issue #127536 - added LEFT JOIN PRCC (Craft now pc.Description)
 *				GF 06/18/2012 TK-15757 
 *
 *
 *
 * Used to initialize PM Firm Contacts from PREH
 *
 * Pass in PMCompany, VendorGroup, Firm and Beginning and Ending Employee number
 *
 * Sets up Employees with Firms The Employee will get the same nuber
 * as the Employee. If the Employee already is setup(or sort name exists) for that firm then it
 * will be skipped
 *
 * Returns 0 and message if successful
 * Returns 1 and error message if error
 ********************************************************************/
(@pmco bCompany, @vendorgroup bGroup, @firm bFirm, @beginemployee bEmployee,
 @endemployee bEmployee, @activeonly bYN, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @prco bCompany

select @rcode=0, @msg = 'Valid'

select @prco=PRCo from bPMCO with (nolock) where PMCo=@pmco


---- insert based on active flag
if @activeonly = 'Y'
	BEGIN
	----TK-15757 
	insert PMPM(VendorGroup, FirmNumber, ContactCode, LastName, FirstName, MiddleInit,
				SortName, Title, Phone, PrefMethod, EMail, UseFaxServerName)
	select @vendorgroup, @firm, Employee, LastName, isnull(FirstName,''), substring(MidName,1,1),
				SortName, pc.Description, Phone, 'M', Email, 'N'
	from PREH e with (nolock) 
	LEFT JOIN PRCC pc WITH (NOLOCK) ON e.PRCo = pc.PRCo and e.Craft = pc.Craft and e.Class = pc.Class
	where e.PRCo=@prco and ActiveYN = 'Y'
	and Employee >=@beginemployee and Employee <=@endemployee
	and not exists (select TOP 1 1 from PMPM c with (nolock) where c.VendorGroup=@vendorgroup and
     				c.FirmNumber=@firm and (e.Employee=c.ContactCode or e.SortName=c.SortName))
	end
else
	BEGIN
	----TK-15757 
	insert PMPM(VendorGroup, FirmNumber, ContactCode, LastName, FirstName, MiddleInit,
				SortName, Title, Phone, PrefMethod, EMail, UseFaxServerName)
	select @vendorgroup, @firm, Employee, LastName, isnull(FirstName,''), substring(MidName,1,1),
				SortName, pc.Description, Phone, 'M', Email, 'N'
	from PREH e with (nolock) 
	LEFT JOIN PRCC pc WITH (NOLOCK) ON e.PRCo = pc.PRCo and e.Craft = pc.Craft and e.Class = pc.Class
	where e.PRCo=@prco and Employee >=@beginemployee and Employee <=@endemployee
	and not exists (select TOP 1 1 from PMPM c with (nolock) where c.VendorGroup=@vendorgroup and
					c.FirmNumber=@firm and (e.Employee=c.ContactCode or e.SortName=c.SortName))
	end



select @msg = 'Number of contacts initialized: ' + isnull(convert(varchar(6),@@rowcount),'') + ' !', @rcode=0


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmContactInitialize] TO [public]
GO
