SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE PROCEDURE [dbo].[bspJCContractOverridesInit]
/**********************************************************************
* Created By:	DANF 02/22/2005
* Modified by:	DANF 08/09/2005 - Issue 29529 Fix Company Number
*				DANF 08/08/2006 - Add the ability to copy notes form the prior month.
*				GF 02/11/2008 - issue #127056 changed to use view for JCOR when updating. Only JCOR needed to be changed.
*
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
* If Revenue Previous Override is not zero Then set Revenue New Projection to Revenue Previous Override
*
* Output:
* @rcode
* @errmsg
*
*
**********************************************************************/
(@JCCo bCompany = null, @Month bMonth = null, @ShowSoftClose char(1),
 @IncludeNotes char(1) = null, @errmsg varchar(255) = '' output)
as

declare @rcode int, @separator varchar(30)

select @rcode = 0, @separator = char(013) + char(010), @errmsg = '-'

if isnull(@ShowSoftClose,'')<>'Y' and isnull(@ShowSoftClose,'')<>'N' 
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
	---- update JCOR
	update r set RevCost=isnull((select o.RevCost from dbo.JCOR o where o.JCCo = r.JCCo
			and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month)),0)
	from dbo.JCOR r
	join dbo.JCCM m on m.JCCo=r.JCCo and m.Contract=r.Contract
	where r.JCCo=@JCCo and r.Month = @Month and m.ContractStatus in (1,2)
	and isnull((select o.RevCost from dbo.JCOR o where o.JCCo = r.JCCo
			and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month)),0)<>0
	if @IncludeNotes = 'Y'
		begin
		update r set Notes=(select o.Notes from dbo.JCOR o where o.JCCo = r.JCCo
				and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month))
		from dbo.JCOR r
		join dbo.JCCM m on m.JCCo=r.JCCo and m.Contract=r.Contract
		where r.JCCo=@JCCo and r.Month = @Month and m.ContractStatus in (1,2)
		and exists (select o.Notes from dbo.JCOR o where o.JCCo = r.JCCo
				and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month))
		end
	end


if @ShowSoftClose = 'N'
	begin
	update r set RevCost=isnull((select o.RevCost from dbo.JCOR o where o.JCCo = r.JCCo
			and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month)),0)
	from dbo.JCOR r
	join dbo.JCCM m on m.JCCo=r.JCCo and m.Contract=r.Contract
	where r.JCCo=@JCCo and r.Month = @Month and m.ContractStatus = 1
	and isnull((select o.RevCost from dbo.JCOR o where o.JCCo = r.JCCo
			and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month)),0)<>0
	if @IncludeNotes = 'Y'
		begin
		update r set Notes=(select o.Notes from dbo.JCOR o where o.JCCo = r.JCCo
				and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month))
		from dbo.JCOR r
		join dbo.JCCM m on m.JCCo=r.JCCo and m.Contract=r.Contract
		where r.JCCo=@JCCo and r.Month = @Month and m.ContractStatus = 1
		and exists (select o.Notes from dbo.JCOR o where o.JCCo = r.JCCo
				and o.Contract=r.Contract and o.Month = DATEADD(Month, -1, @Month))
		end
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCContractOverridesInit] TO [public]
GO
