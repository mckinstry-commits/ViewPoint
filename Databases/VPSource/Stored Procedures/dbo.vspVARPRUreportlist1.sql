SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVARPRUreportlist1    Script Date: 8/28/99 9:35:54 AM ******/
 CREATE     proc [dbo].[vspVARPRUreportlist1]
 /************************************************************************
 * Object:  Stored Procedure dbo.bspVARPRUreportlist1
 *************************************************************************
 * displays security set up in bRPRU for a given user, ordered by report
 * input:  username, msg
 * output: Title, Grant(None,Full)
 * 06/26/96 LM
 * 06/16/99 LM - changed for SQL 7.0 to use name instead of id.
 * 01/12/00 LM - added report security by company feature
 * 08/17/00 DANF - remove reference of system user id
 * 01/30/04 DANF - Do not include Audit reports.
 * 01/26/05 danf - issue #119669 (SQL 9.0 2005)
 **************************************************************************/
 	(@uname bVPUserName=null, @co bCompany,
 	 @msg varchar(60) output) as
 
 set nocount on
 begin
 declare @validcnt integer
 declare @rcode integer
 begin
 select @rcode = 0
 end
 /* displays security set up in bRPRU
  * for a given user, ordered by report */
 
 
 select @validcnt=count(*) from DDUP with (nolock) where VPUserName=@uname
 if @validcnt = 0
 	begin
 	select @msg = 'User not in DDUP!', @rcode = 1
 	goto bspexit
 	end
 
 
 select t.Title, RepGrant=
   case r.VPUserName
     when @uname then 'Full'
 
     else 'None'
   end
   from vRPRT t with (nolock)
   left join vRPRU r with (nolock)
   on t.ReportID = r.ReportID and r.VPUserName   = 'danf' and r.Co=1
   where  t.ReportType <>'Audit'
   order by t.Title

 
 
 bspexit:
   return @rcode
 end
GO
GRANT EXECUTE ON  [dbo].[vspVARPRUreportlist1] TO [public]
GO
