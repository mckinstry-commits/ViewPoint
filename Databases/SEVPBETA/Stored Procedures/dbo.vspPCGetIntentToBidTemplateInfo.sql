SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/8/10
-- Modified By:	GF 12/21/2010 - issue #142753
--				GP 01/17/2011 - issue #142924 added dynamic sql select to add access to all PC columns
--				GarthT 04/05/2011 - TK-03251 - Add Response Field meta clause.
--
-- Description: Returns the information needed for building templates
-- =============================================

CREATE PROCEDURE [dbo].[vspPCGetIntentToBidTemplateInfo]
	@Company bCompany, @PotentialProject varchar(20), @BidPackage varchar(20), @ContactKeyIDsXML varchar(MAX), 
	@MessageBody varchar(MAX), @TemplateName char(40)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    DECLARE @hDoc int, @querystring nvarchar(max), @value nvarchar(max), 
		@query nvarchar(max), @selectClause nvarchar(max), 
		@responsemetavalueclause nvarchar(max),@fromClause nvarchar(max), 
		@whereClause nvarchar(max), @ParamDefinition nvarchar(500), 
		@errmsg VARCHAR(255)
    
    EXEC sp_xml_preparedocument @hDoc OUTPUT, @ContactKeyIDsXML
				
	--return columns
	exec dbo.vspHQWFMergeFieldBuildForPC @TemplateName, @Company, @querystring OUTPUT, @errmsg output

	--build select
	select @selectClause = substring(@querystring , 8, datalength(@querystring))

	--build meta select values if AutoResponse document, otherwise return empty string.
	exec dbo.vspHQGetRFMetaValueClause @TemplateName, @responsemetavalueclause OUTPUT, @errmsg output
	
	--build from
	select @fromClause = ' FROM dbo.PCPotentialWork a' 
		+ ' INNER JOIN dbo.HQCO b ON a.JCCo = b.HQCo'
		+ ' JOIN dbo.PCBidPackage c ON a.JCCo = c.JCCo AND a.PotentialProject = c.PotentialProject'
		+ ' JOIN dbo.PCBidPackageBidList d ON c.JCCo = d.JCCo AND c.PotentialProject = d.PotentialProject AND c.BidPackage = d.BidPackage'
		+ ' JOIN dbo.PCContacts e ON d.VendorGroup = e.VendorGroup AND d.Vendor = e.Vendor AND d.ContactSeq = e.Seq'
		+ ' JOIN dbo.PCQualifications f ON e.VendorGroup = f.VendorGroup AND e.Vendor = f.Vendor'
		+ ' JOIN dbo.PCBidPackageBidListBidResponse r on r.JCCo=d.JCCo and r.PotentialProject=d.PotentialProject and r.BidPackage=d.BidPackage and r.VendorGroup=d.VendorGroup and r.Vendor=d.Vendor and r.ContactSeq=d.ContactSeq'

	--build where	
	select @whereClause = ' WHERE a.JCCo = @Company AND a.PotentialProject = @PotentialProject AND (@BidPackage IS NULL OR c.BidPackage = @BidPackage)'
		+ ' AND e.KeyID IN (SELECT ContactKeyID FROM OPENXML(@hDoc, ''/Contacts/Contact'', 1) WITH (ContactKeyID bigint))'
		----+ ' GROUP BY ' + @selectClause + ',e.KeyID'

	--build query
	select @query = 'SELECT ' + @selectClause +	IsNull(@responsemetavalueclause,'') + ', @MessageBody AS MessageBody, e.KeyID as ContactKeyID' + @fromClause + @whereClause

--PRINT @query


	select @ParamDefinition = '@Company tinyint, @PotentialProject varchar(20), @BidPackage varchar(20), @hDoc int, @MessageBody varchar(max)'

----SELECT @selectClause, @query, @Company, @PotentialProject, @BidPackage

	----execute dynamic sql
	exec sp_executesql @query, 
		@ParamDefinition, 
		@Company = @Company, 
		@PotentialProject = @PotentialProject, 
		@BidPackage = @BidPackage,
		@hDoc = @hDoc, 
		@MessageBody = @MessageBody


	EXEC sp_xml_removedocument @hDoc
	
	SELECT PCBidPackageScopes.*,
		CASE WHEN dbo.PCBidPackageScopes.Phase IS NULL THEN PCBidPackageScopes.ScopeCode ELSE PCBidPackageScopes.Phase END AS ScopePhase,
		CASE WHEN dbo.PCBidPackageScopes.Phase IS NULL THEN PCScopeCodes.[Description] ELSE JCPM.[Description] END AS ScopePhaseDescription
	FROM dbo.PCBidPackageScopes
	LEFT JOIN dbo.PCScopeCodes ON PCBidPackageScopes.VendorGroup = PCScopeCodes.VendorGroup AND PCBidPackageScopes.ScopeCode = PCScopeCodes.ScopeCode
	LEFT JOIN dbo.JCPM ON PCBidPackageScopes.PhaseGroup = JCPM.PhaseGroup AND PCBidPackageScopes.Phase = JCPM.Phase
	WHERE PCBidPackageScopes.JCCo = @Company AND PCBidPackageScopes.PotentialProject = @PotentialProject
		AND (@BidPackage IS NULL OR PCBidPackageScopes.BidPackage = @BidPackage)
	ORDER BY PCBidPackageScopes.ScopeCode, PCBidPackageScopes.PhaseGroup, PCBidPackageScopes.Phase		

    SELECT *
    FROM HQWF
    WHERE TemplateName = @TemplateName
END

GO
GRANT EXECUTE ON  [dbo].[vspPCGetIntentToBidTemplateInfo] TO [public]
GO
