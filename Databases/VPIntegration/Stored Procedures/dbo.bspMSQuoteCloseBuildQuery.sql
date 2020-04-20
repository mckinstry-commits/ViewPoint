SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************/
CREATE  proc [dbo].[bspMSQuoteCloseBuildQuery]
/****************************************************************************
 * Created By:   GF 09/19/2000
 * Modified By:  GF 04/09/2001 - fix to active flag in grid
 *				 GF 12/12/2005 - change for 6.x - return resultset instead of query string.
 *
 * USAGE:
 * 	Builds a query statement to populate grid in MSQuoteClose form.
 *
 * INPUT PARAMETERS:
 *   MS Company, RestrictByType, QuoteType, CustGroup, Customer, CustJob, CustPO,
 *   JCCo, Job, INCo, ToLoc, ExpiredDate, ActiveOnly
 *	Phase, Phase Group
 *
 * OUTPUT PARAMETERS:
 *   Quote, Purchaser, Description, Quote Date, Expired Date, Active Flag
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@msco bCompany = null, @restrictbytype bYN = null, @quotetype char(1) = null,
 @custgroup bGroup = null, @customer bCustomer = null, @custjob varchar(20) = null,
 @custpo varchar(20) = null, @jcco bCompany = null, @job bJob = null, @inco bCompany = null,
 @toloc bLoc = null, @expdate bDate = null, @activeonly bYN = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sql varchar(2000)

select @rcode = 0

select @sql = ' select ''Close'' = ''N'', ''Purge'' = ''N'', '
select @sql = @sql + '''Failed'' = ''No'', '
select @sql = @sql + 'a.Quote, ''Purchaser'' = case a.QuoteType'
select @sql = @sql + ' when ''C'' then (select b.Name from ARCM b where b.CustGroup=a.CustGroup and b.Customer=a.Customer)'
select @sql = @sql + ' when ''J'' then (select c.Description from JCJM c where c.JCCo=a.JCCo and c.Job=a.Job)'
select @sql = @sql + ' when ''I'' then (select d.Description from INLM d where d.INCo=a.INCo and d.Loc=a.Loc)'
select @sql = @sql + ' else '''' end,'
select @sql = @sql + ' a.Description,a.QuoteDate,a.ExpDate, '
select @sql = @sql + '''Active'' = case a.Active when ''Y'' then ''Yes'' else ''No'' end, '
select @sql = @sql + '''ErrorMessage'' = '''' from MSQH a'
select @sql = @sql + ' where a.MSCo=' + convert(varchar(3),@msco)

-- -- -- add form where clause restrictions
if @activeonly = 'Y'
	begin
	select @sql = @sql + ' and a.Active= ' + CHAR(39) + 'Y' + CHAR(39)
	end

if @expdate is not null
      begin
      select @sql = @sql + ' and a.ExpDate<= ' + CHAR(39) + convert(varchar(30),@expdate,101) + CHAR(39)
      end

if @restrictbytype = 'Y'
      begin
      select @sql = @sql + ' and a.QuoteType= ' + CHAR(39) + @quotetype + CHAR(39)
      if @quotetype = 'C'
          begin
          if @customer is not null
              begin
              select @sql = @sql + ' and a.CustGroup= ' + convert(varchar(3),@custgroup)
              select @sql = @sql + ' and a.Customer= ' + convert(varchar(8),@customer)
              end
          if @custjob is not null
              begin
              select @sql = @sql + ' and a.CustJob= ' + CHAR(39) + @custjob + CHAR(39)
              end
          if @custpo is not null
              begin
              select @sql = @sql + ' and a.CustPO= ' + CHAR(39) + @custpo + CHAR(39)
              end
          end
      if @quotetype = 'J'
          begin
          if @jcco is not null
              begin
              select @sql = @sql + ' and a.JCCo= ' + convert(varchar(3),@jcco)
              end
          if @job is not null
              begin
              select @sql = @sql + ' and a.Job= ' + CHAR(39) + @job + CHAR(39)
              end
          end
      if @quotetype = 'I'
          begin
          if @inco is not null
              begin
              select @sql = @sql + ' and a.INCo= ' + convert(varchar(3),@inco)
              end
          if @toloc is not null
              begin
              select @sql = @sql + ' and a.Loc= ' + CHAR(39) + @toloc + CHAR(39)
              end
          end
      end

exec (@sql)


-- -- -- bspexit:
-- -- -- 	-- -- -- if @rcode = 0 select @msg = @sql
-- -- -- 	-- -- -- if @rcode<>0 select @msg=isnull(@msg,'')
-- -- -- 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQuoteCloseBuildQuery] TO [public]
GO
