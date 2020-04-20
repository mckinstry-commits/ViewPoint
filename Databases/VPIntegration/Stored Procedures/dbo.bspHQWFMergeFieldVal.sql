SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[bspHQWFMergeFieldVal]
/***********************************************************
 * CREATED By:	GF 01/08/2002
 * MODIFIED By:	GF 02/09/2004 - issue #18841 - added word table flag to distingish main vs table query.
 *				GF 03/19/2004 - issue #24109 - need to check for invalid characters in merge field name
 *				RM 03/26/04 - Issue# 23061 - Added IsNulls
 *
 * USAGE:
 *   validates HQ Document Template merge field name uniqueness for template name
 *
 *	PASS:
 *  TemplateName	Document Template Name
 *	Seq				Document Template Sequence
 *	MergeFieldName	Document Template merge field name to be validated
 *
 *	RETURNS:
 *  ErrMsg if any
 * 
 * OUTPUT PARAMETERS
 *   @msg     Error message if invalid, 
 * RETURN VALUE
 *   0 Success
 *   1 fail
 *****************************************************/ 
(@templatename varchar(40), @seq int, @mergefieldname varchar(30), @wordtable bYN,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0, @validcnt = 0

if isnull(@seq,0) = 0
	begin
	select @validcnt=count(*) from bHQWF
	where TemplateName=@templatename and MergeFieldName=@mergefieldname and WordTableYN=@wordtable
	if @validcnt <> 0
		begin
		select @msg = 'Merge Field Name is already in use for this template. Must be unique.', @rcode = 1
		goto bspexit
		end
	end
else
	begin
	select @validcnt=count(*) from bHQWF
	where TemplateName=@templatename and MergeFieldName=@mergefieldname and WordTableYN=@wordtable and Seq<>@seq
	if @validcnt <> 0
		begin
		select @msg = 'Merge Field Name is already in use for this template. Must be unique.', @rcode = 1
		goto bspexit
		end
	end

if CHARINDEX('''', ltrim(rtrim(@mergefieldname)), 1) > 0
   	begin
   	select @msg = 'Invalid character: (' + char(39) + ') in merge field name.', @rcode = 1
   	goto bspexit
   	end

if CHARINDEX('%', ltrim(rtrim(@mergefieldname)), 1) > 0
   	begin
   	select @msg = 'Invalid character: (%) in merge field name.', @rcode = 1
   	goto bspexit
   	end

if CHARINDEX(' ', ltrim(rtrim(@mergefieldname)), 1) > 0
   	begin
   	select @msg = 'Invalid character: (Space) in merge field name.', @rcode = 1
   	goto bspexit
   	end

if CHARINDEX('[', ltrim(rtrim(@mergefieldname)), 1) > 0
   	begin
   	select @msg = 'Invalid character: ([) in merge field name.', @rcode = 1
   	goto bspexit
   	end

if CHARINDEX(']', ltrim(rtrim(@mergefieldname)), 1) > 0
   	begin
   	select @msg = 'Invalid character: (]) in merge field name.', @rcode = 1
   	goto bspexit
   	end

if PATINDEX('%[!@#$^&*()+{}:;<>?/]%', @mergefieldname) > 0
   	begin
   	select @msg = 'Invalid character in merge field name. Use alpha-numeric only, no special characters.', @rcode = 1
   	goto bspexit
   	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWFMergeFieldVal] TO [public]
GO
