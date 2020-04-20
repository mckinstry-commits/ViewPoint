SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPMProjectFirmsGet]
   /************************************************************************
   * CREATED: MH    
   * MODIFIED:    AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
   *
   * Purpose of Stored Procedure
   *    Get Project Firms for copying
   
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/

(
  @pmco bCompany,
  @project bProject,
  @vendor bVendor
)
AS 
SET nocount ON
   
           --Local variable declarations list goes here
   
DECLARE @rcode int,
    @msg varchar(80) 
   
   
SELECT  @rcode = 0
SELECT  @msg = NULL
   
   
IF @pmco IS NULL 
    BEGIN
        SELECT  @msg = 'Missing PM Company!',
                @rcode = 1
        GOTO bspexit
    END
   
IF @project IS NULL 
    BEGIN
        SELECT  @msg = 'Missing Project!',
                @rcode = 1
        GOTO bspexit
    END
   
IF @vendor IS NULL 
    BEGIN
        SELECT  @msg = 'Missing Vendor Group!',
                @rcode = 1
        GOTO bspexit
    END
   
   
   -- get firm information
   --#142278
SELECT  PMPF.FirmNumber,
        PMFM.FirmName,
        PMPF.ContactCode,
        PMPM.FirstName + ' ' + PMPM.LastName ContactName,
        PMPF.[Description]
FROM    dbo.PMPF 
        JOIN dbo.PMFM   ON PMPF.VendorGroup = PMFM.VendorGroup
							AND PMPF.FirmNumber = PMFM.FirmNumber
        JOIN dbo.PMPM   ON  PMPF.VendorGroup = PMPM.VendorGroup
							AND PMPF.FirmNumber = PMPM.FirmNumber
							AND PMPF.ContactCode = PMPM.ContactCode
WHERE   PMPF.PMCo = @pmco
        AND PMPF.Project = @project
        AND PMPF.VendorGroup = @vendor
   
bspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectFirmsGet] TO [public]
GO
