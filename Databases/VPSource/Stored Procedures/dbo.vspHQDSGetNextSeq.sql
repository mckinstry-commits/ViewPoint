SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQDSGetNextSeq]
/*************************************
* Created:	Robertt 
* Modified:	TJL 10/16/06 - Issue #26203, 6x Rewrite
*
* Get next sequence from HQDS.
*
* Pass:
*	Nothing
*
* Success returns:
*	0 and NextSeq value
*
* Error returns:
*	1 and error message
**************************************/
(@nextseq int output, @msg varchar(60) output)
as 
set nocount on
declare @rcode int
select @rcode = 0

if exists(select 1 from bHQDS)
	begin	  
	select @nextseq = max(Seq) + 1 
	from bHQDS
	end
else
	begin
	select @nextseq = 0
	end

if @nextseq is null
	begin
	select @msg = 'Error getting next record sequence.', @rcode = 1
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQDSGetNextSeq] TO [public]
GO
