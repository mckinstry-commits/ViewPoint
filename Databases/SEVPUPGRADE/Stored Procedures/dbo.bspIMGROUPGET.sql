SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspIMGROUPGET]
/****************************************************************************
* CREATED: DANF 05/22/2000
* MODIFIED:	RBT  11/14/2003, Issue #22921, Only show one PREndDate for each co/group.
* 			DANF 10/26/2004 - Issue 25901 Added with ( nolock ) and local fast forward cursor.
*			DANF 11/07/2006 - Issue 122982 Improve query preformance
*			GG 04/24/08 - #128000 - replaced slow performing query
*
* USAGE:
* 	Fills grid in IM imports for Ending date
*
* INPUT PARAMETERS:
*
* OUTPUT PARAMETERS:

*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
   (@importid varchar(20) = null, @msg varchar(120) output)
 
   as
   set nocount on
 
   declare @rcode as integer, @prgroupid as int, @prcoid as int, @prenddateid as int,
           @prgroup as bGroup, @prco as bCompany, @var as varchar(60), @prenddate as bDate,
           @desc varchar(120), @C int, @covar as varchar(60), @groupvar as varchar(60), @enddatevar as varchar(60)
 
   select @rcode = 0
 
   begin
 
   delete IMPR
   where ImportId = @importid
 
 if @importid is null
   begin
   select @rcode = 1
   goto bspexit
   end
 
   delete IMPR
   where ImportId = @importid
 
   select @prcoid = Identifier
   from DDUD with (nolock)
   where Form = 'PRTimeCards' and ColumnName = 'Co'
 
   select @prgroupid = Identifier
   from DDUD with (nolock)
   where Form = 'PRTimeCards' and ColumnName = 'PRGroup'
 
   select @prenddateid = Identifier
   from DDUD with (nolock)
   where Form = 'PRTimeCards' and ColumnName = 'PREndDate'
 
 
 
 declare WorkEditCursor cursor local fast_forward for
 select distinct(RecordSeq)
 from IMWE
 where ImportId = @importid
 Order by IMWE.RecordSeq
 
 open WorkEditCursor
 -- set open cursor flag
 
 declare @Recseq int
 
 fetch next from WorkEditCursor into @Recseq
 
 
 
   if @@fetch_status = 0
    begin
 
     nxtseq:
 
-- #128000 commented out slow performing query
-- select @covar=Co.Co, @groupvar=PRGroup.PRGroup,@enddatevar=EndDate.EndDate
-- from bIMWE w with (nolock)
-- left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Co' from bIMWE with (nolock) 
-- 		where Identifier=@prcoid and ImportId = @importid and RecordSeq=@Recseq
--            group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
-- 	     as Co on Co.ImportId=w.ImportId and Co.ImportTemplate=w.ImportTemplate and Co.RecordType=w.RecordType and Co.RecordSeq=w.RecordSeq
--  left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'PRGroup' from bIMWE with (nolock) 
-- 		where Identifier=@prgroupid and ImportId = @importid and RecordSeq=@Recseq
--            group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
-- 	     as PRGroup on PRGroup.ImportId=w.ImportId and PRGroup.ImportTemplate=w.ImportTemplate and PRGroup.RecordType=w.RecordType and PRGroup.RecordSeq=w.RecordSeq
--  left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'EndDate' from bIMWE with (nolock) 
-- 		where Identifier=@prenddateid and ImportId = @importid and RecordSeq=@Recseq
--            group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
-- 	     as EndDate on EndDate.ImportId=w.ImportId and EndDate.ImportTemplate=w.ImportTemplate and EndDate.RecordType=w.RecordType and EndDate.RecordSeq=w.RecordSeq
--  where w.ImportId = @importid and w.RecordSeq=@Recseq
-- group by Co.Co, PRGroup.PRGroup,EndDate.EndDate

-- #128000 - replaced with 3 quick hits to pull PRCo#, PRGroup, and PREndDate
select  @covar = UploadVal
from dbo.bIMWE with (nolock) 
where Identifier=@prcoid and ImportId = @importid and RecordSeq=@Recseq

select  @groupvar = UploadVal
from dbo.bIMWE with (nolock) 
where Identifier=@prgroupid and ImportId = @importid and RecordSeq=@Recseq

select  @enddatevar = UploadVal
from bIMWE with (nolock) 
where Identifier=@prenddateid and ImportId = @importid and RecordSeq=@Recseq
--
 
     select @prco = null,@prgroup = null,@prenddate = Null
 
     if @covar is not null and isnumeric(@covar)=1 select @prco = convert(int, @covar)
 
     if @groupvar is not null and isnumeric(@groupvar)=1 select @prgroup = convert(int, @groupvar)
 
     if @enddatevar is not null and isdate(@enddatevar) = 1 select @prenddate = convert(smalldatetime,@enddatevar)
 
     SELECT @C = 0
 
     select @C = COUNT(*)
     from IMPR with (nolock)
     where ImportId = @importid and Co = @prco and PRGroup = @prgroup --(#22921) and PREndDate = @prenddate
 --mh 10/18/02 - IMPR being populated with entries that do not contain a PRGroup.
 --This will need to be corrected in IMWE.
 --    if @C = 0
 	  if @C = 0 and @prgroup is not null
        begin
         insert IMPR (ImportId, Co, PRGroup, PREndDate)
         values (@importid, @prco, @prgroup, @prenddate)
        end
 
     fetch next from WorkEditCursor into @Recseq
     if @@fetch_status = 0 goto nxtseq
    end
 
 
 close WorkEditCursor
 deallocate WorkEditCursor

 delete IMPR
 where Co is null or PRGroup is null or ImportId is null
 
 bspexit:
 
 select @msg = isnull(@desc,'') + char(13) + char(10) + '[bspIMGROUPGET]'
 
 return @rcode
 end

GO
GRANT EXECUTE ON  [dbo].[bspIMGROUPGET] TO [public]
GO
