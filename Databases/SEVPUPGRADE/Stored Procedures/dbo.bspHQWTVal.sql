SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQWTVal]
/*************************************
 * CREATED BY    : GF 11/29/2001
 * LAST MODIFIED : RM 03/26/04 - Issue# 23061 - Added IsNulls
 *
 * validates HQ Document Template Types
 *
 * Pass:
 * HQ Document Type
 * 
 * Returns:
 * Description
 *
 * Success returns:
 * Joins		Template Joins string
 * Next_Alias	Next default alias for template type
 * 0 and Description from HQWT
 *
 * Error returns:
 *	1 and error message
 *
 **************************************/
(@templatetype varchar(10), @wordtable bYN = 'N' output, @joins varchar(2000) = null output,
 @next_alias varchar(2) = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @alias varchar(2), @lastpart varchar(1), @chars varchar(26), @pos bigint

select @rcode = 0, @chars = 'abcdefghijklmnopqrstuvwxyz'

if @templatetype is null
   	begin
   	select @msg = 'Missing document template type!', @rcode = 1
   	goto bspexit
   	end

---- validate template type
select @msg = Description, @wordtable=WordTable
from dbo.HQWT with (nolock) where TemplateType = @templatetype
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Document Template Type', @rcode = 1
   	goto bspexit
   	end

---- generate a join string with all document objects assigned to this template type
---- main document object
select @joins = 'from ' + a.ObjectTable + ' ' + a.Alias + ' with (nolock)' + char(13) + char(10)
from HQWO a where a.TemplateType=@templatetype and a.JoinOrder=0
---- additional main document
select @joins = @joins + 'join ' + a.ObjectTable + ' ' + a.Alias + ' with (nolock) on ' + a.JoinClause + char(13) + char(10)
from HQWO a where a.TemplateType=@templatetype AND  a.JoinOrder=1
------ now add all other joins
select @joins = @joins + 'left join ' + a.ObjectTable + ' ' + a.Alias + ' with (nolock) on ' + a.JoinClause + char(13) + char(10)
from HQWO a where a.TemplateType=@templatetype AND a.JoinOrder>1
order by a.TemplateType, a.JoinOrder

---- try to get next default alias
---- have used up most single characters so lets start with length 2
if not exists(select a.Alias from HQWO a where a.TemplateType=@templatetype and datalength(a.Alias) > 1)
	begin
	select @next_alias = 'aa'
	goto bspexit
	end

select @alias=max(Alias) from HQWO where TemplateType=@templatetype and datalength(Alias) > 1
---- parse second character and get next alpha
select @lastpart = substring(@alias,2,1)
select @pos = charindex(@lastpart,@chars)
select @next_alias = null
if @pos > 0 select @next_alias = substring(@alias,1,1) + substring(@chars,@pos+1,1)




bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWTVal] TO [public]
GO
