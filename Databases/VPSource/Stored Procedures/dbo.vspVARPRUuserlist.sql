SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVARPRUuserlist    Script Date: 8/28/99 9:35:54 AM ******/
    CREATE  proc [dbo].[vspVARPRUuserlist]
    /*******************************************************************
    * Object:  Stored Procedure dbo.bspVADDMSuserlist
    ********************************************************************
    * lists security set up in bDDMS for a module, ordered by user name
    * input:  module, report, msg
    * ouput:  username, RepGrant(None,Full)
    * Modified 01/12/00 LM - added report security by company feature
	* Modified 06/28/07 AL - Added needed functionality FOR 6x release.
    *********************************************************************/
    (@Mod char(2)=null, @rept varchar(40)=null,  @co bCompany, @msg varchar(60) output) as
   
    set nocount on
    begin
    declare @rcode integer
  
IF @Mod = ''
   BEGIN 
   SELECT @Mod = 'RP'	
   END
 
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
	select u.[VPUserName], g.[Name] 'Group Name', s.Access AS RepGrant
	FROM [RPRTShared] t WITH (NOLOCK)
	JOIN [RPRMShared] m WITH(NOLOCK)
	ON m.[ReportID] = t.[ReportID]
	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID]
	LEFT JOIN [DDUP] u WITH (NOLOCK) ON u.[VPUserName] = s.[VPUserName]
	LEFT JOIN [DDSG] g WITH (NOLOCK) ON g.[SecurityGroup] = s.[SecurityGroup]
	WHERE s.[Co] = @co AND t.[Title] = @rept
	UNION
	SELECT CASE WHEN [SecurityGroup] = -1 then u.[Name] ELSE NULL END AS Name, CASE WHEN [SecurityGroup]<> -1 then u.[Name] ELSE NULL END AS SG, 3 AS RepGrant
	FROM 
	ReportUsers u
	WHERE u.[Name] NOT IN (SELECT s.[VPUserName] FROM [RPRTShared] t WITH (NOLOCK)
	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID]
	LEFT JOIN [DDUP] u WITH (NOLOCK) ON u.[VPUserName] = s.[VPUserName]
	WHERE s.[Co] = @co AND t.[Title] = @rept AND NOT s.[VPUserName] = '' ) 
	AND
	u.[Name] NOT IN (SELECT g.Name FROM [RPRTShared] t WITH (NOLOCK)
	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID]
	LEFT JOIN [DDSG] g WITH (NOLOCK) ON g.[SecurityGroup] = s.[SecurityGroup]
	WHERE s.[Co] = @co AND t.[Title] = @rept AND NOT g.Name IS NULL)

--    select u.VPUserName, RepGrant=
--    case r.VPUserName


--      when u.VPUserName then 'Full'
--      else 'None'
--    end
--    from DDUP u LEFT JOIN vRPRS r 
--      ON u.VPUserName=r.VPUserName and r.Co = @co 
    /*from bRPRT t JOIN bRPRU r ON
       t.Title=r.Title
       JOIN bRPRM m ON
       t.Title = m.Title 
       RIGHT JOIN DDUP u ON
       u.name=r.VPUserName
       Where r.Co=@co and t.Title=@rept and m.Mod = @Mod*/
       order by u.VPUserName
    bspexit:
    	return @rcode
    end
GO
GRANT EXECUTE ON  [dbo].[vspVARPRUuserlist] TO [public]
GO
