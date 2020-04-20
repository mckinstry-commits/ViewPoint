SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************/
CREATE proc [dbo].[vspBITargetCopy]
/***********************************************************
 * CREATED BY: HH 12/21/12 TK-20369
 * MODIFIED BY:
 *
 * USAGE: This SP is used to copy BI Operational Targets
 *		  vBITargetHeader entries with its related tables vBITargetDetail and vBITargetBudget
 *
 * an error is returned if any of the following occurs
 * no source target passed, no destination target passed
 *
 * INPUT PARAMETERS
 *   BICo   			BI Company
 *   SourceTarget  		BI Operational Target to be copied
 *   DestinationTarget	BI Operational Target to be copied to
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *****************************************************/
(@BICo bCompany = 0, @SourceTarget varchar(50) = null, @DestinationTarget varchar(50) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0 

if @BICo is null
    	begin
    	select @msg = 'Missing BI Company.', @rcode = 1
    	goto bspexit
    	end

if @SourceTarget is null or @SourceTarget = ''
    	begin
    	select @msg = 'Missing Source Target.', @rcode = 1
    	goto bspexit
    	end

if @DestinationTarget is null or @DestinationTarget = ''
   	begin
   	select @msg = 'Missing Destination Target.', @rcode = 1
   	goto bspexit
   	end
   
-- check existence
if not exists(select * from BITargetHeader where BICo = @BICo and TargetName = @SourceTarget)
	begin
	select @msg = 'Source Target ' + @SourceTarget + ' does not exists.', @rcode = 1
   	goto bspexit
	end
	
if exists(select * from BITargetHeader where BICo = @BICo and TargetName = @DestinationTarget)
	begin
	select @msg = 'Destination Target ' + @DestinationTarget + ' already exists.', @rcode = 1
   	goto bspexit
	end	

-- copy process
begin try

insert into BITargetHeader
		(BICo, TargetName,			[Description], TargetType, GroupingLevel, GroupingValue, GroupingAll, FilterField, FilterValue, FilterAll, BegDate, EndDate, Period, PRGroup, QueryName)
select	 BICo, @DestinationTarget,  [Description], TargetType, GroupingLevel, GroupingValue, GroupingAll, FilterField, FilterValue, FilterAll, BegDate, EndDate, Period, PRGroup, QueryName
from BITargetHeader
where BICo = @BICo 
		and TargetName = @SourceTarget;

insert into BITargetDetail
		(BICo, TargetName,			Revision,	TargetLevel)
select	 BICo, @DestinationTarget,	Revision,	TargetLevel
from BITargetDetail
where BICo = @BICo 
		and TargetName = @SourceTarget
order by Revision;

insert into BITargetBudget
		(BICo, TargetName,			Revision,	TargetDate, Goal)
select	 BICo, @DestinationTarget,	Revision,	TargetDate, Goal
from BITargetBudget
where BICo = @BICo 
		and TargetName = @SourceTarget
order by Revision, TargetDate;


end try
begin catch
	select @msg = 'dbo.vspBITargetCopy failed', @rcode = 1
	return @rcode
end catch

bspexit:
	if @rcode = 0 
   		select @msg = 'BI Operational Target ' + @SourceTarget + ' successfully copied to ' + @DestinationTarget + '.'
   
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspBITargetCopy] TO [public]
GO
