SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVARPRUuserlist1    Script Date: 8/28/99 9:35:55 AM ******/
    CREATE  proc [dbo].[vspVARPRUuserlist1]
    /*******************************************************************
    * Object:  Stored Procedure dbo.bspVADDMSuserlist
    ********************************************************************
    * lists security set up in bDDMS for a module, ordered by user name
    * input:  report, msg
    * ouput:  username, RepGrant(None,Full)
    * 06/16/99 LM - changed for SQL 7.0 to use name instead of id.
    * Modified 01/12/00 LM - added report security by company feature
    *********************************************************************/
    (@rept varchar(40)=null,  @co bCompany, @msg varchar(60) output) as
   
    set nocount on
    begin
    declare @Title char(40)
    declare @rcode integer
    select @rcode = 0
   
    select @Title=Title from bRPRT where Title=@rept
   
    if @Title is null
    	begin
    	select @msg = 'Report is not set up in RPRT!', @rcode = 1
    	goto bspexit
    	end
   
   
    select u.VPUserName, RepGrant=
    case r.VPUserName
      when u.VPUserName then 'Full'
      else 'None'
    end
      from DDUP u LEFT JOIN bRPRU r 
      ON u.VPUserName=r.VPUserName and  r.Co = @co and r.Title=@rept   
      order by u.VPUserName
   
    bspexit:
    	return @rcode
    end
GO
GRANT EXECUTE ON  [dbo].[vspVARPRUuserlist1] TO [public]
GO
