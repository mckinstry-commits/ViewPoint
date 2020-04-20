SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspPCGetDefaultBidSearchCriteria]    Script Date: 12/08/2010 16:50:23 ******/
   
   CREATE  proc [dbo].[vspPCGetDefaultBidSearchCriteria]
    	(@JCCo bCompany, @PotentialProject VARCHAR(20), @BidPackage VARCHAR(20)
    	, @JobSiteCountry CHAR(2) OUTPUT, @JobSiteState VARCHAR(4) OUTPUT, @JobSiteRegion VARCHAR(10) OUTPUT
    	, @ProjectType VARCHAR(10) OUTPUT, @Scopes VARCHAR(MAX) OUTPUT, @Phases VARCHAR(MAX) OUTPUT
    	, @Certificates VARCHAR(MAX) OUTPUT, @msg varchar(255) OUTPUT)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:		JG 12/08/2010
     * MODIFIED By :
     *
     * USAGE:
     *	Grabs the Default Search Criteria for a given Potential Project and Bid Package.
     *
     * INPUT PARAMETERS
     *  JCCo					Company of the Project
	 *	PotentialProject		Potential Project to grab values.
	 *	BidPackage				Bid Package to grab values for.
     *
     * OUTPUT PARAMETERS
     *  @msg		Error message
	 *
     * RETURN VALUE
     *   0			Success
     *   1			Failure
     *****************************************************/
    declare @rcode int
   
    set @rcode = 0
	SET @Scopes = ''
	SET @Phases = ''
	SET @Certificates = ''

	----------------
	-- Validation --
	----------------
	PRINT 'entered'
    if @JCCo is null
    begin
    	select @msg = 'Missing Company!', @rcode = 1
       	goto vspexit
    end
	if @PotentialProject is null
    begin
    	select @msg = 'Missing Potential Project!', @rcode = 1
       	goto vspexit
    END
    if @BidPackage is null
    begin
    	select @msg = 'Missing Bid Package!', @rcode = 1
       	goto vspexit
    end
    
	-- Check to make sure Potential Project exists.
	if not exists(select top 1 1 from vPCPotentialWork with(nolock) where JCCo = @JCCo AND PotentialProject = @PotentialProject)
	begin
		select @msg = 'Potential Project: ' + @PotentialProject + ' in Company: ' + CAST(@JCCo AS VARCHAR) + ' doesn''t exist.', @rcode = 1
		goto vspexit
	end
	
	
	-- Check to make sure the Bid Package is related to a Potential Project.
	if not exists(select top 1 1 from dbo.vPCBidPackage with(nolock) where JCCo = @JCCo AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage)
	begin
		select @msg = 'Bid Package doesn''t exist or it is not visible.', @rcode = 1
		goto vspexit
	end
	
	
	DECLARE @scopeTable TABLE (ScopeCode VARCHAR(10))
	
	DECLARE @phaseTable TABLE (Phase VARCHAR(20))
	
	DECLARE	@certTable TABLE (CertificateType VARCHAR(20))
	
	-----------------------------
	-- Grab Data --
	-----------------------------
	
	begin try
		begin TRANSACTION
		
		-- GET PROJECT INFO
		SELECT @JobSiteCountry = JobSiteCountry, @JobSiteState = JobSiteState
		, @JobSiteRegion = JobSiteRegion, @ProjectType = ProjectType
		FROM dbo.PCPotentialWork
		WHERE JCCo = @JCCo
		AND PotentialProject = @PotentialProject
		
		-- GET SCOPES
		INSERT INTO @scopeTable
		SELECT DISTINCT ScopeCode FROM dbo.PCBidPackageScopes 
		WHERE JCCo = @JCCo
		AND PotentialProject = @PotentialProject
		AND BidPackage = @BidPackage
		AND ScopeCode IS NOT NULL
		ORDER BY ScopeCode
		
		SELECT @Scopes = @Scopes + ScopeCode + ','
		FROM @scopeTable
		
		IF LEN(@Scopes) > 0
		BEGIN
			SET @Scopes = LEFT(@Scopes, LEN(@Scopes) - 1)
		END

		-- GET PHASES		
		INSERT INTO @phaseTable
		SELECT DISTINCT Phase FROM dbo.PCBidPackageScopes
		WHERE JCCo = @JCCo
		AND PotentialProject = @PotentialProject
		AND BidPackage = @BidPackage
		AND Phase IS NOT NULL
		ORDER BY Phase
		
		SELECT @Phases = @Phases + Phase + ','
		FROM @phaseTable
		
		IF LEN(@Phases) > 0
		BEGIN
			SET @Phases = LEFT(@Phases, LEN(@Phases) - 1)
		END
		
		-- GET CERTIFICATES
		INSERT INTO @certTable
		SELECT DISTINCT CertificateType FROM dbo.PCPotentialProjectCertificate
		WHERE JCCo = @JCCo
		AND PotentialProject = @PotentialProject
		AND CertificateType IS NOT NULL	
		ORDER BY CertificateType
		
		SELECT @Certificates = @Certificates + CertificateType + ','
		FROM @certTable
		
		IF LEN(@Certificates) > 0
		BEGIN
			SET @Certificates = LEFT(@Certificates, LEN(@Certificates) - 1)
		END
		
		commit transaction
	end try
	begin catch
		select @msg = error_message(), @rcode = 1
		rollback transaction
	end catch
	
    vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCGetDefaultBidSearchCriteria] TO [public]
GO
