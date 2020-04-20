SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROC [dbo].[vspPCSelectBiddersValidateVendor]
   /***************************************************
   * CREATED BY    : JG 12/17/10
   * Usage:
   *	Called from PC Select Bidders form to validate a vendor based on the scopes/phases they
   *	implement and the ones required in the Bid Package
   *
   * Input:
   *	@JCCo
   *	@PotentialProject        
   *	@BidPackage
   *	@Vendor
   * Output:
   *	@msg
   *
   * Returns:
   *	0             success
   *	1             error
   *************************************************/
    (
      @JCCo bCompany
    , @PotentialProject VARCHAR(20)
    , @BidPackage VARCHAR(20)
    , @Vendor bVendor
    , @msg VARCHAR(255) OUTPUT
    )
AS 
SET nocount ON
   
DECLARE @rcode INT 
   
SELECT  @rcode = 0
,       @msg = 'I'
    
IF @JCCo IS NULL 
    BEGIN
        SELECT  @msg = 'Company value is null'
        ,       @rcode = 1
        GOTO vspexit
    END
        
IF @PotentialProject IS NULL 
    BEGIN
        SELECT  @msg = 'Potential Project value is null'
        ,       @rcode = 1
        GOTO vspexit
    END
        
IF @BidPackage IS NULL 
    BEGIN
        SELECT  @msg = 'Bid Package value is null'
        ,       @rcode = 1
        GOTO vspexit
    END
        
IF @Vendor IS NULL 
    BEGIN
        SELECT  @msg = 'Vendor value is null'
        ,       @rcode = 1
        GOTO vspexit
    END

IF EXISTS ( SELECT TOP ( 1 )
                    1
            FROM    dbo.PCBidPackageScopes
                    LEFT JOIN PCScopes
                    ON dbo.PCBidPackageScopes.VendorGroup = dbo.PCScopes.VendorGroup
                       AND (
                             dbo.PCBidPackageScopes.ScopeCode = dbo.PCScopes.ScopeCode
                             OR dbo.PCBidPackageScopes.Phase = dbo.PCScopes.PhaseCode
                           )
                       AND Vendor = @Vendor
            WHERE   PCScopes.KeyID IS NOT NULL
                    AND JCCo = @JCCo
                    AND PotentialProject = @PotentialProject
                    AND BidPackage = @BidPackage ) 
    BEGIN
        SELECT  @msg = 'V'
    END
ELSE 
    IF NOT EXISTS ( SELECT TOP ( 1 )
                            1
                    FROM    PCScopes
                            LEFT JOIN PCBidPackageScopes
                            ON dbo.PCScopes.VendorGroup = dbo.PCBidPackageScopes.VendorGroup
                    WHERE   Vendor = @Vendor ) 
        BEGIN
            SELECT  @msg = 'N'
        END

  
vspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCSelectBiddersValidateVendor] TO [public]
GO
