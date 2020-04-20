SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMGetNextPMDocNum   Script Date: 11/03/2004 ******/
CREATE  procedure [dbo].[vspPMGetNextPMDocNum]
/************************************************************************
 * Created By:	GF 10/09/2006 - 6.x only gets next PM document # depending on doc type.    
 * Modified By:	GF 10/23/2008 - issue #130755 have a default doc type for submittals
 *				GF 03/16/2009 - issue #132485 option for RFQ numbering
 *				GP 08/17/2009 - issue #134115 added drawing revision numbering
 *				DC 07/29/2010 - #140529 - Improvement to PM change management
 *				GF 11/10/2010 - issue #141982 - exclude '+,-' from check for next numeric.
 *				GF 09/26/2011 - TK-08779 #144778 fix for decimal in PCO value for next number.
 *				JG 02/21/2012 - TK-12750 - Changed the type of num_doc from a int to a bigint to support
 *										   numbers up to 18 characters long.
 *				JG 02/24/2012 - TK-12750 - Added Floor to all doc IDs to avoid going to the wrong value due to rounding.
 *				JG 02/24/2012 - TK-12750 - Checking length of returned number, if over 10 chars (or 6 for Meetings) then return null.
 *
 *
 *
 * This stored procedure is called from any PM form where we want to get
 * the next sequential document number. If unable to get next document number
 * will return error and user will have to enter manually.
 *
 * Punch List, Transmittal, and ACO's do not have a document type. Need to fake it.
 *
 * INPUT PARAMS:
 * @pmco		PM Company
 * @project		PM Project
 * @doctype		PM Document Type
 * @formname	PM Calling Form  
 *    
 * OUTPUT PARAMS
 * @docnumber	Next document number formatted to bDocument based on category for document type.
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
(@pmco bCompany, @project bJob, @doctype bDocType = null, @co bACO = null, @formname varchar(120) = null, 
 @docnumber bDocument = null output, @errmsg varchar(255) output)   	
as
set nocount on

declare @rcode integer, @next_doc bigint, @doccategory varchar(10),
		@length varchar(10), @mask varchar(30), @dummy varchar(30),
		@autogen varchar(10), @acomask varchar(30), @acoitemmask varchar(30),
		@pcomask varchar(30), @autogenpco varchar(1), @autogenmtg varchar(1),
		@autogenrfi varchar(1), @autogenrfq varchar(1),
		@keyid bigint, @pco varchar(10), @lastchar tinyint, @pconumberlength tinyint, --DC #140529
		@nextnum bigint, @nextnumastext varchar(10), @beginpco varchar(10), @nextpco varchar(10)  --DC #140529

select @rcode = 0, @docnumber = '', @next_doc = 0, @autogen = 'P', @autogenpco = 'P',
		@autogenmtg = 'P', @autogenrfi = 'P', @autogenrfq = 'C'

---- validate parameters
if @pmco is null
   	begin
   	select @errmsg = 'Missing PM Company.', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @errmsg = 'Missing PM Project.', @rcode = 1
   	goto bspexit
   	end

----if @doctype is null
----	begin
----	select @errmsg = 'Missing PM Document Type.', @rcode = 1
----	goto bspexit
----	end

---- if from PMACOS form then set dummy document category
if @formname = 'PMACOS'
	begin
	select @doccategory = 'ACO'
	goto getNextDocument
	end

---- if from PMACOSITEMS form then set dummy document category
if @formname = 'PMACOSITEMS'
	begin
	select @doccategory = 'ACO'
	goto getNextDocument
	end

---- if from PMTRANSMITTAL form then set dummy document category
if @formname = 'PMTRANSMITTAL'
	begin
	select @doccategory = 'TRANSMIT'
	goto getNextDocument
	end

---- if from PMPUNCHLIST form then set dummy document category
if @formname = 'PMPUNCHLIST'
	begin
	select @doccategory = 'PUNCH'
	goto getNextDocument
	end

---- if from PMPROJECTESTIMATES from then set dummy document category
if @formname = 'PMPROJECTBUDGETS'
	begin
	select @doccategory = 'BUDGETNO'
	goto getNextDocument
	end

---- if from DRAWINGREV form then set dummy document category
if @formname = 'DRAWINGREV'
	begin
	select @doccategory = 'DRAWINGREV'
	goto getNextDocument
	end

---- get document category from PMDT
if @doctype = 'STD_DUMMY'
	begin
	select @doccategory = 'SUBMIT'
	end
else
	begin
	select @doccategory=DocCategory from PMDT with (nolock) where DocType=@doctype
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid Document Type.', @rcode = 1
		goto bspexit
		end
	end

getNextDocument:
---- get input mask for bDocument
select @mask=InputMask, @length = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bDocument'
if isnull(@mask,'') = '' select @mask = 'L'
if isnull(@length,'') = '' select @length = '10'
if @mask in ('R','L')
   	begin
   	select @mask = @length + @mask + 'N'
   	end

---- get input mask for bACO
select @acomask=InputMask, @length = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bACO'
if isnull(@acomask,'') = '' select @acomask = 'L'
if isnull(@length,'') = '' select @length = '10'
if @acomask in ('R','L')
   	begin
   	select @acomask = @length + @acomask + 'N'
   	end

---- get input mask for bACOItem. use for both ACO and PCO items
select @acoitemmask=InputMask, @length = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bACO'
if isnull(@acoitemmask,'') = '' select @acoitemmask = 'L'
if isnull(@length,'') = '' select @length = '10'
if @acoitemmask in ('R','L')
   	begin
   	select @acoitemmask = @length + @acoitemmask + 'N'
   	end

---- get input mask for bPCO
select @pcomask=InputMask, @length = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPCO'
if isnull(@pcomask,'') = '' select @pcomask = 'L'
if isnull(@length,'') = '' select @length = '10'
if @pcomask in ('R','L')
   	begin
   	select @pcomask = @length + @pcomask + 'N'
   	end


---- try to get the next numeric document number depending on document category
if @doccategory = 'RFI'
	begin
	select @autogen = AutoGenRFINo from JCJM with (nolock) where JCCo=@pmco and Job=@project
	---- next submittal by project
	if @autogen = 'P' 
		begin
		select @next_doc = max(cast(FLOOR(RFI) as numeric) + 1) 
		from dbo.PMRI with (nolock) where PMCo=@pmco and Project=@project
		AND SUBSTRING(LTRIM(RFI),1,1) not in ('+', '-') 
		and isnumeric(RFI) = 1
		end
	else
		---- if not by project, assume by project and RFI type
		begin
		select @next_doc = max(cast(FLOOR(RFI) as numeric) + 1) 
		from dbo.PMRI with (nolock) where PMCo=@pmco and Project=@project and RFIType=@doctype
		AND SUBSTRING(LTRIM(RFI),1,1) not in ('+', '-') 
		and isnumeric(RFI) = 1
  		end
	---- if null or zero set to 1
	if isnull(@next_doc,0) = 0 select @next_doc = 1
	
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	
	---- check if exists in table
	if exists(select 1 from PMRI with (nolock) where PMCo=@pmco and Project=@project and RFIType=@doctype and RFI=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next RFI number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end


if @doccategory = 'TRANSMIT'
	begin
	select @next_doc = max(cast(FLOOR(Transmittal) as numeric) + 1)
	from PMTM with (nolock) where PMCo=@pmco and Project=@project
	AND SUBSTRING(LTRIM(Transmittal),1,1) not in ('+', '-') 
	and isnumeric(Transmittal) = 1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	
	---- check if exists in table
	if exists(select 1 from PMTM with (nolock) where PMCo=@pmco and Project=@project and Transmittal=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Transmittal number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end


if @doccategory = 'PUNCH'
	begin
	select @next_doc = max(cast(FLOOR(PunchList) as numeric) + 1)
	from PMPU with (nolock) where PMCo=@pmco and Project=@project
	AND SUBSTRING(LTRIM(PunchList),1,1) not in ('+', '-') 
	and isnumeric(PunchList) = 1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	---- check if exists in table
	if exists(select 1 from PMPU with (nolock) where PMCo=@pmco and Project=@project and PunchList=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Punch List number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end


if @doccategory = 'OTHER'
	begin
	select @next_doc = max(cast(FLOOR(Document) as numeric) + 1)
	from PMOD with (nolock) where PMCo=@pmco and Project=@project and DocType=@doctype
	AND SUBSTRING(LTRIM(Document),1,1) not in ('+', '-') 
	and isnumeric(Document) = 1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	---- check if exists in table
	if exists(select 1 from PMOD with (nolock) where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Other Document number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end


if @doccategory = 'DRAWING'
	begin
	select @next_doc = max(cast(FLOOR(Drawing) as numeric) + 1)
	from PMDG with (nolock) where PMCo=@pmco and Project=@project and DrawingType=@doctype
	AND SUBSTRING(LTRIM(Drawing),1,1) not in ('+', '-') 
	and isnumeric(Drawing) = 1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	---- check if exists in table
	if exists(select 1 from PMDG with (nolock) where PMCo=@pmco and Project=@project and DrawingType=@doctype and Drawing=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Drawing Log number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end

if @doccategory = 'DRAWINGREV'
	begin
	select @next_doc = max(cast(FLOOR(Rev) as numeric) + 1)
	from dbo.PMDR with (nolock) where PMCo=@pmco and Project=@project
	AND SUBSTRING(LTRIM(Rev),1,1) not in ('+', '-') 
	and isnumeric(Rev)=1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber output	
	END
	---- check if exists in table
	if exists(select 1 from dbo.PMDR with (nolock) where PMCo=@pmco and Project=@project and Rev=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Drawing Log Revision number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end	

if @doccategory = 'TEST'
	begin
	select @next_doc = max(cast(FLOOR(TestCode) as numeric) + 1)
	from PMTL with (nolock) where PMCo=@pmco and Project=@project and TestType=@doctype
	AND SUBSTRING(LTRIM(TestCode),1,1) not in ('+', '-') 
	and isnumeric(TestCode) = 1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	---- check if exists in table
	if exists(select 1 from PMTL with (nolock) where PMCo=@pmco and Project=@project and TestType=@doctype and TestCode=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Test Log number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end


if @doccategory = 'INSPECT'
	begin
	select @next_doc = max(cast(FLOOR(InspectionCode) as numeric) + 1)
	from PMIL with (nolock) where PMCo=@pmco and Project=@project and InspectionType=@doctype
	AND SUBSTRING(LTRIM(InspectionCode),1,1) not in ('+', '-') 
	and isnumeric(InspectionCode) = 1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	---- check if exists in table
	if exists(select 1 from PMIL with (nolock) where PMCo=@pmco and Project=@project and InspectionType=@doctype and InspectionCode=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Inspection Log number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end


if @doccategory = 'ACO'
	begin
	---- ACOs
	if @formname = 'PMACOS'
		begin
		select @next_doc = max(cast(FLOOR(ACO) as numeric) + 1)
		from PMOH with (nolock) where PMCo=@pmco and Project=@project
		AND SUBSTRING(LTRIM(ACO),1,1) not in ('+', '-') 
		and isnumeric(ACO) = 1
		if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
		
		---- skip if greater than 10 chars TK-12750
		IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
		BEGIN
			------ format @docnumber using appropiate value
			set @dummy = convert(varchar(10),@next_doc)
			exec @rcode = dbo.bspHQFormatMultiPart @dummy, @acomask, @docnumber output	
		END
		
		---- check if exists in table
		if exists(select 1 from PMOH with (nolock) where PMCo=@pmco and Project=@project and ACO=@docnumber)
			begin
			select @errmsg = 'Error occurred trying to get next ACO number. Enter manually.', @rcode = 1, @docnumber = ''
			goto bspexit
			end
		goto bspexit
		end

	---- ACO Items
	if @formname = 'PMACOSITEMS'
		begin
		select @next_doc = max(cast(FLOOR(ACOItem) as numeric) + 1)
		from PMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@co
		AND SUBSTRING(LTRIM(ACOItem),1,1) not in ('+', '-') 
		and isnumeric(ACOItem) = 1
		---- if null or zero set to 1
		if isnull(@next_doc,0) = 0 select @next_doc = 1
		---- skip if greater than 10 chars TK-12750
		IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
		BEGIN
			------ format @docnumber using appropiate value
			set @dummy = convert(varchar(10),@next_doc)
			exec @rcode = dbo.bspHQFormatMultiPart @dummy, @acoitemmask, @docnumber OUTPUT
		END
		---- check if exists in table
		if exists(select 1 from PMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@co and ACOItem=@docnumber)
			begin
			select @errmsg = 'Error occurred trying to get next ACO Item number. Enter manually.', @rcode = 1, @docnumber = ''
			goto bspexit
			end
		goto bspexit
		end
	end


---- check to see if the auto generate option is set to Project or Project and submittal Type
if @doccategory = 'SUBMIT'
	begin
	select @autogen = AutoGenSubNo from JCJM with (nolock) where JCCo=@pmco and Job=@project
	---- next submittal by project
	if @autogen = 'P' 
		begin
		select @next_doc = max(cast(FLOOR(Submittal) as numeric) + 1) 
		from PMSM with (nolock) where PMCo=@pmco and Project=@project
		AND SUBSTRING(LTRIM(Submittal),1,1) not in ('+', '-') 
		and isnumeric(Submittal) = 1
		end
	else
		---- if submittal type = 'STD_DUMMY' then no default type available, so use 1
		if @doctype = 'STD_DUMMY'
			begin
			select @next_doc = 1
			end
		else
			---- if not by project, assume by project and submittal type
			begin
			select @next_doc = max(cast(FLOOR(Submittal) as numeric) + 1) 
			from PMSM with (nolock) where PMCo=@pmco and Project=@project and SubmittalType=@doctype
			AND SUBSTRING(LTRIM(Submittal),1,1) not in ('+', '-') 
			and isnumeric(Submittal) = 1
  			end

	---- if null or zero set to 1
	if isnull(@next_doc,0) = 0 select @next_doc = 1
	---- skip if greater than 10 chars TK-12750
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
	BEGIN
		------ format @docnumber using appropiate value
		set @dummy = convert(varchar(10),@next_doc)
		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
	END
	---- check if exists in table
	if exists(select 1 from PMSM with (nolock) where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Submittal number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end


---- for document category = 'PCO' need to look in different tables depending
---- on whether getting next RFQ or next PCO or next PCO item
if @doccategory = 'PCO'
	begin
	---- RFQ's
	if @formname = 'PMRFQ'
		begin
		---- #132485
		select @autogenrfq = AutoGenRFQNo from JCJM with (nolock) where JCCo=@pmco and Job=@project
		if isnull(@autogenrfq,'') = '' select @autogenrfq = 'P'
		---- next RFQ by project
		if @autogenrfq = 'P' 
			begin
			select @next_doc = max(cast(FLOOR(RFQ) as numeric) + 1) 
			from PMRQ with (nolock) where PMCo=@pmco and Project=@project
			AND SUBSTRING(LTRIM(RFQ),1,1) not in ('+', '-') 
			and isnumeric(RFQ) = 1
			end
		---- next RFQ by project and PCO type
		if @autogenrfq = 'T'
			begin
			select @next_doc = max(cast(FLOOR(RFQ) as numeric) + 1) 
			from PMRQ with (nolock) where PMCo=@pmco and Project=@project and PCOType=@doctype
			AND SUBSTRING(LTRIM(RFQ),1,1) not in ('+', '-') 
			and isnumeric(RFQ) = 1
			end
		---- if not project or project and pco type, assume project, pco type, and pco
		if @autogenrfq not in ('P', 'T')
			begin
			select @next_doc = max(cast(FLOOR(RFQ) as numeric) + 1) 
			from PMRQ with (nolock) where PMCo=@pmco and Project=@project and PCOType=@doctype and PCO=@co 
			AND SUBSTRING(LTRIM(RFQ),1,1) not in ('+', '-') 
			and isnumeric(RFQ) = 1
  			end
		---- if null or zero set to 1
		if isnull(@next_doc,0) = 0 select @next_doc = 1
		---- skip if greater than 10 chars TK-12750
		IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
		BEGIN
			------ format @docnumber using appropiate value
			set @dummy = convert(varchar(10),@next_doc)
			exec @rcode = dbo.bspHQFormatMultiPart @dummy, @mask, @docnumber OUTPUT
		END
		---- check if exists in table
		if exists(select 1 from PMRQ with (nolock) where PMCo=@pmco and Project=@project and PCOType=@doctype and PCO=@co and RFQ=@docnumber)
			begin
			select @errmsg = 'Error occurred trying to get next RFQ number. Enter manually.', @rcode = 1, @docnumber = ''
			goto bspexit
			end
		goto bspexit
		end

	---- PCO's
	if @formname = 'PMPCOS'
		begin
		select @autogenpco = AutoGenPCONo from JCJM with (nolock) where JCCo=@pmco and Job=@project
		if isnull(@autogenpco,'') = '' select @autogenpco = 'P'
		--DC #140529  START
		---- next submittal by project
		if @autogenpco = 'P' 
			BEGIN			
			SELECT @keyid = max(KeyID)	--Get the key id for the last PCO
			FROM PMOP WITH (NOLOCK)
			WHERE PMCo=@pmco and Project=@project
			---- next submittal by project
			SELECT @next_doc = max(cast(FLOOR(PCO) as numeric) + 1) 
			FROM PMOP WITH (NOLOCK) 
			WHERE PMCo=@pmco and Project=@project
			----#141982
			AND SUBSTRING(LTRIM(PCO),1,1) not in ('+', '-') 
			and isnumeric(PCO) = 1																		
			END
		ELSE
			BEGIN
			SELECT @keyid = max(KeyID)
			FROM PMOP WITH (NOLOCK)
			WHERE PMCo=@pmco and Project=@project and PCOType=@doctype
			---- if not by project, assume by project and submittal type
			SELECT @next_doc = max(cast(FLOOR(PCO) as numeric) + 1) 
			FROM PMOP WITH (NOLOCK) 
			WHERE PMCo=@pmco and Project=@project and PCOType=@doctype
			----#141982
			AND SUBSTRING(LTRIM(PCO),1,1) not in ('+', '-') 
			and isnumeric(PCO) = 1																		
			END			
			
		IF ISNULL(@keyid,'') = ''
			BEGIN
			-- if null or zero set to 1
			IF isnull(@next_doc,0) = 0 SELECT @next_doc = 1
			---- skip if greater than 10 chars TK-12750
			IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
				BEGIN
					-- format @docnumber using appropiate value
					SET @dummy = convert(varchar(10),@next_doc)							
				END
			END		
		ELSE
			BEGIN			
			SELECT @pco = PCO
			FROM PMOP
			WHERE KeyID = @keyid

			----TK-08779
			IF isnumeric(@pco) = 1 AND PATINDEX('%[.]%', @pco) = 0
				BEGIN
					----Grab the next doc if last entered PCO is a number
					IF ISNUMERIC(@next_doc) = 1
					BEGIN
						---- skip if greater than 10 chars TK-12750
						IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
						BEGIN
							SELECT @dummy = CONVERT(VARCHAR(10), @next_doc)
						END	
					END	
					ELSE
					BEGIN
						---- skip if greater than 10 chars TK-12750
						IF LEN(CONVERT(VARCHAR(MAX), convert(bigint, @pco) + 1)) <= 10
						BEGIN
							SELECT @dummy = CONVERT(VARCHAR(10), convert(bigint, @pco) + 1)
						END
					END	
				END
			ELSE
				BEGIN
				SELECT @lastchar = PatIndex('%[^0-9]%', reverse(@pco))	--Position of the first non numeric character			
				IF @lastchar = 1 --  If the last character is an alpha, return next doc number
					BEGIN
					-- if null or zero set to 1
					IF isnull(@next_doc,0) = 0 SELECT @next_doc = 1
					---- skip if greater than 10 chars TK-12750
					IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
						BEGIN
						-- format @docnumber using appropiate value
						SET @dummy = convert(varchar(10),@next_doc)							
						END
					END
				ELSE
					BEGIN						
					SELECT @pconumberlength = len(right(@pco,@lastchar -1))  --the # of numbers at the end of the PCO
					SELECT @nextnum = convert(bigint, right(@pco,@lastchar -1)) + 1  --Add 1 to the PCO #					
					SELECT @nextnumastext = right('0000000000' + convert(varchar(10),@nextnum), case when @pconumberlength>len(@nextnum) then @pconumberlength else len(@nextnum) end) --Converts the next number to text and adds any leading zero's
					SELECT @beginpco = left(@pco,len(@pco) - @lastchar + 1)  --Gets the beginning 	
					---- skip if greater than 10 chars TK-12750
					IF LEN(CONVERT(VARCHAR(MAX), @beginpco + convert(varchar(10), @nextnumastext))) <= 10
						BEGIN
							SELECT @dummy = @beginpco + convert(varchar(10), @nextnumastext)  --combine PCO and next PCO #
						END
					END				
				END	
			END		
		--DC #140529  END						

		exec @rcode = dbo.bspHQFormatMultiPart @dummy, @pcomask, @docnumber output
		---- check if exists in table
		if exists(select 1 from PMOP with (nolock) where PMCo=@pmco and Project=@project and PCOType=@doctype and PCO=@docnumber)
			begin
			select @errmsg = 'Error occurred trying to get next PCO number. Enter manually.', @rcode = 1, @docnumber = ''
			goto bspexit
			end
		goto bspexit
		end

	---- PCO Items
	if @formname = 'PMPCOSITEMS'
		begin
		---- get next PCO item form PMCo, Project, PCOType, PCO
		select @next_doc = max(cast(FLOOR(PCOItem) as numeric) + 1) 
		from PMOI with (nolock) where PMCo=@pmco and Project=@project
		and PCOType=@doctype and PCO=@co
		AND SUBSTRING(LTRIM(PCOItem),1,1) not in ('+', '-') 
		and isnumeric(PCOItem) = 1
		---- if null or zero set to 1
		if isnull(@next_doc,0) = 0 select @next_doc = 1
		---- skip if greater than 10 chars TK-12750
		IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) <= 10
		BEGIN
			------ format @docnumber using appropiate value
			set @dummy = convert(varchar(10),@next_doc)
			exec @rcode = dbo.bspHQFormatMultiPart @dummy, @acoitemmask, @docnumber OUTPUT
		END
		---- check if exists in table
		if exists(select 1 from PMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@doctype and PCO=@co and PCOItem=@docnumber)
			begin
			select @errmsg = 'Error occurred trying to get next PCO Item number. Enter manually.', @rcode = 1, @docnumber = ''
			goto bspexit
			end
		goto bspexit
		end
	end


---- check to see if the auto generate option is set to Project or Project and meeting Type
if @doccategory = 'MTG'
	begin
	select @autogenmtg = AutoGenMTGNo from JCJM with (nolock) where JCCo=@pmco and Job=@project
	---- next submittal by project
	if @autogenmtg = 'P' 
		begin
		select @next_doc = max(Meeting) + 1
		from PMMM with (nolock) where PMCo=@pmco and Project=@project
		end
	else
		---- if not by project, assume by project and submittal type
		begin
		select @next_doc = max(Meeting) + 1
		from PMMM with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@doctype
  		end
	---- if null or zero set to 1
	if isnull(@next_doc,0) = 0 select @next_doc = 1
	---- check if exists in table
	IF LEN(CONVERT(VARCHAR(MAX), @next_doc)) > 6 
	OR exists(select 1 from PMMM with (nolock) where PMCo=@pmco and Project=@project and MeetingType=@doctype and Meeting=@next_doc)
		begin
		select @errmsg = 'Error occurred trying to get next Meeting number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	---- since meeting is a integer, just convert to varchar no formatting needed
	select @docnumber = convert(varchar(10), @next_doc)
	goto bspexit
	end

if @doccategory = 'BUDGETNO'
	begin
	select @next_doc = max(cast(FLOOR(BudgetNo) as numeric) + 1)
	from PMEH with (nolock) where PMCo=@pmco and Project=@project
	AND SUBSTRING(LTRIM(BudgetNo),1,1) not in ('+', '-') 
	and isnumeric(BudgetNo) = 1
	if @@rowcount = 0 or isnull(@next_doc,0) = 0 select @next_doc = 1
	---- since estimat is a varchar(10), just convert to varchar no formatting needed
	select @docnumber = convert(varchar(10), @next_doc)
	---- check if exists in table
	if exists(select 1 from PMEH with (nolock) where PMCo=@pmco and Project=@project and BudgetNo=@docnumber)
		begin
		select @errmsg = 'Error occurred trying to get next Budget number. Enter manually.', @rcode = 1, @docnumber = ''
		goto bspexit
		end
	goto bspexit
	end

bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextPMDocNum] TO [public]
GO
