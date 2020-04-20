SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE proc [dbo].[bspHQWFInitMergeFields]
/*********************************************
 * Created By:   GF 01/09/2002
 * Modified By:  GF 02/27/2003 - issue #20503 word table added to HQWD update from source when initializing.
 *				RM 03/26/04 - Issue# 23061 - Added IsNulls
 *				GF 07/07/2004 - issue #25031 - initializing word table fields not adding all word table fields.
 *
 * Initializes merge fields for a template from a templat. Called from PMDocTemplates.
 *
 *
 * Pass:
 *	InitFromTemplate
 *	InitToTemplate
 *	TemplateType
 *
 * Success returns:
 *	0 and msg
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@initfromtemplate varchar(40), @inittotemplate varchar(40), @templatetype varchar(10),
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int,  @seq int, @wordtable bYN, @opencursor int,
   		@docobject varchar(30), @columnname varchar(60), @mergefieldname varchar(30),
   		@mergeorder smallint, @wordtableyn bYN, @format varchar(30)

select @rcode = 0, @opencursor = 0

if isnull(@initfromtemplate,'') = ''
   	begin
   	select @msg = 'Missing Initialize from template', @rcode = 1
   	goto bspexit
   	end

if isnull(@inittotemplate,'') = ''
   	begin
   	select @msg = 'Missing Initialize to template', @rcode = 1
   	goto bspexit
   	end

---- get word table flag from HQWT for valid template type
select @wordtable=WordTable from bHQWT where TemplateType=@templatetype
if @@rowcount = 0
   	begin
   	select @msg = 'Missing Initialize Template Type', @rcode = 1
   	goto bspexit
   	end

---- validate source template
select @validcnt = count(*) from bHQWD with (nolock) where TemplateName = @initfromtemplate
if @validcnt = 0
   	begin
   	select @msg = 'Initialize from template - ' + isnull(@initfromtemplate,'') + ' not in HQWD.', @rcode=1
   	goto bspexit
   	end

-- validate destination template
select @validcnt = count(*) from bHQWD with (nolock) where TemplateName=@inittotemplate
if @validcnt = 0
   	begin
   	select @msg = 'Initialize to template - ' + isnull(@inittotemplate,'') + ' not in HQWD.', @rcode=1
   	goto bspexit
   	end

---- if the template type does not have word tables and merge fields exist in HQWF exit SP
if @wordtable = 'N'
   	begin
   	if exists(select * from bHQWF where TemplateName = @inittotemplate)
   		goto bspexit
   	else
   		begin
   		---- initialize merge fields from @initfromtemplate into @inittotemplate
   		insert into bHQWF (TemplateName, Seq, DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN, Format)
   		select @inittotemplate, a.Seq, a.DocObject, a.ColumnName, a.MergeFieldName, a.MergeOrder, a.WordTableYN, a.Format
   		from bHQWF a where a.TemplateName=@initfromtemplate
   		and not exists(select b.MergeOrder from bHQWF b with (nolock) where b.TemplateName=@inittotemplate and b.Seq=a.Seq)
   		and not exists(select c.MergeOrder from bHQWF c with (nolock) where c.TemplateName=@inittotemplate
   				 		and c.MergeFieldName=a.MergeFieldName)
   		goto bspexit
   		end
   	end


---- if the template type has word tables and merge fields exist in HQWF then only insert word table merge fields
---- create a cursor to process JC Change Order detail (vJCAC)
declare bcHQWF cursor LOCAL FAST_FORWARD
for select DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN, Format
from bHQWF where TemplateName=@initfromtemplate
Order By TemplateName, Seq

---- open cursor
open bcHQWF
select @opencursor = 1

---- loop through bcHQWF cursor
HQWF_loop:
fetch next from bcHQWF into @docobject, @columnname, @mergefieldname, @mergeorder, @wordtableyn, @format
if @@fetch_status <> 0 goto HQWF_end

---- get next HQWF seq
select @seq=1
select @seq=isnull(Max(Seq),0)+1
from bHQWF where TemplateName = @inittotemplate

---- initialize word table merge fields from @initfromtemplate into @inittotemplate
if not exists(select * from bHQWF where TemplateName=@inittotemplate and DocObject=@docobject 
   							and ColumnName=@columnname and MergeFieldName=@mergefieldname)
   	begin
   	insert into bHQWF (TemplateName, Seq, DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN, Format)
   	select @inittotemplate, @seq, @docobject, @columnname, @mergefieldname, @mergeorder, @wordtableyn, @format
   	end


goto HQWF_loop


HQWF_end:
   	if @opencursor = 1
       	begin
       	close bcHQWF
       	deallocate bcHQWF
       	select @opencursor = 0
       	end




bspexit:
	if @opencursor = 1
       	begin
       	close bcHQWF
       	deallocate bcHQWF
       	select @opencursor = 0
       	end
   
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWFInitMergeFields] TO [public]
GO
