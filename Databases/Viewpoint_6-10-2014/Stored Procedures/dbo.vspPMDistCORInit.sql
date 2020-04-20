SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMDistCORInit]
/*************************************
* Created By :	DAN SO 03/21/2011 - copied from vspPMDistSubCOInit
* Modified By:	GF 08/24/2011 TK-02767
*				SCOTTP 05/10/2013 - TFS-49587,49703 Fix issue with adding a new contact record
*
*
* Pass this a Firm contact and it will initialize a Change Order Request
* distribution line in the vPMDistribution table.
*
*
* Pass:
*       PMCO			PM Company this Other Document is in
*       Project			Project for the Other Document
*       SentToFirm		Sent to firm to initialize
*       SentToContact	Contact to initialize to
*		CORKeyID		Change Order Request KeyID
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
@CORKeyID bigint = null, @msg varchar(255) = null output)
as
set nocount on

	DECLARE @rcode int, @VendorGroup bGroup, @Seq bTrans, @PrefMethod varchar(1), @EmailOption char(1),
			@Contract bContract, @COR smallint

	SET @rcode = 0
   
	-- Check for nulls --
	IF @PMCo IS NULL OR @Project IS NULL OR @CORKeyID IS NULL OR
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
		
	-- get Contract and ChangeOrderRequest(COR) number TK-02767
	SELECT	@Contract = Contract, @COR = COR
	  FROM	dbo.PMChangeOrderRequest 
	 WHERE	KeyID = @CORKeyID
		
	-- check if already in distribution table TK-02767
	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.vPMDistribution WITH (NOLOCK) WHERE PMCo=@PMCo AND Project=@Project
				AND VendorGroup=@VendorGroup AND SentToFirm=@SentToFirm AND SentToContact=@SentToContact
				AND CORContract=@Contract AND COR=@COR)
		BEGIN
		
			-- Get next Seq --
			SELECT	@Seq = 1
			SELECT	@Seq = isnull(Max(Seq),0) + 1
			  FROM	dbo.PMDistribution
			 WHERE	PMCo = @PMCo and Project = @Project
			 ----TK-02767
			   AND	CORContract=@Contract AND COR=@COR

			-- Insert vPMDistribution record TK-02767
			INSERT INTO vPMDistribution(PMCo, Project, CORContract, COR, Seq, VendorGroup, SentToFirm, SentToContact, 
					PrefMethod, Send, CC, CORID)
			VALUES(@PMCo, @Project, @Contract, @COR, @Seq, @VendorGroup, @SentToFirm, @SentToContact, 
					@PrefMethod, 'Y', @EmailOption, @CORKeyID)
					
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
GRANT EXECUTE ON  [dbo].[vspPMDistCORInit] TO [public]
GO
