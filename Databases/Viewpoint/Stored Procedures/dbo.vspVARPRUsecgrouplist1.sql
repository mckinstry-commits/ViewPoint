SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVARPRUuserlist1    Script Date: 8/28/99 9:35:55 AM ******/
    CREATE  proc [dbo].[vspVARPRUsecgrouplist1]
    /*******************************************************************
    * Object:  Stored Procedure dbo.bspVADDMSsecgrouplist
    ********************************************************************
    * lists security set up in bDDMS for a module, ordered by Securitygroup
    * input:  report, msg
    * ouput:  username, RepGrant(None,Full)
    * 06/16/99 LM - changed for SQL 7.0 to use name instead of id.
    * Modified 01/12/00 LM - added report security by company feature
    *********************************************************************/
    (@Mod char(2)=null, @rept varchar(40)=null,  @co bCompany, @msg varchar(60) output) as
   
    set nocount on
    begin
    declare @rcode integer
   
    select @rcode = 0
    if (select count(*) from DDMO where  Mod=@Mod)<>1
    	begin
    	select @msg = 'Invalid Module!', @rcode = 1
    	goto bspexit
    	end
   
   
--    case s.SecurityGroup
--      when u.SecurityGroup then 'Full'
--      else 'None'
--    END
	select t.Title, s.Access AS RepGrant
	FROM [RPRTShared] t WITH (NOLOCK)
	JOIN [RPRMShared] m WITH(NOLOCK)
	ON m.[ReportID] = t.[ReportID]
	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID]  
	WHERE m.[Mod] = @Mod AND s.[Co] = @co
	UNION
	SELECT t.[Title], 3 AS RepGrant
	FROM [RPRTShared] t 
	JOIN [RPRMShared] m WITH(NOLOCK)
	ON m.[ReportID] = t.[ReportID]
	WHERE Title NOT IN (SELECT Title FROM [RPRTShared] t WITH (NOLOCK)
	JOIN [RPRMShared] m WITH(NOLOCK)
	ON m.[ReportID] = t.[ReportID]
	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID])  
	
	--t.Title = @rept
    /*from bRPRT t JOIN bRPRU r ON
       t.Title=r.Title
       JOIN bRPRM m ON
       t.Title = m.Title 
       RIGHT JOIN DDUP u ON
       u.name=r.VPUserName
       Where r.Co=@co and t.Title=@rept and m.Mod = @Mod*/
  
    bspexit:
    	return @rcode
    end
GO
GRANT EXECUTE ON  [dbo].[vspVARPRUsecgrouplist1] TO [public]
GO
