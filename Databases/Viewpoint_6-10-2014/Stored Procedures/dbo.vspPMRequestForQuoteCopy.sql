SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE	PROCEDURE [dbo].[vspPMRequestForQuoteCopy]

/***********************************************************
   * CREATED BY:	STO	03/21/2013
   * REVIEWD BY:	
   * MODIFIED BY:	HH  05/15/2013 TFS 50310 copy following fields from vPMRequestForQuote:
   *					ReceivedDate,VendorGroup,FirmNumber,ResponsiblePerson
   *				
   * USAGE:
   * Copies RFQ info and related tab info to new RFQ.
   *
   * INPUT PARAMETERS
   *	PMCo   
   *	OldProject
   *	OldRFQItem
   *	OldRFQ
   *	NewProject
   *	NewRFQItem
   *	NewRFQ
   *	NewRFQDesc
   *	
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@PMCo bCompany, @OldProject bJob, @OldRFQ bDocument, @NewProject bJob, @NewRFQ bDocument, 
	@NewRFQDesc varchar(60) = null, @rKeyID int output, @msg varchar(255) output)
  as
  set nocount on

declare @rcode int,@PMDHNextSeq int,@NumOfRFQItems int,@JobStatus varchar(max)
select @rcode = 0
set @rKeyID = NULL
-------------------------------
-- Validate input output params
-------------------------------

if @PMCo is null
begin
	select @msg='Missing PM Company!', @rcode = 1
	goto vspexit
end

if @OldProject is null
begin
	select @msg='Missing Copy From (source) Project!', @rcode = 1
	goto vspexit
end

if @OldRFQ is null
begin
	select @msg='Missing Copy From (source) RFQ!', @rcode = 1
	goto vspexit
end

if @NewProject is null
begin
	select @msg='Missing Copy To (dest) Project!', @rcode = 1
	goto vspexit
end

if @NewRFQ is null
begin
	select @msg='Missing Copy To (dest) RFQ!', @rcode = 1
	goto vspexit
end

--make sure the Copy From (source) RFQ exists
if not exists 	(select top 1 1 from dbo.vPMRequestForQuote where PMCo = @PMCo and Project = @OldProject 
		AND RFQ = @OldRFQ)
begin
	select @msg='The RFQ you are attempting to copy from (source) does not exists, please enter a new value.', @rcode = 1
	goto vspexit	
end

--make sure the Copy To (dest) RFQ does not exist
if exists (select top 1 1 from dbo.vPMRequestForQuote where PMCo = @PMCo and Project = @NewProject
	AND RFQ = @NewRFQ)
begin
	select @msg='The RFQ you are attempting to copy to (dest) already exists, please enter a new value.', @rcode = 1
	goto vspexit	
end

---------------
-- Copy the RFQ
---------------

-- select * from dbo.PMRequestForQuoteDetail where PMCo = @PMCo AND Project=@OldProject and RFQ=@OldRFQ
set @NumOfRFQItems= (select count(RFQItem) from dbo.PMRequestForQuoteDetail where PMCo = @PMCo AND Project=@OldProject and RFQ=@OldRFQ)

-- do an insert select for the header record here.  Is always done as checks above prove we have a record
-- to insert.

INSERT dbo.vPMRequestForQuote(PMCo,Project,RFQ,CreateDate,SentDate,DueDate,ReceivedDate,[Description],Scope,
ScopeButtonText,[Status],Notes,UniqueAttchID,VendorGroup,FirmNumber,ResponsiblePerson)
SELECT q.PMCo,@NewProject,@NewRFQ as RFQ,q.CreateDate,q.SentDate,q.DueDate,q.ReceivedDate,
	CASE 
		WHEN @NewRFQDesc IS NULL THEN q.[Description]
		WHEN @NewRFQDesc IS NOT NULL THEN @NewRFQDesc
	END as [Description],
	q.Scope,q.ScopeButtonText,q.[Status],q.Notes,q.UniqueAttchID,q.VendorGroup,q.FirmNumber,q.ResponsiblePerson
FROM dbo.vPMRequestForQuote q
WHERE	q.PMCo = @PMCo 
		AND (q.Project = @OldProject OR @OldProject IS NULL) 
		AND (q.[Status]= @JobStatus OR @JobStatus IS NULL)
		AND (q.RFQ = @OldRFQ)

-- if we have RFQItems associated with the RFQ we know insert those records into the detail table
if (@NumOfRFQItems >= 1)
	BEGIN
		INSERT dbo.vPMRequestForQuoteDetail(PMCo,Project,RFQ,RFQItem,[Description],Scope,ScopeButtonText,
		Status,ROM,SentDate,ReceivedDate,VendorGroup,Firm,Vendor,Contact,Notes,UniqueAttchID)
		SELECT p.PMCo,@NewProject,@NewRFQ as RFQ,p.RFQItem,p.[Description],p.Scope,p.ScopeButtonText,p.[Status],
			p.ROM,p.SentDate,p.ReceivedDate,p.VendorGroup,p.Firm,p.Vendor,p.Contact,p.Notes,p.UniqueAttchID
		FROM dbo.vPMRequestForQuoteDetail p
		WHERE	p.PMCo = @PMCo
				AND ( p.Project = @OldProject OR @OldProject IS NULL ) 
				AND ( p.[Status] = @JobStatus OR @JobStatus IS NULL )
				AND p.RFQ = @OldRFQ
	END

set @rKeyID = (select q.KeyID from dbo.vPMRequestForQuote q where q.PMCo = @PMCo AND q.Project = @OldProject AND q.RFQ = @OldRFQ)

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMRequestForQuoteCopy] TO [public]
GO
