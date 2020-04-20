SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE   procedure [dbo].[vspPMMeetingMinutesGet]
/********************************************************
 * Created By:	GF 06/27/2005    
 * Modified By:    
 *
 * Purpose of Stored Procedure
 * Get Source Project Meeting Minutes for grid display called from PMMeetingMinutesCopy form.
 *    
 *           
 * Notes about Stored Procedure
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 ********************************************************/
(@pmco bCompany = null, @src_project bJob = null, @dest_project bJob = null, @copy_detail bYN = 'Y',
 @copy_attendees bYN = 'Y', @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sql varchar(1000)

select @rcode = 0

select @sql = ' select ''Copy Detail'' = ' + CHAR(39) + @copy_detail + CHAR(39) + ', ''Copy Attendees'' = ' + CHAR(39) + @copy_attendees + CHAR(39)
select @sql = @sql + ', a.MeetingType, a.Meeting, a.MinutesType, a.Subject from PMMM a '
select @sql = @sql + ' where a.PMCo = ' + convert(varchar(3),@pmco) + ' and a.Project = ' + CHAR(39) + @src_project + CHAR(39)
select @sql = @sql + ' and not exists(select top 1 1 from PMMM b where b.PMCo=a.PMCo and b.Project=' + CHAR(39) + @dest_project + CHAR(39)
select @sql = @sql + ' and b.MeetingType=a.MeetingType and b.Meeting=a.Meeting and b.MinutesType=a.MinutesType)'
select @sql = @sql + ' order by a.PMCo, a.Project, a.MeetingType, a.Meeting, a.MinutesType'


exec (@sql)

-- -- -- -- -- -- get meeting minutes data from PMMF
-- -- -- select @copy_detail as [Copy Detail], @copy_attendees as [Copy Attendees],
-- -- -- 		PMMM.MeetingType as [Meeting Type], PMMM.Meeting as [Meeting],
-- -- -- 		PMMM.MinutesType as [Minutes Type], PMMM.Subject as [Subject] 
-- -- -- from PMMM with (nolock)
-- -- -- where PMMM.PMCo=@pmco and PMMM.Project=@src_project
-- -- -- and not exists(select top 1 1 from PMMM a where a.PMCo=PMMM.PMCo and a.Project=@dest_project
-- -- -- 			and a.MeetingType=PMMM.MeetingType and a.Meeting=PMMM.Meeting and a.MinutesType=PMMM.MinutesType)
-- -- -- order by PMMM.PMCo, PMMM.Project, PMMM.MeetingType, PMMM.Meeting, PMMM.MinutesType

-- -- -- bspexit:
-- -- -- 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMMeetingMinutesGet] TO [public]
GO
