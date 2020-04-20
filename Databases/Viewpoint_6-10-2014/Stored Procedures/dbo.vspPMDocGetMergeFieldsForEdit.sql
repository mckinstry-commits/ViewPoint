SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
CREATE  proc [dbo].[vspPMDocGetMergeFieldsForEdit]
/************************************************
 * Created By:	GF 02/15/2007
 * Modified By:	GF 03/10/2009 - issue #131183 - added TotalOrigTax for SUB and SUBITEM
 *				GF 10/30/2009 - issue #134090 - submittals CCList
 *				gf 12/21/2010 - ISSUE #142573 - INTENT TO BID CHANGES
 *				GF 01/14/2011 - issue #142924 change for PC templates
 *				AJW 11/14/2013 - TFS 67268 don't add duplicate table merge fields to list
 *
 *
 *
 * Build merge header list for use in word template edit
 *
 *
 * Pass:
 * @template		PM Document Template
 *
 *
 **************************************/
(@template varchar(40) = null, @fullfilename varchar(250) = null output, 
 @headerstring varchar(max) = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @templatetype varchar(10), @location varchar(10), @filename varchar(60),
		@path varchar(200), @joinstring varchar(max),
		@querystring varchar(max)

select @rcode = 0

if isnull(@template,'') = ''
	begin
	select @msg = 'Missing Document Template Name.', @rcode = 1
	goto bspexit
	end

---- get template info #134090
select @location=Location, @filename=FileName, @templatetype=TemplateType
from HQWD where TemplateName=@template
if @@rowcount = 0
	begin
	select @msg = 'Document Template Name not in file.', @rcode = 1
	goto bspexit
	end

---- get template path/filename
if isnull(@location,'') <> 'PMStandard'
	begin
	select @path=Path from HQWL where Location=@location
	if @@rowcount = 0
		begin
		select @msg = 'PM Location is missing.', @rcode = 1
		goto bspexit
		end
	end
else
	begin
	select @path = '\\Netdevel\Viewpoint Repository\Document Templates\Standard'
	end

select @fullfilename = isnull(@path,'') + '\' + isnull(@filename,'')

---- build header string and column string from HQWF for template
exec @rcode = dbo.bspHQWFMergeFieldBuild @template, @headerstring output, @querystring output, @msg output
if @rcode <> 0 goto bspexit

---- build join clause from HQWO for template type
exec @rcode = dbo.bspHQWDJoinClauseBuild @templatetype, 'N', 'Y', 'N', @joinstring output, @msg output
if @rcode <> 0 goto bspexit

---- there may be additional merge fields added to header string depending on document type
if @templatetype = 'PCO'
	begin
	select @headerstring = 'TotalAmount,' + @headerstring
	end

----#131183
if @templatetype = 'SUB'
	begin
	select @headerstring = 'TotalSubcontract, TotalOrigSL, TotalOrigTax, TotalCurrTax,' + @headerstring
	end

if @templatetype = 'SUBITEM'
	begin
	select @headerstring = 'TotalSubcontract, TotalOrigSL, TotalOrigTax, TotalCurrTax,' + @headerstring
	end

---- add the CClist to the headerstring #134090
---- #142924
if @templatetype not in ('SUB', 'SUBITEM', 'BIDNOT', 'BIDADD', 'BIDINTENT')
	begin
	select @headerstring = @headerstring + ',CCList'
	end


---- #142924 add comma to header string first
SET	@headerstring = @headerstring + ','

---- cte to load merge fields for intent to bid scopes
;
with IntentToBid_Scopes(MergeFieldName) AS
	(
	--don't add duplicate mergefields into the headerstring.  Word flags them with a number suffix which messes up merge
		select p.MergeFieldName
		from dbo.HQWF p
		WHERE p.TemplateName = @template AND WordTableYN = 'Y' AND NOT EXISTS(
		select 1 from bHQWF f 
		where f.TemplateName = p.TemplateName and f.MergeFieldName = p.MergeFieldName and f.WordTableYN = 'N')
	)

	SELECT	@headerstring = @headerstring + MergeFieldName + ','
	FROM IntentToBid_Scopes WHERE MergeFieldName IS NOT NULL
;

---- remove last semi-colon
if ISNULL(@headerstring,'') <> ''
	begin
	select @headerstring = left(@headerstring, len(@headerstring)- 1) -- remove last semi-colon
	end

	
	


bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocGetMergeFieldsForEdit] TO [public]
GO
