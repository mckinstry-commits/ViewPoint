SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVPUserList    Script Date: 8/13/2004 11:15:38 AM ******/
   CREATE   procedure [dbo].[bspVPUserList]
    /********************************************************
    * Created:	GG 10/24/01
    * Modified: GF 02/05/2003 - Issue #18863 - change from hostname/loginame to loginame/hostname
    *			 GF 06/25/2003 - do not check RPRUN, RPRUN2 per Rob H
    *			 GF 10/02/2003 - issue #21783 - flag user as system if in VA, RPRUN, HQ, UD. Added PRCREWTS to acct.
    *			 DANF 04/01/2004 - Issue 23721 - Added RPLaunch.
    *			 DC  8/13/04 - Issue 20981 - Added RQ
    * 			 DANF 09/14/2004 - Issue 19246 added new login
    *			 DANF 08/12/2005 - Issue 29444 do not exlude the user bidtek from the user list.
    *			 DANF 09/26/2005 - Issue 29857
    *							 
    *
    * Purpose:
    *  Called by the VP Menu About box to return a list of current Viewpoint
    *  users and the type of license they are counted under.
    *
    *  A user may be counted as both an Accounting and PM license, but will only 
    *  be counted as System if he is not one of the other two.
    *
    *  Counted as an Accounting license if user has a process running under one or
    *  more of the following program names: AP,AR,CM,EM,IN,GL,HR,JB,JC,MS,PO,PR,RP,SL,IM,RQ
    *
    *  Counted as a Project Mgmt license if user has a process running under the 
    *  follwing program name: PM
    *
    *  Counted as a System (used for System License check) if user is not already counted
    *  as an Accounting or PM license and has a process running under one or more of the 
    *  following program names: HQ,VA,UD,RPRUN
    *
    *  User is not counted if he is only running VPMENU 
    *
    * Returns:
    *  Result set (loginname, Acct, PM, Sys)
    *
    *******************************************************************************/
   ( @system bYN = 'N')
    as
    set nocount on
    
   -- build a temp table to hold user info
   create table #UserCheck (loginame varchar(128) not null, Acct tinyint not null, PM tinyint not null, Sys tinyint not null)
   
   if @system = 'N'
   	begin
    
   		-- add an entry for each login running Viewpoint
   		insert #UserCheck (loginame, Acct, PM, Sys)
   		select distinct rtrim(loginame) + '/' + rtrim(hostname), '', '', ''
   		from master..sysprocesses 
   		where loginame <> 'viewpointcs'
   		and upper(program_name) in ('AP','AR','CM','EM','IN','GL','HR','JB','JC','MS','PO','PR','RP','SL','IM','PM','HQ','VA','UD','PRCREWTS','RPRUN','VPMENU','RQ')
   		
   		-- acct from LicenseCheck('AP', 'AR', 'CM', 'EM', 'IN', 'GL', 'HR', 'JB', 'JC', 'MS', 'PO', 'PR', 'RP', 'SL', 'IM', 'PRCREWTS')
   		-- flag Accounting users
   		update #UserCheck
   		set Acct = case when (select count(*) from master..sysprocesses s
   		where upper(program_name) in ('AP', 'AR', 'CM', 'EM', 'IN', 'GL', 'HR', 'JB', 'JC', 'MS', 'PO', 'PR', 'RP', 'SL', 'IM', 'PRCREWTS','RQ')
   		and (rtrim(s.loginame) + '/' + rtrim(s.hostname)) = u.loginame) > 0 then 1 else 0 end
   		from #UserCheck u
   		 
   		
   		-- flag PM users
   		update #UserCheck
   		set PM = case when (select count(*) from master..sysprocesses s
   		where upper(program_name) = 'PM' and (rtrim(s.loginame) + '/' + rtrim(s.hostname)) = u.loginame) > 0 then 1 else 0 end
   		from #UserCheck u
   		
   		
   		/*
   		-- flag VA users as system
   		update #UserCheck
   		set Sys = case when
   			(select count(*) from master..sysprocesses s where upper(program_name) = 'VA' 
   				and (rtrim(s.loginame) + '/' + rtrim(s.hostname)) = u.loginame) > 0
   			and
   			(select count(*) from master..sysprocesses r where upper(program_name)
   				in ('AP', 'AR', 'CM', 'EM', 'IN', 'GL', 'HR', 'JB', 'JC', 'MS', 'PO', 'PR', 'RP', 'SL', 'IM', 'PRCREWTS','PM')
   				and (rtrim(r.loginame) + '/' + rtrim(r.hostname)) = u.loginame) = 0 then 1 else 0 end
   			from #UserCheck u
   		*/
   		
   		
   		-- flag VA, RPRUN, HQ, UD users as system
   		update #UserCheck
   		set Sys = case when
   			(select count(*) from master..sysprocesses s where upper(program_name) in ('VA', 'RPRUN', 'HQ', 'UD', 'RPLAUNCH')
   				and (rtrim(s.loginame) + '/' + rtrim(s.hostname)) = u.loginame) > 0 then 1 else 0 end
   		from #UserCheck u
   		
   		-- last clean up system users - set count to zero if in acct or PM
   		update #UserCheck set Sys = 0
   		from #UserCheck u where u.Acct <> 0 or u.PM <> 0
   
   	end
   else
   	begin
   		insert #UserCheck (loginame, Acct, PM, Sys)
   		select distinct rtrim(loginame) + '/' + rtrim(hostname), 1, '', ''
   		from master..sysprocesses 
   		where loginame <> 'viewpointcs'
   		and upper(program_name) in ('VPMENU')
   
   		insert #UserCheck (loginame, Acct, PM, Sys)
   		select distinct rtrim(loginame) + '/' + rtrim(hostname), 1, '', ''
   		from master..sysprocesses p  with (nolock) 
   		where loginame <> 'viewpointcs' and
   		upper(program_name) in 
   		('AP', 'AR', 'CM', 'EM', 'IN', 'GL', 'HR', 'JB', 'JC', 'MS', 'PO', 'PR', 'RP', 'SL', 'IM', 'PRCREWTS', 'RQ', 'VA','RPRUN','RPLAUNCH', 'HQ', 'UD', 'VS')
   		and not exists 
   		( select 1 from master..sysprocesses f with (nolock) where   p.hostname=f.hostname and p.loginame=f.loginame and upper(program_name) = 'VPMENU')
   	
   	end
   
    
   select * from #UserCheck order by loginame
    
   drop table #UserCheck
    
   return

GO
GRANT EXECUTE ON  [dbo].[bspVPUserList] TO [public]
GO
