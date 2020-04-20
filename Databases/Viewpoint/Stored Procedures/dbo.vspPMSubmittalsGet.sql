SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
CREATE procedure [dbo].[vspPMSubmittalsGet]
/************************************************************************
* Created By:	GF 08/12/2005
* Modified By:	GF 10/27/2009 - issue #134090 - submittal distributions
*
*
* Purpose of Stored Procedure to get submittals for copying
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @submittaltype bDocType, @copy_items bYN = 'Y',
 @copy_revisions bYN = 'N', @copy_distributions bYN = 'Y', @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sql varchar(2000)

select @rcode = 0

if isnull(@submittaltype,'') = '' set @submittaltype = null

select @sql = ' select ''Copy Items'' = ' + CHAR(39) + @copy_items + CHAR(39) +
				', ''Copy Revisions'' = ' + CHAR(39) + @copy_revisions + CHAR(39) +
				', ''Copy Distributions'' = ' + CHAR(39) + @copy_distributions + CHAR(39)
select @sql = @sql + ', a.SubmittalType, a.Submittal, a.Rev, a.Description' + ' from PMSM a'
select @sql = @sql + ' where a.PMCo = ' + convert(varchar(3),@pmco) + ' and a.Project = ' + CHAR(39) + @project + CHAR(39)

if @submittaltype is not null
      begin
      select @sql = @sql + ' and a.SubmittalType = ' + CHAR(39) + @submittaltype + CHAR(39)
      end

select @sql = @sql + ' and a.Rev = 0'


exec (@sql)



GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalsGet] TO [public]
GO
