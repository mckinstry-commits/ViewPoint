SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE    PROCEDURE [dbo].[vspVPMenuGetHQCompanies]


/**************************************************
* Created: JRK 12/13/03
* Modified: George Clingerman 09-08-2007 Issue 129068 - Added "ReportDateFormat" as another return column
*
* Used by VPMenu's Change Company routine to fill a list with company numbers
* and names.
*
* Inputs:
*	<none>
*
* Output:
*	resultset of users' accessible items for the sub folder
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0	--not used at this point.


select HQCo, Name, ReportDateFormat from HQCO -- No longer using HQCOLookup.
order by HQCo   
   
vspexit:
	/*
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuGetHQCompanies]'
	*/
	return @rcode









GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetHQCompanies] TO [public]
GO
