SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVARPRUreportlist    Script Date: 8/28/99 9:35:54 AM ******/
   CREATE   proc [dbo].[vspVARPRUreportlist]
   /************************************************************************
   * Object:  Stored Procedure dbo.bspVARPRUreportlist
   *************************************************************************
   * displays security set up in bRPRU for a given module & user, ordered by report
   * input:  module, username, msg
   * output: Title, Grant(None,Full)
   * 06/26/96 LM
   * 06/16/99 LM - changed for SQL 7.0 to use name instead of id.
   * 01/12/00 LM - added report security by company feature
   * 08/17/00 DANF - remove reference to system user id
   * 01/30/04 DANF - Do not include Audit reports.
   **************************************************************************/
   	(@Module char(2)=null, @co smallint,
   	 @msg varchar(60) output) as
   
   set nocount on
   declare @validcnt integer
   declare @rcode integer
   begin
   
   select @rcode = 0
   
   /* displays security set up in bRPRU
    * for a given module & user, ordered by report */
   
--   select @validcnt= count(*) from DDUP where VPUserName=@uname
--   
--   if @validcnt = 0
--   	begin
--   	select @msg = 'User not in DDUP!', @rcode = 1
--   	goto bspexit
--   	end
   
    IF @Module = ''
   BEGIN 
   SELECT @Module = 'RP'	
   END
--    case s.SecurityGroup
--      when u.SecurityGroup then 'Full'
--      else 'None'
--    END
	select t.[ReportID], t.Title, s.[VPUserName], ISNULL(s.Access, 3) AS Access
	FROM [RPRTShared] t WITH (NOLOCK)
	
	JOIN [RPRMShared] m WITH(NOLOCK)
	
	ON m.[ReportID] = t.[ReportID]
	
	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID]  
	
	WHERE m.[Mod] = @Module AND s.[Co] = @co AND s.[VPUserName] <> ''
	
	UNION
	
	SELECT t.[ReportID], t.Title, u.[VPUserName], 3 AS Access 
	
	FROM [RPRTShared] t 

	JOIN [RPRMShared] m WITH(NOLOCK)
	
	ON m.[ReportID] = t.[ReportID]

	CROSS JOIN  [DDUP] u WITH (NOLOCK) 
	
	WHERE u.[VPUserName] NOT IN (select s.[VPUserName]
	
	FROM [RPRTShared] t WITH (NOLOCK)
	
	JOIN [RPRMShared] m WITH(NOLOCK)
	
	ON m.[ReportID] = t.[ReportID]
	
	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID]  
	
	WHERE m.[Mod] = @Module AND s.[Co] = @co AND s.[VPUserName] <> '') AND m.Mod = @Module


--   select t.Title, RepGrant=
--     case u.VPUserName
--       when @uname then 'Full'
--       else 'None'
--     end
--     from vRPRT t JOIN vRPRM m ON
--     t.ReportID = m.ReportID and m.Mod = @Module
--     LEFT JOIN vRPRS u ON
--     t.ReportID = u.ReportID and u.VPUserName = @uname and u.Co=@co
--     where t.ReportType <>'Audit'
--     order by t.Title
--   
   
   bspexit:
     return @rcode
   end
GO
GRANT EXECUTE ON  [dbo].[vspVARPRUreportlist] TO [public]
GO
