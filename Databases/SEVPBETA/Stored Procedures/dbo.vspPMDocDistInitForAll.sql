SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPMDocDistInitForAll]
/***********************************************************************
* Created By:
* Modified By:	GF 10/18/2010 - TFS #793
*				GF 03/18/2011 - TK-02604 SUBCO
*				GF 03/28/2011 - TK-03298 COR
*				GF 04/11/2011 - TK-04056 PURCHASECO
*				JG 04/30/2011 - TK-04388 CCO
*
*
*	This procedure is used to call all PM Doc Dist Init procedures
*	in order to clean up form code in PMToolStripHelper - DocDistInitialize.
*
*
*************************************************************************/
(@pmco bCompany, @project bProject, @doccategory varchar(10), @user bVPUserName,
 @doctype bDocType, @document bDocument = NULL, @template varchar(40) = null,
 @filename varchar(255) = null, @pco varchar(10) = null, @revision tinyint = null,
 @poco bCompany = null, @slco bCompany = null, @sl varchar(30) = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode INT, @KeyID BIGINT

set @rcode = 0

---- if a subcontract change order we need to get key id TK-02604
IF @doccategory = 'SUBCO'
	BEGIN
	SELECT @KeyID = KeyID
	FROM dbo.PMSubcontractCO
	WHERE PMCo=@pmco AND Project = @project AND SLCo=@slco AND SL=@sl AND SubCO=CONVERT(INT,@document)
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @msg = 'Unable to locate subcontract change order record.', @rcode = 1
		GOTO vspexit
		END
	END
	
---- if a change order request we need to get key id TK-03298
IF @doccategory = 'COR'
	BEGIN
	SELECT @KeyID = KeyID
	FROM dbo.PMChangeOrderRequest
	WHERE PMCo=@pmco AND Contract = @project AND COR=CONVERT(INT, @document)
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @msg = 'Unable to locate change order request record.', @rcode = 1
		GOTO vspexit
		END
	END
	
	---- if a contract change order we need to get key id TK-04388
IF @doccategory = 'CCO'
	BEGIN
	SELECT @KeyID = KeyID
	FROM dbo.PMContractChangeOrder
	WHERE PMCo=@pmco AND Contract = @project AND ID=CONVERT(INT, @document)
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @msg = 'Unable to locate contract change order record.', @rcode = 1
		GOTO vspexit
		END
	END

---- if a purchase change order we need to get key id TK-04056
IF @doccategory = 'PURCHASECO'
	BEGIN
	SELECT @KeyID = KeyID
	FROM dbo.PMPOCO
	WHERE PMCo=@pmco AND Project = @project AND POCo=@slco AND PO=@sl AND POCONum=CONVERT(INT,@document)
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @msg = 'Unable to locate purchase change order record.', @rcode = 1
		GOTO vspexit
		END
	END

IF @doccategory = 'PURCHASE'
	BEGIN
	SELECT @KeyID = KeyID
	FROM dbo.POHD
	WHERE POCo=@poco AND PO=@sl
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @msg = 'Unable to locate purchase order record.', @rcode = 1
		GOTO vspexit
		END
	END

--Launch Dist Init Procs by Document Category
if @doccategory = 'RFI'
begin
	execute @rcode = vspPMDocDistInitForRFI @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @msg OUTPUT
end
else if @doccategory = 'RFQ'
begin
	execute @rcode = vspPMDocDistInitForRFQ @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @pco, @msg output	
end
else if @doccategory = 'PCO'
begin
	execute @rcode = vspPMDocDistInitForPCO @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @msg output
end
else if @doccategory = 'DRAWING'
begin
	execute @rcode = vspPMDocDistInitForDrawingLog @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @msg output
end
else if @doccategory = 'INSPECT'
begin
	execute @rcode = vspPMDocDistInitForInspectLog @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @msg output
end
else if @doccategory = 'OTHER'
begin
	execute @rcode = vspPMDocDistInitForOtherDoc @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @msg output
end
else if @doccategory = 'SUBMIT'
begin
	execute @rcode = vspPMDocDistInitForSUBMIT @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @revision, @msg output
end
else if @doccategory = 'TEST'
begin
	execute @rcode = vspPMDocDistInitForTestLog @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @msg output
end
else if @doccategory = 'TRANSMIT'
begin
	execute @rcode = vspPMDocDistInitForTRANSMIT @pmco, @project, @doccategory, @user, @document, 
		@template, @filename, @msg output
END
ELSE IF @doccategory = 'ISSUE'
	BEGIN
	execute @rcode = vspPMDocDistInitForIssueLog @pmco, @project, @doccategory, @user, @doctype, @document, 
		@template, @filename, @msg output
	END
	----TK-02604
ELSE IF @doccategory = 'SUBCO'
	BEGIN
	execute @rcode = vspPMDocDistInitForSUBCO @pmco, @project, @doccategory, @user, @KeyID, @template, @filename, @msg output
	END
	----TK-03298
ELSE IF @doccategory = 'COR'
	BEGIN
	execute @rcode = vspPMDocDistInitForCOR @pmco, @project, @doccategory, @user, @KeyID, @template, @filename, @msg output
	END
	---TK-04388
ELSE IF @doccategory = 'CCO'
	BEGIN
	execute @rcode = vspPMDocDistInitForCCO @pmco, @project, @doccategory, @user, @KeyID, @template, @filename, @msg output
	END
else if @doccategory = 'PURCHASE'
begin
	execute @rcode = vspPMDocDistInitForPO @pmco, @project, @doccategory, @user, @poco, @sl, @KeyID,
		@template, @filename, @msg output
end
---- TK-04056
else if @doccategory = 'PURCHASECO'
	BEGIN
	execute @rcode = vspPMDocDistInitForPOCO @pmco, @project, @doccategory, @user, @KeyID, @template, @filename, @msg output
	END
else if @doccategory = 'SUB' or @doccategory = 'SUBITEM'
begin
	execute @rcode = vspPMDocDistInitForSUB @pmco, @project, @doccategory, @user, @slco, @sl, 
				@template, @filename, @msg OUTPUT
end



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocDistInitForAll] TO [public]
GO
