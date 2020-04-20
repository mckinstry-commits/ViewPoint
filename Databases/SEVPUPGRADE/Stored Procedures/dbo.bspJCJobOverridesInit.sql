SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************/
CREATE PROCEDURE [dbo].[bspJCJobOverridesInit]
/**********************************************************************
* Created By:	DANF 02/22/2005
* Modified by:	DANF 08/09/2005 - Issue 29529 Fix Company Number
*				DANF 08/08/2006 - Add the ability to copy notes form the prior month.
*				GF 02/11/2008 - issue #127056 changed to use view for JCOP when updating. Only JCOP needed to be changed.
*
*
* Usage: Used to ititialize overrides from the file menu option of the JC Overrides Form.
*
* Input:
* @JCCo - JCCo
* @Month - Month
* @ShowSoftClose - ShowSoftClose
* @IncludeNotes
*
* If Cost Previous Override is not zero Then set Cost New Projection to Cost Previous Override
*
* Output:
* @rcode
* @errmsg
*
*
**********************************************************************/
(@JCCo bCompany = null, @Month bMonth = null, @ShowSoftClose char(1) = null,
 @IncludeNotes char(1) = null, @errmsg varchar(255) = '' output)
as

declare @rcode int, @separator varchar(30)

select @rcode = 0, @separator = char(013) + char(010), @errmsg = '-'

if isnull(@ShowSoftClose,'') <> 'Y' and isnull(@ShowSoftClose,'') <> 'N' 
	begin
	select @rcode=1, @errmsg='Invalid Show Soft Close Flag. Must be Y or N.'
	goto bspexit
	end

if isnull(@Month,'')=''
	begin
	select @rcode=1, @errmsg='Missing Month.'
	goto bspexit
	end

if isnull(@JCCo,'')=''
	begin
	select @rcode=1, @errmsg='Missing Job Cost Company.'
	goto bspexit
	end

if isnull(@IncludeNotes,'')=''
	begin
	select @rcode=1, @errmsg='Missing Include Note Option.'
	goto bspexit
	end


if @ShowSoftClose = 'Y'
	begin
	---- update JCOP
	update r set ProjCost=isnull((select o.ProjCost from dbo.JCOP o where o.JCCo = r.JCCo
				and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month)),0)
	from dbo.JCOP r with (nolock)
	join dbo.JCJM n with (nolock) on n.JCCo=r.JCCo and n.Job=r.Job
	where r.JCCo=@JCCo and r.Month = @Month and n.JobStatus in (1,2)
	and isnull((select o.ProjCost from dbo.JCOP o with (nolock) where o.JCCo = r.JCCo
				and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month)),0)< > 0
	---- include notes
	if @IncludeNotes = 'Y'
		begin
		update r set Notes=(select o.Notes from dbo.JCOP o where o.JCCo = r.JCCo
					and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month))
		from dbo.JCOP r with (nolock)
		join dbo.JCJM n with (nolock) on n.JCCo=r.JCCo and n.Job=r.Job
		where r.JCCo=@JCCo and r.Month = @Month and n.JobStatus in (1,2)
		and exists (select o.Notes from dbo.JCOP o with (nolock) where o.JCCo = r.JCCo
					and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month))
		end
	end


if @ShowSoftClose = 'N'
	begin
	---- update JCOP
   	update r set ProjCost=isnull((select o.ProjCost from dbo.JCOP o where o.JCCo = r.JCCo
				and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month)),0)
   	from dbo.JCOP r
   	join dbo.JCJM n on n.JCCo=r.JCCo and n.Job=r.Job
   	where r.JCCo=@JCCo and r.Month = @Month and n.JobStatus = 1 
	and isnull((select o.ProjCost from dbo.JCOP o where o.JCCo = r.JCCo
			and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month)),0) <> 0
	---- include notes
	if @IncludeNotes = 'Y'
		begin
		update r set Notes=(select o.Notes from dbo.JCOP o with (nolock) where o.JCCo = r.JCCo
				and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month))
		from dbo.JCOP r with (nolock)
		join dbo.JCJM n with (nolock) on n.JCCo=r.JCCo and n.Job=r.Job
		where r.JCCo=@JCCo and r.Month = @Month and n.JobStatus = 1
		and exists(select o.Notes from dbo.JCOP o with (nolock) where o.JCCo = r.JCCo
				and o.Job=r.Job and o.Month = DATEADD(Month, -1, @Month))
		end
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJobOverridesInit] TO [public]
GO
