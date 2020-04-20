SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVARPRUupdate    Script Date: 8/28/99 9:35:54 AM ******/
     CREATE  proc [dbo].[vspVARPRUupdate]
     /**************************************************************
     * Object:  Stored Procedure dbo.bspVARPRUupdate
     **************************************************************
     * grants/revokes (deletes) entries in
     * bRPRU,  for a given user,report
     * pass in action, report, username, msg OUTPUT
     * where action is ('grant', 'revoke')
     * 06/27/96 LM
     * 06/15/99 LM - modified to use username instead of user id for SQL 7.0 change
     * 01/11/00 LM - added report security by company
     * 08/17/00 DANF - remove reference to system user id
     **************************************************************/
   
     (@action varchar(8)=null,
      @report varchar(40),
      @username bVPUserName=null,
      @co bCompany,
      @msg varchar(60) output) as
   
     set nocount on
     begin
       declare @rcode int	/* error return code for any errors */
       select @rcode = 0
   
     begin transaction
        if (select count(*) from DDUP where VPUserName=@username) <> 1
        begin
           select @msg = 'User name not in DDUP!', @rcode=1
           goto bsperror
        end
        if (select count(*) from vRPRT where  Title=@report)<1
     	begin
     	select @msg = 'Report not in RPRT!', @rcode = 1
     	goto bsperror
     	end
        if @action='grant'
        begin
   
   
          /* insert report security */
          if exists (select Title from bRPRU where Title=@report
     					 and VPUserName=@username and Co=@co)
          begin
   	  goto bspexit
          end
          else
          begin
     	insert into bRPRU (Co, VPUserName, Title)
     	select @co,@username,@report
          end
        end
        if @action='revoke'
        begin
   
          /* delete report security */
          delete from bRPRU where Co=@co and Title=@report and VPUserName=@username
        end
   
   bspexit:
     commit transaction
   
   
     return @rcode
   
     bsperror:
      rollback transaction
      return @rcode
   
     end
GO
GRANT EXECUTE ON  [dbo].[vspVARPRUupdate] TO [public]
GO
