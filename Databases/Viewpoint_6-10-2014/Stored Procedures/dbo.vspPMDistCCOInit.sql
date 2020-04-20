SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMDistCCOInit]
/*************************************
* Created By :	SCOTTP 05/10/2013 - TFS-49587,49703
* Modified By:	
*
* Pass this a Firm contact and it will initialize a Contract Change Order
* distribution line in the vPMDistribution table.
*
*
* Pass:
*       PMCO			PM Company this Other Document is in
*       Project			Project for the Other Document
*       SentToFirm		Sent to firm to initialize
*       SentToContact	Contact to initialize to
*       CCOKeyID		Change Order Request Contract KeyID
*
* Returns:
*      msg if Error
* Success returns:
*	0 on Success, 1 on Error
*
* Error returns:

*	1 and error message
**************************************/
(@PMCo bCompany = null, @Project bJob = null, @SentToFirm bFirm = null, @SentToContact bEmployee = null, 
@CCOKeyID bigint = null, @msg varchar(255) = null output)
as
set nocount on

	DECLARE @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1), @EmailOption char(1),
			@Contract bContract, @ID smallint

	SET @rcode = 0
   
	-- Check for nulls --
	IF @PMCo IS NULL OR @Project IS NULL OR @CCOKeyID IS NULL OR
       @SentToFirm IS NULL OR @SentToContact IS NULL
   		BEGIN
   			SET @msg = 'Missing information!'
   			SET @rcode = 1
   			GOTO vspexit
   		END
   
	-- Get VendorGroup --
	SELECT	@VendorGroup = h.VendorGroup
	  FROM	bHQCO h with (nolock) join bPMCO p with (nolock) on h.HQCo = p.APCo
	 WHERE	p.PMCo = @PMCo
   
	-- Get Prefered Method --
	SELECT	@PrefMethod = PrefMethod
	  FROM	bPMPM with (nolock)
	 WHERE	VendorGroup = @VendorGroup AND FirmNumber = @SentToFirm AND ContactCode = @SentToContact
	 
	IF ISNULL(@PrefMethod,'') = '' SET @PrefMethod = 'M'
   
	-- Get EmailOption --
	SELECT	@EmailOption = ISNULL(EmailOption,'N') 
	  FROM	bPMPF with (nolock) 
	 WHERE  PMCo=@PMCo AND Project=@Project AND VendorGroup=@VendorGroup 
	   AND	FirmNumber=@SentToFirm AND ContactCode=@SentToContact

	IF ISNULL(@EmailOption,'') = '' SET @EmailOption = 'N'
		
	-- get Contract and PMContractChangeOrder(CCO) number
	SELECT	@Contract = Contract, @ID = ID
	  FROM	dbo.PMContractChangeOrder 
	 WHERE	KeyID = @CCOKeyID
		
	-- check if already in distribution table TK-02767
	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution WITH (NOLOCK) WHERE PMCo=@PMCo AND Project=@Project
				AND VendorGroup=@VendorGroup AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
				AND Contract=@Contract AND ID=@ID)
		BEGIN
		
			-- Get next Seq --
			SELECT	@Seq = 1
			SELECT	@Seq = isnull(Max(Seq),0) + 1
			  FROM	dbo.PMDistribution
			 WHERE	PMCo = @PMCo and Project = @Project
			 ----TK-02767
			   AND	Contract=@Contract AND ID=@ID

			-- Insert vPMDistribution record TK-02767
			INSERT INTO vPMDistribution(PMCo, Project, Contract, ID, Seq, VendorGroup, SentToFirm, SentToContact, 
					PrefMethod, Send, CC, ContractCOID)
			VALUES(@PMCo, @Project, @Contract, @ID, @Seq, @VendorGroup, @SentToFirm, @SentToContact, 
					@PrefMethod, 'Y', @EmailOption, @CCOKeyID)
					
			IF @@ROWCOUNT = 0
				BEGIN
					SET @msg = 'Nothing inserted!'
					SET @rcode=1
					GOTO vspexit
				END

			IF @@ROWCOUNT > 1
				BEGIN
					SET @msg = 'Too many rows affected, insert aborted!'
					SET @rcode=1
					GOTO vspexit
				END
	   
	   END



vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDistCCOInit] TO [public]
GO
