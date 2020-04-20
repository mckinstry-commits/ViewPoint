SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspHQWFMergeFieldAdd]
/*************************************
 * Created By:	GF 01/10/2002
 * Modified By:	GF 01/20/2004 - issue #18841 - added word table flag to distingish main vs table query.
 *				RM 03/26/04 - Issue# 23061 - Added IsNulls
 *
 * Adds a merge field to template. Called from PMDocTemplates.
 *
 *
 * Pass:
 *	TemplateName
 *	DocObject
 *	ColumnName
 *
 * Success returns:
 *	0 and msg
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@templatename varchar(40), @docobject varchar(30), @columnname varchar(30),
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @seq int, @templatetype varchar(10), @mergefieldname varchar(30), 
   		@mergeorder smallint, @wordtable bYN

select @rcode = 0

---- validate template, get template type
select @templatetype=TemplateType from bHQWD where TemplateName=@templatename
if @@rowcount = 0
   	begin
   	select @msg = 'Template not found - ' + isnull(@templatename,'') + ' not in HQWD.', @rcode=1
   	goto bspexit
   	end

---- validate docobject, get word table flag
select @wordtable=WordTable from bHQWO where TemplateType=@templatetype and DocObject=@docobject
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid document object for this template', @rcode = 1
   	goto bspexit
   	end

---- validate unique merge field name
select @mergefieldname=MergeFieldName
from bHQWF with (nolock) where TemplateName=@templatename and MergeFieldName=@columnname
if @@rowcount = 0
   	begin
	---- get next sequence
   	select @seq=isnull(max(Seq),0) + 1
   	from bHQWF with (nolock) where TemplateName=@templatename
   	---- get next merge order
   	select @mergeorder=isnull(max(MergeOrder),0) + 1
   	from bHQWF with (nolock) where TemplateName=@templatename and WordTableYN=@wordtable
   	---- add column to bHQWF
   	insert into bHQWF (TemplateName, Seq, DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN)
   	select @templatename, @seq, @docobject, @columnname, @columnname, @mergeorder, @wordtable
   	end


bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWFMergeFieldAdd] TO [public]
GO
