SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          PROCEDURE [dbo].[vspDDAppLogsTableStatistics]
/**************************************************
* Created: JRK 06/01/05
* Modified: 
*
* Returns 2 pieces of data about vDDAL: Nbr of rows and oldest log date.
*
* Inputs:
*	none
*
* Output:
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

	Select Count(0), MIN([DateTime]) from vDDAL


   
vspexit:

	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDAppLogsTableStatistics]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDAppLogsTableStatistics] TO [public]
GO
