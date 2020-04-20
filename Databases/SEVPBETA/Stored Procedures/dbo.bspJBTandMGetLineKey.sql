SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMGetLineKey    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMGetLineKey]
   /***********************************************************
   * CREATED BY	: kb 5/17/00
   * MODIFIED BY	: kb 5/15/01 - changed datatype of @item from bItem to bContractItem
   *   	kb 2/8/2 - issue #16068
   *		TJL 07/03/02 - Issue #17701
   *		TJL 10/14/02 - Issue #18982, Detail Addons fail to initialize for Non-Contract Bills
   *		TJL 10/16/02 - Issue #19027, Correct for ANSI NULLs
   *		TJL 07/08/03 - Issue #21737, Correct Sort by Phase and by Job
   *		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
   *		TJL 12/09/03 - Issue #20471, Direct 'A' Type values to a specific JCJP Contract Item
   *
   * USED IN:
   *
   * USAGE:
   *
   * INPUT PARAMETERS
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   (@co bCompany, @phasegroup bGroup = null, @phase bPhase = null,
   	@job bJob = null, @item bContractItem = null, @template varchar(10), @templateseq int,
   	@postdate bDate = null, @actualdate bDate = null, @groupnum int,
   	@processtots bYN, @linekey varchar(100) output, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @spaces varchar(20), @sortorder char(1), @dateyear varchar(4),
   	@datemonth varchar(2), @dateday varchar(2)
   
   select @rcode = 0, @spaces = '                    '
   
   select @sortorder = SortOrder 
   from bJBTM with (nolock) 
   where JBCo = @co and Template = @template
   
   select @dateyear = case @sortorder 
   		when 'A' then convert(char(4),datepart(yyyy,@actualdate))  
   		when 'D' then convert(char(4),datepart(yyyy,@postdate)) end,
   	@datemonth = case @sortorder 
   		when 'A' then datepart(mm,@actualdate)
           when 'D' then datepart(mm,@postdate) end,
   	@dateday= case @sortorder 
   		when 'A' then datepart(dd,@actualdate)
           when 'D' then datepart(dd,@postdate) end
   
   if len(@datemonth) <2 select @datemonth ='0' + @datemonth
   if len(@dateday) <2 select @dateday ='0' + @dateday
   
   select @linekey =  case @sortorder
           when 'D' then case when @processtots = 'Y' then space(8) else
   			isnull(@dateyear, '') + isnull(@datemonth, '') + isnull(@dateday, '') end
   		when 'A' then case when @processtots = 'Y' then space(8) else
   			isnull(@dateyear, '') + isnull(@datemonth, '') + isnull(@dateday, '') end
   		when 'P' then convert(varchar(20),isnull(@phase,'')) + space(20-datalength(isnull(@phase,'')))
   		when 'J' then convert(varchar(10),isnull(@job,'')) + space(10-datalength(isnull(@job,''))) +
   			convert(varchar(20),isnull(@phase,'')) + space(20-datalength(isnull(@phase,'')))
           else '' end +
   			space(16-datalength(isnull(@item,0))) + convert(char(16),isnull(@item,0)) +
           	space(10-datalength(convert(varchar(10),@templateseq))) + convert(varchar(10),@templateseq)
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMGetLineKey] TO [public]
GO
