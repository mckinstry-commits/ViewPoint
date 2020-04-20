SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[vspHQPurgeMasterAudit]
/***********************************************************
* Created: AL 2/25/07
* Modified:	GG 03/01/07 - add parameter check, nolocks, cleanup
*			AL 9/12/17 - no longer removes records WHERE the Co IS null
*  
* USAGE:
* 	Counts or deleted Master Audit entries in bHQMA based on 
*	input parameters.  If nothing found to purge error message is returned.
*
* INPUT PARAMETERS
*   @co				Current company to restrict purge
*	@date			Purge through date
*	@purgeby		'A'=all, 'T'=table, 'M'=module (except DD)
*	@modtable		Module or Table name - w/o the 'b' or 'v'
*	@countOrPurge	Flag to count or purge audit entries
*
* OUTPUT PARAMETERS
*   @msg			warning or error message
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
   
   (@co bCompany = null, @date bDate = null, @purgeby varchar(1) = null,
	@modtable varchar(10) = null, @countOrPurge varchar(10), @msg varchar(250) output)
as
   
set nocount on
declare @rcode int, @validcnt int
select @rcode = 0

if @co is null
	begin
	select @msg = 'Missing Company #!', @rcode = 1
	goto vspexit
	end
if @date is null
	begin
	select @msg = 'Missing Date!', @rcode = 1
	goto vspexit
	end
if isnull(@purgeby,'') not in ('A','T','M')
	begin
	select @msg = 'Invalid Purge Option, must be ''A'' = All,''T'' = Table, or ''M'' = Module!', @rcode = 1
	goto vspexit
	end
--audit entries for DD should not be purged
if (@modtable = 'bDD' or @modtable = 'vDD' or @modtable like 'vDD%' or @modtable like 'bDD%' or @modtable like 'DD%' )
	begin
	select @msg = 'Cannot purge DD audit entries', @rcode = 1
	goto vspexit	
	end

-- count the records to be purged
if @countOrPurge = 'count' 
	-- get the count to purge
	begin
	if @purgeby = 'T'       --purge by table
		begin
		select @validcnt = Count(*) from dbo.bHQMA (nolock)
		where Co = @co and substring(TableName,2,len(TableName)) = @modtable
			and convert(int,DATEDIFF(day, @date, [DateTime]))<=0
		end
	if @purgeby = 'M'       --purge by module
		begin
		select @validcnt = Count(*) from dbo.bHQMA (nolock)
		where Co = @co and substring(TableName,2,2) = @modtable
			and convert(int,DATEDIFF(day, @date, [DateTime]))<=0
		end
	if @purgeby = 'A'           --purge all entries
		begin
		select @validcnt = Count(*) from dbo.bHQMA (nolock)
		where Co = @co and convert(int,DATEDIFF(day, @date, [DateTime]))<=0
		end

	if @validcnt > 0
		begin
		select @msg = 'You are about to purge ' + convert(varchar(10), @validcnt) + ' records!' + char(13)
					   + ' Do you wish to continue?', @rcode = 0
		end
	else
		begin
		select @msg = 'No records found to purge.', @rcode = 1
		end
	end 

-- remove audit records
if @countOrPurge = 'purge' 
	begin
	if @purgeby = 'A'             --purge all entries
		begin
		delete dbo.bHQMA
		where Co = @co and convert(int,DATEDIFF(day, @date, [DateTime]))<=0
		end
   if @purgeby = 'T'              --purge by table name
		begin
		delete dbo.bHQMA
		where Co = @co and substring(TableName,2,len(TableName)) = @modtable
			and convert(int,DATEDIFF(day, @date, [DateTime]))<=0
		end
   if @purgeby = 'M'           --purge by module
       begin
       delete from bHQMA where Co = @co and substring(TableName,2,2) = @modtable
			and convert(int,DATEDIFF(day, @date, [DateTime]))<=0
       end
   end 
  
vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQPurgeMasterAudit] TO [public]
GO
